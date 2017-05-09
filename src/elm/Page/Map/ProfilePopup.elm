module Page.Map.ProfilePopup exposing (view, personView, nonPersonView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy exposing (..)
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


view : Msg -> Bool -> Scale -> Position -> Object -> Maybe Person -> Html Msg
view closeMsg transition scale offsetScreenXY object person =
    let
        centerTopScreenXY =
            ProfilePopupLogic.centerTopScreenXYOfObject scale offsetScreenXY object
    in
        case person of
            Just person ->
                div
                    [ style (Styles.personDetailPopupDefault transition personPopupSize centerTopScreenXY)
                    ]
                    (lazy2 pointerDefault transition personPopupSize.width
                        :: personView (Just closeMsg) (Object.idOf object) person
                    )

            Nothing ->
                nonPersonPopup
                    transition
                    centerTopScreenXY
                    (Object.idOf object)
                    (Object.nameOf object)
                    (Object.urlOf object)


nonPersonPopup : Bool -> Position -> ObjectId -> String -> String -> Html Msg
nonPersonPopup transition centerTopScreenXY objectId name url =
    if name == "" then
        text ""
    else
        let
            ( size, styles ) =
                if String.length name > 10 then
                    ( middlePopupSize, Styles.personDetailPopupDefault transition middlePopupSize centerTopScreenXY )
                else
                    let
                        size =
                            smallPopupSize (String.length name)
                    in
                        ( size, Styles.personDetailPopupSmall transition size centerTopScreenXY )
        in
            div
                [ style styles
                , classList [ ( "popup-blink", transition ) ]
                ]
                (pointerSmall transition size :: nonPersonView objectId name url)


nonPersonView : ObjectId -> String -> String -> List (Html Msg)
nonPersonView objectId name url =
    [ div
        [ style Styles.personDetailPopupNoPerson
        ]
        [ if url /= "" then
            a
                [ target "_blank"
                , href url
                , style [ ( "text-decoration", "underline" ) ]
                ]
                [ text name ]
          else
            text name
        , objectLink [ ( "margin-left", "5px" ) ] objectId
        ]
    ]


middlePopupSize : Size
middlePopupSize =
    Size 300 100


smallPopupSize : Int -> Size
smallPopupSize charLength =
    Size (charLength * 20 + 45) 40


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
        , lazy photo url
        , div
            [ style Styles.personDetailPopupPersonName ]
            [ text person.name
            , objectLink
                [ ( "position", "absolute" )
                , ( "top", "4px" )
                , ( "margin-left", "5px" )
                ]
                objectId
            ]
        , lazy2 viewTel False person.tel1
        , lazy2 viewTel True person.tel2
        , lazy mail person
        , div [ style Styles.personDetailPopupPersonPost ] [ text person.post ]
        ]


objectLink : List ( String, String ) -> String -> Html Msg
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


pointerDefault : Bool -> Int -> Html msg
pointerDefault transition width =
    div [ style (Styles.personDetailPopupPointerDefault transition width) ] []


pointerSmall : Bool -> Size -> Html msg
pointerSmall transition size =
    div
        [ style (Styles.personDetailPopupPointerSmall transition size.width)
        , classList [ ( "popup-blink", transition ) ]
        ]
        []


viewTel : Bool -> Maybe String -> Html msg
viewTel second tel =
    div
        [ style (Styles.personDetailPopupPersonTel second) ]
        [ Icons.personDetailPopupPersonTel
        , div
            [ style Styles.personDetailPopupPersonIconText ]
            [ text (Maybe.withDefault "" tel) ]
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
