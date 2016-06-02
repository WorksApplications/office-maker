module View.EquipmentView exposing(equipmentView') -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)


equipmentView' : Bool -> String -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> List (Html.Attribute msg) -> Scale.Model -> Bool -> Maybe Person -> Bool -> Html msg
equipmentView' showPersonMatch key' rect color name selected alpha eventHandlers scale disableTransition personInfo personMatched =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect
    styles =
      Styles.desk screenRect color selected alpha disableTransition
  in
    div
      ( eventHandlers ++ [ {- key key', -} style styles ] )
      [ equipmentLabelView scale disableTransition name
      , if showPersonMatch then
          personMatchingView name personMatched
        else
          text ""
      ]

personMatchingView : String -> Bool -> Html msg
personMatchingView name personMatched =
  if name /= "" && personMatched then
    div [ style Styles.personMatched ] [ Icons.personMatched ]
  else if name /= "" && not personMatched then
    div [ style Styles.personNotMatched ] [ Icons.personNotMatched ]
  else
    text ""


equipmentLabelView : Scale.Model -> Bool -> String -> Html msg
equipmentLabelView scale disableTransition name =
  let
    styles =
      Styles.nameLabel
        (Scale.imageToScreenRatio scale)
        disableTransition  --TODO
  in
    pre
      [ style styles ]
      [ text name ]
