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
  | SelectResult String
  | Error API.Error


type Event =
  OnError String | OnResults | OnSelectResult String

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
    SelectResult id ->
        (model, Cmd.none, Just (OnSelectResult id))
    Error httpError ->
        (model, Cmd.none, Just (OnError "http error")) --TODO

equipmentsInFloor : String -> Model -> List Equipment
equipmentsInFloor floorId model =
  List.filterMap (\(e, id) -> if id == floorId then Just e else Nothing) model.results


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
      li
        [ Html.Events.onClick (SelectResult (idOf e))
        , style Styles.searchResultItem
        ]
        [ text (format e floorId) ]
  in
    ul
      [ style Styles.ul ]
      (List.map each model.results)
