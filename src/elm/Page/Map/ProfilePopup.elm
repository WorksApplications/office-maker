module Page.Map.ProfilePopup exposing(view, personView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale exposing (Scale)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (Object)
import Model.ProfilePopupLogic as ProfilePopupLogic
import Util.HtmlUtil as HtmlUtil
import CoreType exposing (..)

import Page.Map.Msg exposing (Msg(..))


personPopupSize : Size
personPopupSize =
  ProfilePopupLogic.personPopupSize


view : Msg -> Scale -> Position -> Object -> Maybe Person -> Html Msg
view closeMsg scale offsetScreenXY object person =
  let
    centerTopScreenXY =
      ProfilePopupLogic.centerTopScreenXYOfObject scale offsetScreenXY object
  in
    case person of
      Just person ->
        div
          [ class "profile-popup"
          , style (Styles.personDetailPopupDefault personPopupSize centerTopScreenXY)
          ]
          ( Lazy.lazy pointerDefault personPopupSize.width ::
            personView (Just closeMsg) (Object.idOf object) person
          )

      Nothing ->
        nonPersonView centerTopScreenXY (Object.idOf object) (Object.nameOf object)


nonPersonView : Position -> ObjectId -> String -> Html Msg
nonPersonView centerTopScreenXY objectId name =
  if name == "" then
    text ""
  else
    let
      (size, styles) =
        if String.length name > 10 then
          (middlePopupSize, Styles.personDetailPopupDefault middlePopupSize centerTopScreenXY)
        else
          (smallPopupSize, Styles.personDetailPopupSmall smallPopupSize centerTopScreenXY)
    in
      div
        [ class "profile-popup"
        , style styles
        ]
        ( pointerSmall size ::
          [ div
              [ style (Styles.personDetailPopupNoPerson) ]
              [ text name, objectLink [ ("margin-left", "5px") ] objectId ]
          ]
        )


middlePopupSize : Size
middlePopupSize =
  Size 300 100


smallPopupSize : Size
smallPopupSize =
  Size 90 40


personView : Maybe Msg -> String -> Person -> List (Html Msg)
personView maybeCloseMsg objectId person =
  let
    url =
      Maybe.withDefault "./images/users/default.png" person.image

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
    , Lazy.lazy photo url
    , div
        [ style Styles.personDetailPopupPersonName ]
        [ text person.name
        , objectLink
            [ ("position", "absolute")
            , ("top", "4px")
            , ("margin-left", "5px")
            ]
            objectId
        ]
    , Lazy.lazy tel person
    , Lazy.lazy mail person
    , div [ style Styles.personDetailPopupPersonPost ] [ text person.post ]
    ]


objectLink : List (String, String) -> String -> Html Msg
objectLink styles objectId =
  a
    [ HtmlUtil.onPreventDefaultClick (ChangeToObjectUrl objectId)
    , href ("?object=" ++ objectId)
    , style styles
    ]
    [ Icons.link ]


photo : String -> Html msg
photo url =
  img [ style Styles.personDetailPopupPersonImage, src url ] []


pointerDefault : Int -> Html msg
pointerDefault width =
  div [ style (Styles.personDetailPopupPointerDefault width) ] []


pointerSmall : Size -> Html msg
pointerSmall size =
  div [ style (Styles.personDetailPopupPointerSmall size.width) ] []


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
