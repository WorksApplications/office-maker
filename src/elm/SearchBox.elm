module SearchBox exposing (..) -- where

import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Model.Equipments as Equipments exposing (..)
import Model.API as API

import Util.HtmlUtil exposing (..)
import Util.Keys as Keys
import View.Styles as Styles

type Msg =
    NoOp
  | Input String
  | Results (List Equipment)
  | Error API.Error
  | KeyDown Int

type Event =
  OnError String | OnResults

type alias Model =
  { query : String
  , results : List Equipment
  }

init : Model
init =
  { query = ""
  , results = []
  }

update : Msg -> Model -> (Model, Cmd Msg, Maybe Event)
update msg model =
  case Debug.log "searchbox" msg of
    NoOp ->
      (model, Cmd.none, Nothing)
    Input query ->
      let
        newModel = { model | query = query }
      in
        (newModel, Cmd.none, Nothing)
    KeyDown keyCode ->
      let
        cmd =
          if keyCode == 13 && model.query /= "" then
            Task.perform (always NoOp) Results (API.search model.query)
          else
            Cmd.none
      in
        (model, cmd, Nothing)
    Results results ->
      let
        newModel = { model | results = results }
      in
        (newModel, Cmd.none, Just OnResults)
    Error httpError ->
        (model, Cmd.none, Just (OnError "http error")) --TODO

subscriptions : (Msg -> a) -> Sub a
subscriptions f =
  Sub.map f <| Keys.downs KeyDown

view : Model -> Html Msg
view model =
  input
    [ type' "input"
    , placeholder "Search"
    , style Styles.searchBox
    , value model.query
    , onInput Input
    ]
    []
