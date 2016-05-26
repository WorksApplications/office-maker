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
    _ = Debug.log "currentFloorId, floor.id" (currentFloorId, List.map .id floors)
    each floor =
      li
        [ style (Styles.floorsInfoViewItem (currentFloorId == floor.id) floor.public)
        ]
        [ a [ href (URL.hashFromFloorId floor.id) ] [ text floor.name ]
        ]
  in
    ul
      [ style (Styles.ul ++ Styles.floorsInfoView) ]
      (List.map each floors)
