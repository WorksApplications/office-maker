module View.ProfilePopup exposing(view, innerView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)
import Model.Equipments as Equipments exposing (..)
import Model.ProfilePopupLogic exposing (..)

view : msg -> (Int, Int) -> Scale.Model -> (Int, Int) -> Equipment -> Maybe Person -> Html msg
view closeMsg (popupWidth, popupHeight) scale offsetScreenXY equipment person =
  let
    centerTopScreenXY =
      centerTopScreenXYOfEquipment scale offsetScreenXY equipment
  in
    case person of
      Just person ->
        div
          [ style (Styles.personDetailPopupDefault popupWidth popupHeight centerTopScreenXY) ]
          (pointerDefault popupWidth :: innerView (Just closeMsg) person)
      Nothing ->
        if nameOf equipment == "" then
          text ""
        else
          div
            [ style (Styles.personDetailPopupSmall centerTopScreenXY) ]
            (pointerSmall :: [ div [ style (Styles.personDetailPopupNoPerson) ] [ text (nameOf equipment) ] ])


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


pointerDefault : Int -> Html msg
pointerDefault width =
  div [ style (Styles.personDetailPopupPointerDefault width) ] []


pointerSmall : Html msg
pointerSmall =
  div [ style (Styles.personDetailPopupPointerSmall) ] []


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
