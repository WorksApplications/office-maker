module SearchBox exposing (..)

import Task
import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events
import Model.API as API
-- import Model.Equipments exposing (Equipment)
import Model.SearchResult exposing (SearchResult)

import Util.HtmlUtil exposing (..)

import View.Styles as Styles

type Msg =
    Input String
  | Results (List SearchResult)
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
init : (Msg -> a) -> Maybe String -> (Model, Cmd a)
init transformMsg query =
  case query of
    Just query ->
      ({ query = query
      , results = Nothing
      }, if query /= "" then
          Cmd.map transformMsg (searchCmd False query)
        else
          Cmd.none
      )
    Nothing ->
      ({ query = ""
      , results = Nothing
      }, Cmd.none)

doSearch : (Msg -> a) -> Bool -> String -> Model -> (Model, Cmd a)
doSearch transformMsg withPrivate query model =
  ({ model | query = query }
  , if query /= "" then
      Cmd.map transformMsg (searchCmd withPrivate query)
    else
      Cmd.none
  )

update : Msg -> Model -> (Model, Cmd Msg, Event)
update msg model =
  case {-Debug.log "searchbox"-} msg of
    Input query ->
        ({ model | query = query }, Cmd.none, None)
    Submit ->
        (model, Cmd.none, OnSubmit)
    Results results ->
        ({ model | results = Just results }, Cmd.none, OnResults)
    SelectResult result ->
        (model, Cmd.none, (OnSelectResult result))
    Error apiError ->
        (model, Cmd.none, (OnError apiError))

searchCmd : Bool -> String -> Cmd Msg
searchCmd withPrivate query =
  Task.perform Error Results (API.search withPrivate query)


resultsInFloor : Maybe String -> Model -> List SearchResult
resultsInFloor maybeId model =
  let
    results =
      allResults model
    targetId =
      Maybe.withDefault "draft" maybeId -- TODO ?
    f { personId, equipmentIdAndFloorId } =
      case equipmentIdAndFloorId of
        Just (eid, fid) ->
          fid == targetId
        Nothing ->
          False
  in
    List.filter f results

allResults : Model -> List SearchResult
allResults model =
  case model.results of
    Nothing ->
      []
    Just results ->
      results

view : (Msg -> msg) -> Model -> Html msg
view translateMsg model =
  App.map translateMsg <|
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

resultView : (Msg -> msg) -> (SearchResult -> Html msg) -> SearchResult -> Html msg
resultView translateMsg format result =
    li
      [ Html.Events.onClick (translateMsg <| SelectResult result)
      , style Styles.searchResultItem
      ]
      [ format result ]


resultsView : (Msg -> msg) -> Maybe String -> (SearchResult -> Html msg) -> Model -> Html msg
resultsView transformMsg thisFloorId format model =
    case model.results of
      Nothing ->
        text ""
      Just [] ->
        div [] [ text "Nothing found." ]
      Just results ->
        let
          (inThisFloor, inOtherFloor, inDraftFloor, missing) =
            List.foldl (\({ personId, equipmentIdAndFloorId } as result) (this, other, draft, miss) ->
              case equipmentIdAndFloorId of
                Just (eid, fid) ->
                  if Just fid == thisFloorId then -- this might be draft, but "in this floor" anyway
                    (result :: this, other, draft, miss)
                  else if fid == "draft" then -- this is draft, and user is not looking at it.
                    (this, other, result :: draft, miss)
                  else
                    (this, result :: other, draft, miss)
                Nothing ->
                  (this, other, draft, result :: miss)
            ) ([], [], [], []) results
          each result =
            resultView transformMsg format result
        in
          ul
            [ style Styles.ul ]
            (List.map each (inThisFloor ++ inOtherFloor ++ inDraftFloor ++ missing))
















--
