module View.FloorsInfoView exposing(view)

import Html exposing (..)
-- import Html.Keyed as Keyed
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles

import Model.URL as URL
import Model.Floor
import Model.FloorInfo as FloorInfo exposing (FloorInfo)

type alias Floor = Model.Floor.Model


linkBox : List (String, String) -> List (String, String) -> String -> List (Html msg) -> Html msg
linkBox liStyle aStyle url inner =
  li
    [ style liStyle ]
    [ a [ href url , style aStyle ] inner ]


eachView : Bool -> Maybe String -> FloorInfo -> Maybe (Html msg)
eachView isEditMode currentFloorId floorInfo =
  Maybe.map
    (\floor ->
      eachView'
        (currentFloorId == floor.id)
        (markAsPrivate floorInfo)
        (markAsModified isEditMode floorInfo)
        floor
    )
    (getFloor isEditMode floorInfo)


eachView' : Bool -> Bool -> Bool -> Floor -> Html msg
eachView' selected markAsPrivate markAsModified floor =
  linkBox
    (Styles.floorsInfoViewItem selected markAsPrivate)
    Styles.floorsInfoViewItemLink
    (URL.hashFromFloorId floor.id)
    [ text (floor.name ++ (if markAsModified then "*" else ""))
    ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    (Styles.floorsInfoViewItem False False)
    Styles.floorsInfoViewItemLink
    "#"
    [ div [ onClick msg ] [ text "+"] ]


view : msg -> Bool -> Bool -> Maybe String -> List FloorInfo -> Html msg
view onCreateNewFloor isAdmin isEditMode currentFloorId floorInfoList =
  ul
    [ style Styles.floorsInfoView ]
    ( List.filterMap (eachView isEditMode currentFloorId) (List.sortBy (getOrd isEditMode) floorInfoList) ++
        if isEditMode && isAdmin then
          [ createButton onCreateNewFloor ]
        else
          []
    )

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
