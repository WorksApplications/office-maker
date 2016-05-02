import Html exposing (Html, text, div, input, form, h2)
import Html.Attributes exposing (type', value, action, method, style)

import StartApp
import Signal exposing (Signal, Address)
import Task
import API
import Effects exposing (Effects)

import Header
import Util.HtmlUtil as HtmlUtil exposing (..)
import View.Styles as Styles

app : StartApp.App Model
app = StartApp.start
  { init = init
  , view = view
  , update = update
  , inputs = []
  }

main : Signal Html
main = app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks

--------

type Action =
    InputId String
  | InputPass String
  | Submit
  | UnAuthorized
  | Success
  | NoOp

type alias Model =
  { error : Maybe String
  , inputId : String
  , inputPass : String
  }

init : (Model, Effects Action)
init =
  ( { error = Nothing, inputId = "", inputPass = "" }
  , Effects.none
  )

update : Action -> Model -> (Model, Effects Action)
update action model =
  case Debug.log "action" action of
    InputId s -> ({model | inputId = s}, Effects.none)
    InputPass s -> ({model | inputPass = s}, Effects.none)
    Submit ->
      let
        task =
          API.login model.inputId model.inputPass
            `Task.andThen` (\_ -> Task.succeed Success)
            `Task.onError` (\e ->
              let
                _ = Debug.log "e" e
              in
                Task.succeed UnAuthorized)
      in
        (model, Effects.task task)
    UnAuthorized ->
      ({model | error = Just "unauthorized."}, Effects.none)
    Success ->
      let
        task =
          API.gotoTop `Task.andThen` (\_ -> Task.succeed NoOp)
      in
        (model, Effects.task task)
    NoOp ->
      (model, Effects.none)

view : Address Action -> Model -> Html
view address model =
  div
    []
    [ Header.view Nothing
    , container address model
    ]

container : Address Action -> Model -> Html
container address model =
  div
    [ style Styles.loginContainer ]
    [ h2 [ style Styles.loginCaption ] [ text "Sign in to Office Makaer" ]
    , div [] [ text (Maybe.withDefault "" model.error) ]
    , loginForm address model
    ]

loginForm : Address Action -> Model -> Html
loginForm address model =
  HtmlUtil.form' address Submit
    []
    [ div
        []
        [ div [] [ text "Username" ]
        , input
            [ style Styles.formInput
            , onInput (Signal.forwardTo address InputId)
            , type' "input"
            , value model.inputId]
            []
        ]
    , div
        []
        [ div [] [ text "Password" ]
        , input
            [ style Styles.formInput
            , onInput (Signal.forwardTo address InputPass)
            , type' "input"
            , value model.inputPass]
            []
        ]
    , input
        [ style <| Styles.primaryButton ++ [("margin-top", "20px"), ("width", "100%")]
        , type' "submit"
        , value "Sign in"
        ]
        []
    ]
