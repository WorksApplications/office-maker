import Html exposing (Html, text, div, input, form, h2)
import Html.App as App
import Html.Attributes exposing (type', value, action, method, style, autofocus)

import Task
import Http

import Model.API as API
import Header
import Util.HtmlUtil as HtmlUtil exposing (..)
import View.Styles as Styles

main : Program Never
main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }

--------

type Action =
    InputId String
  | InputPass String
  | Submit
  | Error Http.Error
  | Success
  | NoOp

type alias Model =
  { error : Maybe String
  , inputId : String
  , inputPass : String
  }

init : (Model, Cmd Action)
init =
  { error = Nothing, inputId = "", inputPass = "" } ! []

update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    InputId s -> { model | inputId = s} ! []
    InputPass s -> { model | inputPass = s} ! []
    Submit ->
      let
        task =
          API.login model.inputId model.inputPass
      in
        model ! [ Task.perform Error (always Success) task ]
    Error e ->
      let
        message =
          case e of
            Http.NetworkError ->
              "network error"
            _ ->
              "unauthorized"
      in
        {model | error = Just message} ! []
    Success ->
        model ! [ Task.perform (always NoOp) (always NoOp) API.gotoTop ]
    NoOp ->
        model ! []

view : Model -> Html Action
view model =
  div
    []
    [ Header.view Nothing |> App.map (always NoOp)
    , container model
    ]

container : Model -> Html Action
container model =
  div
    [ style Styles.loginContainer ]
    [ h2 [ style Styles.loginCaption ] [ text "Sign in to Office Makaer" ]
    , div [ style Styles.loginError ] [ text (Maybe.withDefault "" model.error) ]
    , loginForm model
    ]

loginForm : Model -> Html Action
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
