module SearchBox exposing (..)

import Task
import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events
import Model.API as API
import Model.SearchResult exposing (SearchResult)

import Util.HtmlUtil exposing (..)

import View.Styles as Styles

type Msg =
    Input String
  | Results (Maybe String) (List SearchResult)
  | Submit
  | SelectResult SearchResult
  | Error API.Error


type Event =
    OnError API.Error
  | OnResults
  | OnSelectResult SearchResult
  | OnSubmit
  | None


type alias Model =
  { query : String
  , results : Maybe (List SearchResult)
  }


-- TODO refactor
init : API.Config -> (Msg -> a) -> Maybe String -> (Model, Cmd a)
init apiConfig transformMsg query =
  case query of
    Just query ->
      ({ query = query
      , results = Nothing
      }, if query /= "" then
          Cmd.map transformMsg (searchCmd apiConfig False Nothing query)--TODO search here? maybe lacking information
        else
          Cmd.none
      )
    Nothing ->
      ({ query = ""
      , results = Nothing
      }, Cmd.none)


doSearch : API.Config -> (Msg -> a) -> Bool -> Maybe String -> String -> Model -> (Model, Cmd a)
doSearch apiConfig transformMsg withPrivate thisFloorId query model =
  ({ model | query = query }
  , if query /= "" then
      Cmd.map transformMsg (searchCmd apiConfig withPrivate thisFloorId query)
    else
      Cmd.none
  )


update : Msg -> Model -> (Model, Cmd Msg, Event)
update msg model =
  case msg of
    Input query ->
        ({ model | query = query }, Cmd.none, None)

    Submit ->
        (model, Cmd.none, OnSubmit)

    Results thisFloorId results ->
        ({ model | results = Just (reorderResults thisFloorId results) }, Cmd.none, OnResults)

    SelectResult result ->
        (model, Cmd.none, (OnSelectResult result))

    Error apiError ->
        (model, Cmd.none, (OnError apiError))


searchCmd : API.Config -> Bool -> Maybe String -> String -> Cmd Msg
searchCmd apiConfig withPrivate thisFloorId query =
  Task.perform Error (Results thisFloorId) (API.search apiConfig withPrivate query)


allResults : Model -> List SearchResult
allResults model =
  case model.results of
    Nothing ->
      []
    Just results ->
      results


reorderResults : Maybe String -> List SearchResult -> List SearchResult
reorderResults thisFloorId results =
  let
    (inThisFloor, inOtherFloor, missing) =
      List.foldl (\({ personId, objectIdAndFloorId } as result) (this, other, miss) ->
        case objectIdAndFloorId of
          Just (eid, fid) ->
            if Just fid == thisFloorId then
              (result :: this, other, miss)
            else
              (this, result :: other, miss)
          Nothing ->
            (this, other, result :: miss)
      ) ([], [], []) results
  in
    inThisFloor ++ inOtherFloor ++ missing


view : (Msg -> msg) -> Model -> Html msg
view transformMsg model =
  App.map transformMsg <|
    form' Submit
      [ ]
      [ input
        [ type' "input"
        , placeholder "Search"
        , style Styles.searchBox
        , defaultValue model.query
        , onInput Input
        ]
        []
      ]


resultView : (Msg -> msg) -> (SearchResult -> Html msg) -> SearchResult -> Html msg
resultView transformMsg format result =
    li
      [ Html.Events.onClick (transformMsg <| SelectResult result)
      , style Styles.searchResultItem
      ]
      [ format result ]


resultsView : (Msg -> msg) -> Bool -> (SearchResult -> Html msg) -> Model -> Html msg
resultsView transformMsg isEditing format model =
    case model.results of
      Nothing ->
        text ""
      Just [] ->
        div [] [ text "Nothing found." ]
      Just results ->
        let
          each result =
            resultView transformMsg format result

          children =
            List.map each results
        in
          ul [] children


--
