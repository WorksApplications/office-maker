module View.ProfilePopup exposing(view) -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)
import Model.Equipments as Equipments exposing (..)

view : Scale.Model -> (Int, Int) -> Equipment -> Person -> Html msg
view scale (offsetX, offsetY) equipment person =
  let
    url =
      Maybe.withDefault "images/users/default.png" person.image
    (x, y, w, h) =
      rect equipment
    (screenX, screenY) =
      Scale.imageToScreenForPosition scale (offsetX + x + w//2, offsetY + y)
  in
    div
      [ style (Styles.personDetailPopup (screenX, screenY)) ]
      [ div [ style Styles.personDetailPopupClose ] [ Icons.popupClose ]
      , img [ style Styles.personDetailPopupPersonImage, src url ] []
      -- , div [ style Styles.popupPersonNo ] [ text person.no ]
      , div [ style Styles.personDetailPopupPersonName ] [ text person.name ]
      , tel person
      , mail person
      , div [ style Styles.personDetailPopupPersonOrg ] [ text person.org ]
      , pointer
      ]

pointer : Html msg
pointer =
  div [ style Styles.personDetailPopupPointer ] []

tel : Person -> Html msg
tel person =
  div
    [ style Styles.personDetailPopupPersonTel ]
    [ Icons.personDetailPopupPersonTel
    , div
        [ style Styles.personDetailPopupPersonIconText ]
        [ text (Maybe.withDefault "" person.tel) ]
    ]

mail : Person -> Html msg
mail person =
  div
    [ style Styles.personDetailPopupPersonMail ]
    [ Icons.personDetailPopupPersonMail
    , div
        [ style Styles.personDetailPopupPersonIconText ]
        [ text (Maybe.withDefault "" person.mail) ]
    ]
