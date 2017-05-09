port module Page.Login.Main exposing (..)

import Html exposing (Html, text, div, input, form, h2)
import Html.Attributes exposing (type_, value, action, method, style, autofocus)
import Task
import Http
import Navigation
import API.API as API
import API.Page as Page
import View.HeaderView as HeaderView
import Util.HtmlUtil as HtmlUtil exposing (..)
import Model.I18n as I18n exposing (Language(..))
import Page.Login.Styles as Styles


port saveToken : String -> Cmd msg


port tokenSaved : ({} -> msg) -> Sub msg


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> tokenSaved (always TokenSaved)
        }



--------


type alias Model =
    { accountServiceRoot : String
    , title : String
    , error : Maybe String
    , inputId : String
    , inputPass : String
    , lang : Language
    }



----


type alias Flags =
    { accountServiceRoot : String
    , title : String
    , lang : String
    }


type Msg
    = InputId String
    | InputPass String
    | Submit
    | Error Http.Error
    | Success String
    | TokenSaved


init : Flags -> ( Model, Cmd Msg )
init { accountServiceRoot, title, lang } =
    { accountServiceRoot = accountServiceRoot
    , title = title
    , error = Nothing
    , inputId = ""
    , inputPass = ""
    , lang =
        if lang == "ja" then
            JA
        else
            EN
    }
        ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        InputId s ->
            { model | inputId = s } ! []

        InputPass s ->
            { model | inputPass = s } ! []

        Submit ->
            let
                cmd =
                    API.login
                        model.accountServiceRoot
                        model.inputId
                        model.inputPass
                        |> Task.map Success
                        |> Task.onError (Error >> Task.succeed)
                        |> Task.perform identity
            in
                model ! [ cmd ]

        Error e ->
            let
                _ =
                    Debug.log "Error" e

                message =
                    case e of
                        Http.NetworkError ->
                            -- "network error"
                            "unauthorized"

                        _ ->
                            "unauthorized"
            in
                { model | error = Just message } ! []

        Success token ->
            model ! [ saveToken token ]

        TokenSaved ->
            model ! [ Navigation.load Page.top ]



----


view : Model -> Html Msg
view model =
    div
        []
        [ HeaderView.view False model.title (Just ".") (text "")
        , container model
        ]


container : Model -> Html Msg
container model =
    div
        [ style Styles.loginContainer ]
        [ h2 [ style Styles.loginCaption ] [ text (I18n.signInTo model.lang model.title) ]
        , div [ style Styles.loginError ] [ text (Maybe.withDefault "" model.error) ]
        , loginForm model
        ]


loginForm : Model -> Html Msg
loginForm model =
    HtmlUtil.form_ Submit
        []
        [ div
            []
            [ div [] [ text (I18n.mailAddress model.lang) ]
            , input
                [ style Styles.formInput
                , onInput InputId
                , type_ "text"
                , value model.inputId
                , autofocus True
                ]
                []
            ]
        , div
            []
            [ div [] [ text (I18n.password model.lang) ]
            , input
                [ style Styles.formInput
                , onInput InputPass
                , type_ "password"
                , value model.inputPass
                ]
                []
            ]
        , input
            [ style Styles.loginSubmitButton
            , type_ "submit"
            , value (I18n.signIn model.lang)
            ]
            []
        ]
