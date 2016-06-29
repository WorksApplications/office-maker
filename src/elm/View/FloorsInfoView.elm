module View.FloorsInfoView exposing(view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles

import Model.URL as URL
import Model.Floor

type alias Floor = Model.Floor.Model


linkBox : List (String, String) -> List (String, String) -> String -> List (Html msg) -> Html msg
linkBox liStyle aStyle url inner =
  li
    [ style liStyle ]
    [ a [ href url , style aStyle ] inner ]


eachView : Maybe String -> Floor -> Html msg
eachView currentFloorId floor =
  linkBox
    (Styles.floorsInfoViewItem (currentFloorId == floor.id) (isPrivate floor))
    Styles.floorsInfoViewItemLink
    (URL.hashFromFloorId floor.id)
    [ text <|
      (floor.name ++ (if modifiedSinceLastPublished floor then "*" else ""))
    ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    (Styles.floorsInfoViewItem False False)
    Styles.floorsInfoViewItemLink
    "#"
    [ div [ onClick msg ] [ text "+"] -- TODO ICON
    ]


view : Maybe msg -> Maybe String -> List Floor -> Html msg
view onCreateNewFloor currentFloorId floors =
  ul
    [ style (Styles.ul ++ Styles.floorsInfoView) ]
    ( List.map (eachView currentFloorId) floors ++
        case onCreateNewFloor of
          Just msg -> [ createButton msg ]
          _ -> []
    )

isPrivate : Floor -> Bool
isPrivate floor =
  floor.id == Nothing -- TODO add flag

modifiedSinceLastPublished : Floor -> Bool
modifiedSinceLastPublished floor =
  not floor.public
