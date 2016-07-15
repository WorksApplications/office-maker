module View.ProfilePopup exposing(view, innerView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)
import Model.Equipments as Equipments exposing (..)

view : msg -> Scale.Model -> (Int, Int) -> Equipment -> Maybe Person -> Html msg
view closeMsg scale (offsetX, offsetY) equipment person =
  let
    (x, y, w, h) =
      rect equipment
    (screenX, screenY) =
      Scale.imageToScreenForPosition scale (offsetX + x + w//2, offsetY + y)
  in
    case person of
      Just person ->
        div
          [ style (Styles.personDetailPopup (screenX, screenY) False) ]
          (pointer False :: innerView (Just closeMsg) person)
      Nothing ->
        if nameOf equipment == "" then
          text ""
        else
          div
            [ style (Styles.personDetailPopup (screenX, screenY) True) ]
            (pointer True :: [ div [ style (Styles.personDetailPopupNoPerson) ] [ text (nameOf equipment) ] ])


innerView : Maybe msg -> Person -> List (Html msg)
innerView maybeCloseMsg person =
  let
    url =
      Maybe.withDefault "images/users/default.png" person.image
    closeButton =
      case maybeCloseMsg of
        Just msg ->
          div
            [ style Styles.personDetailPopupClose
            , onClick msg
            ]
            [ Icons.popupClose ]
        Nothing ->
          text ""
  in
    [ closeButton
    , img [ style Styles.personDetailPopupPersonImage, src url ] []
    -- , div [ style Styles.popupPersonNo ] [ text person.no ]
    , div [ style Styles.personDetailPopupPersonName ] [ text person.name ]
    , tel person
    , mail person
    , div [ style Styles.personDetailPopupPersonOrg ] [ text person.org ]
    ]

pointer : Bool -> Html msg
pointer smallMode =
  div [ style (Styles.personDetailPopupPointer smallMode) ] []

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
        [ case person.mail of
            Just mail ->
              a [ href ("mailto:" ++ mail) ] [ text mail ]
            Nothing ->
              text ""
        ]
    ]
