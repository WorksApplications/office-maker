module SearchBox exposing (..) -- where

import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Model.Equipments as Equipments exposing (..)
import Model.API as API

import Util.HtmlUtil exposing (..)
-- import Util.Keys as Keys
import View.Styles as Styles

type Msg =
    NoOp
  | Input String
  | Results (List (Equipment, String))
  | Submit
  | SelectResultMsg
  | Error API.Error


type Event =
  OnError String | OnResults | SelectResult

type alias Model =
  { query : String
  , results : List (Equipment, String)
  }

init : Model
init =
  { query = ""
  , results = []
  }

update : Msg -> Model -> (Model, Cmd Msg, Maybe Event)
update msg model =
  case {-Debug.log "searchbox"-} msg of
    NoOp ->
      (model, Cmd.none, Nothing)
    Input query ->
      let
        newModel = { model | query = query }
      in
        (newModel, Cmd.none, Nothing)
    Submit ->
      let
        cmd =
          if model.query /= "" then
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
    SelectResultMsg ->
        (model, Cmd.none, Just SelectResult)
    Error httpError ->
        (model, Cmd.none, Just (OnError "http error")) --TODO

view : Model -> Html Msg
view model =
  form' Submit
    [ ]
    [ input
      [ type' "input"
      , placeholder "Search"
      , style Styles.searchBox
      , value model.query
      , onInput Input
      ]
      []
    ]

resultsView : (Equipment -> String -> String) -> Model -> Html Msg
resultsView format model =
  let
    each (e, floorId) =
      li [ Html.Events.onClick SelectResultMsg ] [ text (format e floorId) ]
  in
    ul
      []
      (List.map each model.results)
