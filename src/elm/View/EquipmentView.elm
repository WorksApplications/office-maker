module View.EquipmentView exposing(equipmentView') -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles

import Model.Scale as Scale

equipmentView' : String -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> List (Html.Attribute msg) -> Scale.Model -> Bool -> Bool -> Html msg
equipmentView' key' rect color name selected alpha eventHandlers scale disableTransition isSelectedResult =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect
    styles =
      Styles.desk screenRect color selected alpha ++
        [("display", "table")] ++
        Styles.transition disableTransition
  in
    div
      ( eventHandlers ++ [ {- key key', -} style styles ] )
      [ equipmentLabelView scale disableTransition name
      , text (if isSelectedResult then "selected" else "")
      ]

equipmentLabelView : Scale.Model -> Bool -> String -> Html msg
equipmentLabelView scale disableTransition name =
  let
    styles =
      Styles.nameLabel (Scale.imageToScreenRatio scale) ++  --TODO
        Styles.transition disableTransition
  in
    pre
      [ style styles ]
      [ text name ]
