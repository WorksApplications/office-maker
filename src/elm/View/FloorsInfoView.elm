module View.FloorsInfoView exposing(view)

import Dict exposing (Dict)
import InlineHover exposing (hover)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import View.Styles as Styles

import Model.User as User exposing (User)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))


type alias FloorId = String


view : (FloorId -> Attribute msg) -> ((FloorId, Bool) -> msg) -> msg -> Bool -> User -> Bool -> Maybe String -> Dict FloorId FloorInfo -> Html msg
view toContextMenuAttribute goToFloorMsg onCreateNewFloor disableContextmenu user isEditMode currentFloorId floorsInfo =
  if isEditMode then
    viewEditingFloors toContextMenuAttribute goToFloorMsg onCreateNewFloor disableContextmenu user currentFloorId floorsInfo
  else
    viewPublicFloors goToFloorMsg currentFloorId floorsInfo


viewEditingFloors : (FloorId -> Attribute msg) -> ((FloorId, Bool) -> msg) -> msg -> Bool -> User -> Maybe FloorId -> Dict FloorId FloorInfo -> Html msg
viewEditingFloors toContextMenuAttribute goToFloorMsg onCreateNewFloor disableContextmenu user currentFloorId floorsInfo =
  let
    contextMenuMsg floor =
      if not disableContextmenu && not (User.isGuest user) then
        Just (toContextMenuAttribute floor.id)
      else
        Nothing

    floorList =
      floorsInfo
        |> FloorInfo.toEditingList
        |> List.map
          (\floor ->
            eachView
              (contextMenuMsg floor)
              (goToFloorMsg (floor.id, True))
              (currentFloorId == Just floor.id)
              False -- TODO
              floor.name
          )

    create =
      if User.isAdmin user then
        [ Lazy.lazy createButton onCreateNewFloor ]
      else
        []
  in
    wrapList ( floorList ++ create )


viewPublicFloors : ((FloorId, Bool) -> msg) -> Maybe FloorId -> Dict FloorId FloorInfo -> Html msg
viewPublicFloors goToFloorMsg currentFloorId floorsInfo =
  let
    floorList =
      floorsInfo
        |> FloorInfo.toPublicList
        |> List.map
          (\floor ->
            eachView
              Nothing
              (goToFloorMsg (floor.id, False))
              (currentFloorId == Just floor.id)
              False -- TODO
              floor.name
          )
  in
    wrapList floorList


wrapList : List (Html msg) -> Html msg
wrapList children =
  ul [ style Styles.floorsInfoView ] children


eachView : Maybe (Attribute msg) -> msg -> Bool -> Bool -> String -> Html msg
eachView maybeOpenContextMenu onClickMsg selected markAsPrivate floorName =
  linkBox
    onClickMsg
    (Styles.floorsInfoViewItem selected markAsPrivate)
    (Styles.floorsInfoViewItemHover markAsPrivate)
    Styles.floorsInfoViewItemLink
    maybeOpenContextMenu
    [ text floorName ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    msg
    (Styles.floorsInfoViewItem False False)
    (Styles.floorsInfoViewItemHover False)
    Styles.floorsInfoViewItemLink
    Nothing
    [ text "+" ]


linkBox : msg -> List (String, String) -> List (String, String) -> List (String, String) -> Maybe (Attribute msg) -> List (Html msg) -> Html msg
linkBox clickMsg liStyle hoverStyle innerStyle maybeOpenContextMenu inner =
  -- hover hoverStyle
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
