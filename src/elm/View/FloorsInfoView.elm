module View.FloorsInfoView exposing(view)

import Html exposing (..)
-- import Html.Keyed as Keyed
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles

import Model.URL as URL
import Model.Floor
import Model.FloorInfo as FloorInfo exposing (FloorInfo)

import Util.HtmlUtil exposing (..)

import Json.Decode as Decode


type alias Floor = Model.Floor.Model


linkBox : Maybe msg -> List (String, String) -> List (String, String) -> String -> List (Html msg) -> Html msg
linkBox contextmenuMsg liStyle aStyle url inner =
  li
    ( style liStyle ::
      ( case contextmenuMsg of
          Just msg ->
            [ onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } (Decode.succeed msg) ]

          Nothing ->
            []
      )
    )
    [ a [ href url, style aStyle ] inner ]


eachView : (Maybe String -> msg) -> Bool -> Bool -> Bool -> Maybe String -> FloorInfo -> Maybe (Html msg)
eachView contextmenuMsg disableContextmenu isAdmin isEditMode currentFloorId floorInfo =
  Maybe.map
    (\floor ->
      eachView'
        (if not disableContextmenu && isAdmin && isEditMode then Just (contextmenuMsg floor.id) else Nothing)
        (currentFloorId == floor.id)
        (markAsPrivate floorInfo)
        (markAsModified isEditMode floorInfo)
        floor
    )
    (getFloor isEditMode floorInfo)


eachView' : Maybe msg -> Bool -> Bool -> Bool -> Floor -> Html msg
eachView' contextmenuMsg selected markAsPrivate markAsModified floor =
  linkBox
    contextmenuMsg
    (Styles.floorsInfoViewItem selected markAsPrivate)
    Styles.floorsInfoViewItemLink
    (URL.hashFromFloorId floor.id)
    [ text (floor.name ++ (if markAsModified then "*" else ""))
    ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    Nothing
    (Styles.floorsInfoViewItem False False)
    Styles.floorsInfoViewItemLink
    "#"
    [ div [ onClick msg ] [ text "+"] ]


view : (Maybe String -> msg) -> ((Int, Int) -> msg) -> msg -> msg -> Bool -> Bool -> Bool -> Maybe String -> List FloorInfo -> Html msg
view onContextMenu onMove onClickMsg onCreateNewFloor disableContextmenu isAdmin isEditMode currentFloorId floorInfoList =
  let
    floorList =
      List.filterMap
        (eachView onContextMenu disableContextmenu isAdmin isEditMode currentFloorId)
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
      , onClick onClickMsg
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
