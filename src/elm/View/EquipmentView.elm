module View.EquipmentView exposing(equipmentView') -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)


equipmentView' : String -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> List (Html.Attribute msg) -> Scale.Model -> Bool -> Maybe Person -> Bool -> Html msg
equipmentView' key' rect color name selected alpha eventHandlers scale disableTransition personInfo personMatched =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect
    styles =
      Styles.desk screenRect color selected alpha ++
        [("display", "table")] ++
        Styles.transition disableTransition
    popup' =
      case personInfo of
        Just person ->
          popup person
        Nothing ->
          text ""
  in
    div
      ( eventHandlers ++ [ {- key key', -} style styles ] )
      [ equipmentLabelView scale disableTransition name
      , personMatchingView name personMatched
      , popup'
      ]

popup : Person -> Html msg
popup person =
  let
    url =
      Maybe.withDefault "images/default.png" person.image
  in
    div
      [ style (Styles.popup (50, 50)) ] -- TODO
      [ div [ style Styles.popupClose ] [ Icons.popupClose ]
      , img [ style Styles.popupPersonImage, src url ] []
      -- , div [ style Styles.popupPersonNo ] [ text person.no ]
      , div [ style Styles.popupPersonName ] [ text person.name ]
      , div [ style Styles.popupPersonOrg ] [ text person.org ]
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
      Styles.nameLabel (Scale.imageToScreenRatio scale) ++  --TODO
        Styles.transition disableTransition
  in
    pre
      [ style styles ]
      [ text name ]
