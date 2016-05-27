module View.FloorsInfoView exposing(view) -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles

import Model.URL as URL
import Model.Floor

type alias Floor = Model.Floor.Model

view : Maybe String -> List Floor -> Html msg
view currentFloorId floors =
  let
    each floor =
      li
        [ style (Styles.floorsInfoViewItem (currentFloorId == floor.id) (isPrivate floor))
        ]
        [ a
            [ href (URL.hashFromFloorId floor.id)
            , style Styles.floorsInfoViewItemLink
            ]
            [ text floor.name
            , if modifiedSinceLastPublished floor then
                text "*"
              else
                text ""
            ]
        ]
  in
    ul
      [ style (Styles.ul ++ Styles.floorsInfoView) ]
      (List.map each floors)

isPrivate : Floor -> Bool
isPrivate floor =
  floor.id == Nothing -- TODO add flag

modifiedSinceLastPublished : Floor -> Bool
modifiedSinceLastPublished floor =
  not floor.public
