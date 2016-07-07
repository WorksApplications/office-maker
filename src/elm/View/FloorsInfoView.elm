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
  case getFloor isEditMode floorInfo of
    Just floor ->
      Just <|
      linkBox
        (Styles.floorsInfoViewItem (currentFloorId == floor.id) (markAsPrivate isEditMode floorInfo))
        Styles.floorsInfoViewItemLink
        (URL.hashFromFloorId floor.id)
        [ text <|
          (floor.name ++ (if modifiedSinceLastPublished floor then "*" else ""))
        ]
    Nothing ->
      Nothing


createButton : msg -> Html msg
createButton msg =
  linkBox
    (Styles.floorsInfoViewItem False False)
    Styles.floorsInfoViewItemLink
    "#"
    [ div [ onClick msg ] [ text "+"] -- TODO ICON
    ]


view : msg -> Bool -> Bool -> Maybe String -> List FloorInfo -> Html msg
view onCreateNewFloor isAdmin isEditMode currentFloorId floorInfoList =
  ul
    [ style (Styles.ul ++ Styles.floorsInfoView) ]
    ( List.filterMap (eachView isEditMode currentFloorId) floorInfoList ++
        if isEditMode && isAdmin then
          [ createButton onCreateNewFloor ]
        else
          []
    )


getFloor : Bool -> FloorInfo -> Maybe Floor
getFloor isEditMode info =
  case info of
    FloorInfo.Public floor ->
      Just floor
    FloorInfo.PublicWithEdit lastPublicFloor currentPrivateFloor ->
      if isEditMode then Just currentPrivateFloor else Just lastPublicFloor
    FloorInfo.Private floor ->
      if isEditMode then Just floor else Nothing


markAsPrivate : Bool -> FloorInfo -> Bool
markAsPrivate isEditing floorInfo =
  case floorInfo of
    FloorInfo.Public _ -> False
    FloorInfo.PublicWithEdit _ _ -> isEditing
    FloorInfo.Private _ -> True



modifiedSinceLastPublished : Floor -> Bool
modifiedSinceLastPublished floor =
  not floor.public
