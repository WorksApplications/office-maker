module View.FloorsInfoView exposing(view) -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles

import Model.Floor

type alias Floor = Model.Floor.Model

view : String -> List Floor -> Html msg
view currentFloorId floors =
  let
    each floor =
      li
        [ style (Styles.floorsInfoViewItem (currentFloorId == floor.id))
        ]
        [ a [ href ("#" ++ floor.id) ] [ text floor.name ]
        ]
  in
    ul
      [ style (Styles.ul ++ Styles.floorsInfoView) ]
      (List.map each floors)
