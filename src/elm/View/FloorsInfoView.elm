module View.FloorsInfoView exposing(view)

import Dict exposing (Dict)
import Json.Decode as Decode

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles

import Model.User as User exposing (User)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))

import InlineHover exposing (hover)


type alias FloorId = String


view : (String -> msg) -> ((FloorId, Bool) -> msg) -> msg -> Bool -> User -> Bool -> Maybe String -> Dict FloorId FloorInfo -> Html msg
view onContextMenu goToFloorMsg onCreateNewFloor disableContextmenu user isEditMode currentFloorId floorsInfo =
  if isEditMode then
    viewEditingFloors onContextMenu goToFloorMsg onCreateNewFloor disableContextmenu user currentFloorId floorsInfo
  else
    viewPublicFloors goToFloorMsg currentFloorId floorsInfo


viewEditingFloors :  (FloorId -> msg) -> ((FloorId, Bool) -> msg) -> msg -> Bool -> User -> Maybe FloorId -> Dict FloorId FloorInfo -> Html msg
viewEditingFloors onContextMenu goToFloorMsg onCreateNewFloor disableContextmenu user currentFloorId floorsInfo =
  let
    contextMenuMsg floor =
      if not disableContextmenu && not (User.isGuest user) then
        Just (onContextMenu floor.id)
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
              (not floor.public)
              floor.name
          )

    create =
      if User.isAdmin user then
        [ createButton onCreateNewFloor ]
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
              False
              floor.name
          )
  in
    wrapList floorList


wrapList : List (Html msg) -> Html msg
wrapList children =
  ul [ style Styles.floorsInfoView ] children


eachView : Maybe msg -> msg -> Bool -> Bool -> String -> Html msg
eachView contextmenuMsg onClickMsg selected markAsPrivate floorName =
  linkBox
    contextmenuMsg
    onClickMsg
    (Styles.floorsInfoViewItem selected markAsPrivate)
    (Styles.floorsInfoViewItemHover markAsPrivate)
    Styles.floorsInfoViewItemLink
    [ text floorName ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    Nothing
    msg
    (Styles.floorsInfoViewItem False False)
    (Styles.floorsInfoViewItemHover False)
    Styles.floorsInfoViewItemLink
    [ text "+" ]


linkBox : Maybe msg -> msg -> List (String, String) -> List (String, String) -> List (String, String) -> List (Html msg) -> Html msg
linkBox contextmenuMsg clickMsg liStyle hoverStyle innerStyle inner =
  hover hoverStyle
  li
    ( style liStyle ::
      onClick clickMsg ::
      ( case contextmenuMsg of
          Just msg ->
            [ onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } (Decode.succeed msg) ]

          Nothing ->
            []
      )
    )
    [ span [ style innerStyle ] inner ]
