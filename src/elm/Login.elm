port module Login exposing (..)

import Html exposing (Html, text, div, input, form, h2)
import Html.App as App
import Html.Attributes exposing (type', value, action, method, style, autofocus)

import Task
import Http

import API.API as API
import Header
import Util.HtmlUtil as HtmlUtil exposing (..)
import View.Styles as Styles

port saveToken : String -> Cmd msg

port tokenSaved : ({} -> msg) -> Sub msg

type alias Flags =
  { accountServiceRoot : String
  , title : String
  }


main : Program Flags
main =
  App.programWithFlags
    { init = \flags -> init flags.accountServiceRoot flags.title
    , view = view
    , update = update
    , subscriptions = \_ -> tokenSaved (always TokenSaved)
    }

--------

type Msg =
    InputId String
  | InputPass String
  | Submit
  | Error Http.Error
  | Success String
  | TokenSaved
  | NoOp


type alias Model =
  { accountServiceRoot : String
  , title : String
  , error : Maybe String
  , inputId : String
  , inputPass : String
  }


init : String -> String -> (Model, Cmd Msg)
init accountServiceRoot title =
  { accountServiceRoot = accountServiceRoot
  , title = title
  , error = Nothing
  , inputId = ""
  , inputPass = ""
  } ! []


update : Msg -> Model -> (Model, Cmd Msg)
update message model =
  case message of
    InputId s ->
      { model | inputId = s} ! []

    InputPass s ->
      { model | inputPass = s} ! []

    Submit ->
      let
        task =
          API.login
            model.accountServiceRoot
            model.inputId
            model.inputPass
      in
        model ! [ Task.perform Error Success task ]

    Error e ->
      let
        _ = Debug.log "Error" e
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
      model ! [ Task.perform (always NoOp) (always NoOp) API.gotoTop ]

    NoOp ->
      model ! []


view : Model -> Html Msg
view model =
  div
    []
    [ Header.view model.title Nothing |> App.map (always NoOp)
    , container model
    ]


container : Model -> Html Msg
container model =
  div
    [ style Styles.loginContainer ]
    [ h2 [ style Styles.loginCaption ] [ text ("Sign in to " ++ model.title) ]
    , div [ style Styles.loginError ] [ text (Maybe.withDefault "" model.error) ]
    , loginForm model
    ]


loginForm : Model -> Html Msg
loginForm model =
  HtmlUtil.form' Submit
    []
    [ div
        []
        [ div [] [ text "Username" ]
        , input
            [ style Styles.formInput
            , onInput InputId
            , type' "text"
            , value model.inputId
            , autofocus True
            ]
            []
        ]
    , div
        []
        [ div [] [ text "Password" ]
        , input
            [ style Styles.formInput
            , onInput InputPass
            , type' "password"
            , value model.inputPass
            ]
            []
        ]
    , input
        [ style <| Styles.primaryButton ++ [("margin-top", "20px"), ("width", "100%")]
        , type' "submit"
        , value "Sign in"
        ]
        []
    ]
