module SearchBox exposing (..) -- where

import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Model.Equipments as Equipments exposing (..)
import Model.API as API

import Util.HtmlUtil exposing (..)

import View.Styles as Styles

type Msg =
    Input String
  | Results (List (Equipment, String))
  | Submit Bool
  | SelectResult String
  | Error API.Error


type Event =
  OnError API.Error | OnResults | OnSelectResult String

type alias Model =
  { query : String
  , results : Maybe (List (Equipment, String))
  }

init : Model
init =
  { query = ""
  , results = Nothing
  }

update : Msg -> Model -> (Model, Cmd Msg, Maybe Event)
update msg model =
  case {-Debug.log "searchbox"-} msg of
    Input query ->
      let
        newModel = { model | query = query }
      in
        (newModel, Cmd.none, Nothing)
    Submit withPrivate ->
      let
        cmd =
          if model.query /= "" then
            Task.perform Error Results (API.search withPrivate model.query)
          else
            Cmd.none
      in
        (model, cmd, Nothing)
    Results results ->
      let
        newModel = { model | results = Just results }
      in
        (newModel, Cmd.none, Just OnResults)
    SelectResult id ->
        (model, Cmd.none, Just (OnSelectResult id))
    Error apiError ->
        (model, Cmd.none, Just (OnError apiError))

equipmentsInFloor : String -> Model -> List Equipment
equipmentsInFloor floorId model =
  case model.results of
    Nothing ->
      []
    Just results ->
      List.filterMap (\(e, id) -> if id == Debug.log "floorId" floorId then Just e else Nothing) results


view : Bool -> Model -> Html Msg
view searchWithPrivate model =
  form' (Submit searchWithPrivate)
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
    case model.results of
      Nothing ->
        text ""
      Just [] ->
        div [] [ text "Nothing found." ]
      Just results ->
        ul
          [ style Styles.ul ]
          (List.map each results)
