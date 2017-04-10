module Page.Map.FloorsInfoView exposing (view)

import Dict exposing (Dict)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import ContextMenu
import CoreType exposing (..)
import View.Styles as Styles
import Model.User as User exposing (User)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))
import Page.Map.Msg exposing (Msg(..))
import Page.Map.ContextMenuContext as ContextMenuContext


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
              (GoToFloor floor.id True)
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
          (GoToFloor floor.id False)
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
  li
    ( style (Styles.floorsInfoViewItem selected markAsPrivate)
    :: onClick onClickMsg
    :: (maybeOpenContextMenu |> Maybe.map (List.singleton) |> Maybe.withDefault [])
    )
    [ span [ style Styles.floorsInfoViewItemLink ] [ text floorName ] ]


createButton : Html Msg
createButton =
  li
    [ style (Styles.floorsInfoViewItem False False)
    , onClick CreateNewFloor
    ]
    [ span [ style Styles.floorsInfoViewItemLink ] [ text "+" ] ]
