module Page.Map.FloorsInfoView exposing (view)

import Dict exposing (Dict)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ContextMenu
import View.Styles as Styles

import Model.User as User exposing (User)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))

import Page.Map.Msg exposing (Msg(..))
import Page.Map.ContextMenuContext as ContextMenuContext

type alias FloorId = String


view : Bool -> User -> Bool -> Maybe String -> Dict FloorId FloorInfo -> Html Msg
view disableContextmenu user isEditMode currentFloorId floorsInfo =
  if isEditMode then
    viewEditingFloors disableContextmenu user currentFloorId floorsInfo
  else
    viewPublicFloors currentFloorId floorsInfo


viewEditingFloors : Bool -> User -> Maybe FloorId -> Dict FloorId FloorInfo -> Html Msg
viewEditingFloors disableContextmenu user currentFloorId floorsInfo =
  let
    contextMenuMsg floor =
      if not disableContextmenu && not (User.isGuest user) then
        Just (ContextMenu.open ContextMenuMsg (ContextMenuContext.FloorInfoContextMenu floor.id))
      else
        Nothing

    floorList =
      floorsInfo
        |> FloorInfo.toValues
        |> List.map (\floorInfo -> (FloorInfo.isNeverPublished floorInfo, FloorInfo.editingFloor floorInfo))
        |> List.sortBy (Tuple.second >> .ord)
        |> List.map (\(isNeverPublished, floor) ->
            eachView
              (contextMenuMsg floor)
              (GoToFloor <| Just (floor.id, True))
              (currentFloorId == Just floor.id)
              isNeverPublished
              floor.name
          )

    create =
      if User.isAdmin user then
        [ createButton ]
      else
        []
  in
    wrapList ( floorList ++ create )


viewPublicFloors : Maybe FloorId -> Dict FloorId FloorInfo -> Html Msg
viewPublicFloors currentFloorId floorsInfo =
  floorsInfo
    |> FloorInfo.toPublicList
    |> List.map
      (\floor ->
        eachView
          Nothing
          (GoToFloor <| Just (floor.id, False))
          (currentFloorId == Just floor.id)
          False -- TODO
          floor.name
      )
    |> wrapList


wrapList : List (Html msg) -> Html msg
wrapList children =
  ul [ style Styles.floorsInfoView ] children


eachView : Maybe (Attribute msg) -> msg -> Bool -> Bool -> String -> Html msg
eachView maybeOpenContextMenu onClickMsg selected markAsPrivate floorName =
  linkBox
    onClickMsg
    (Styles.floorsInfoViewItem selected markAsPrivate)
    Styles.floorsInfoViewItemLink
    maybeOpenContextMenu
    [ text floorName ]


createButton : Html Msg
createButton =
  linkBox
    CreateNewFloor
    (Styles.floorsInfoViewItem False False)
    Styles.floorsInfoViewItemLink
    Nothing
    [ text "+" ]


linkBox : msg -> List (String, String) -> List (String, String) -> Maybe (Attribute msg) -> List (Html msg) -> Html msg
linkBox clickMsg liStyle innerStyle maybeOpenContextMenu inner =
  li
    ( style liStyle ::
      onClick clickMsg ::
      ( case maybeOpenContextMenu of
          Just attr ->
            [ attr ]

          Nothing ->
            []
      )
    )
    [ span [ style innerStyle ] inner ]
