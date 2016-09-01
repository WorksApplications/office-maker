module View.FloorsInfoView exposing(view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles

import Model.Floor exposing (Floor)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)

import Util.HtmlUtil exposing (..)

import Json.Decode as Decode

import InlineHover exposing (hover)


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


eachView : (String -> msg) -> (String -> msg) -> Bool -> Bool -> Bool -> String -> FloorInfo -> Maybe (Html msg)
eachView contextmenuMsg onClickMsg disableContextmenu isAdmin isEditMode currentFloorId floorInfo =
  Maybe.map
    (\floor ->
      eachView'
        (if not disableContextmenu && isAdmin && isEditMode then Just (contextmenuMsg floor.id) else Nothing)
        (onClickMsg floor.id)
        (currentFloorId == floor.id)
        (markAsPrivate floorInfo)
        (markAsModified isEditMode floorInfo)
        floor
    )
    (getFloor isEditMode floorInfo)


eachView' : Maybe msg -> msg -> Bool -> Bool -> Bool -> Floor -> Html msg
eachView' contextmenuMsg onClickMsg selected markAsPrivate markAsModified floor =
  linkBox
    contextmenuMsg
    onClickMsg
    (Styles.floorsInfoViewItem selected markAsPrivate)
    (Styles.floorsInfoViewItemHover markAsPrivate)
    Styles.floorsInfoViewItemLink
    [ text (floor.name ++ (if markAsModified then "*" else ""))
    ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    Nothing
    msg
    (Styles.floorsInfoViewItem False False)
    (Styles.floorsInfoViewItemHover False)
    Styles.floorsInfoViewItemLink
    [ text "+" ]


view : (String -> msg) -> ((Int, Int) -> msg) -> (String -> Bool -> msg) -> msg -> Bool -> Bool -> Bool -> String -> List FloorInfo -> Html msg
view onContextMenu onMove onClickMsg onCreateNewFloor disableContextmenu isAdmin isEditMode currentFloorId floorInfoList =
  let
    requestPrivate =
      isAdmin && isEditMode

    onClickMsg' id =
      onClickMsg id requestPrivate

    floorList =
      List.filterMap
        (eachView onContextMenu onClickMsg' disableContextmenu isAdmin isEditMode currentFloorId)
        (List.sortBy (getOrd isEditMode) floorInfoList)

    create =
      if isEditMode && isAdmin then
        [ createButton onCreateNewFloor ]
      else
        []
  in
    ul
      [ style Styles.floorsInfoView
      , onMouseMove' onMove
      ]
      ( floorList ++ create )


getOrd : Bool -> FloorInfo -> Int
getOrd isEditMode info =
  case info of
    FloorInfo.Public floor ->
      floor.ord

    FloorInfo.PublicWithEdit lastPublicFloor currentPrivateFloor ->
      if isEditMode then currentPrivateFloor.ord else lastPublicFloor.ord

    FloorInfo.Private floor ->
      if isEditMode then floor.ord else -1


getFloor : Bool -> FloorInfo -> Maybe Floor
getFloor isEditMode info =
  case info of
    FloorInfo.Public floor ->
      Just floor

    FloorInfo.PublicWithEdit lastPublicFloor currentPrivateFloor ->
      if isEditMode then Just currentPrivateFloor else Just lastPublicFloor

    FloorInfo.Private floor ->
      if isEditMode then Just floor else Nothing


markAsPrivate : FloorInfo -> Bool
markAsPrivate floorInfo =
  case floorInfo of
    FloorInfo.Public _ -> False
    FloorInfo.PublicWithEdit _ _ -> False
    FloorInfo.Private _ -> True


markAsModified : Bool -> FloorInfo -> Bool
markAsModified isEditMode floorInfo =
  case floorInfo of
    FloorInfo.Public _ -> False
    FloorInfo.PublicWithEdit _ _ -> if isEditMode then True else False
    FloorInfo.Private _ -> False
