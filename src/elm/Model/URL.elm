module Model.URL exposing (..) -- where

import Dict
import String
import Http
import Util.UrlParser as UrlParser
import Util.HttpUtil as HttpUtil
import Task exposing (..)

type alias Model =
  { rawHash : String -- deprecated
  , floorId: String
  , query : Maybe String
  , personId : Maybe String
  }

parse : String -> Model
parse hash =
  let
    hash' = String.dropLeft 1 hash
    (floorId, dict) = UrlParser.parse hash'
  in
    { rawHash = hash
    , floorId = Maybe.withDefault "" (List.head floorId)
    , query = Dict.get "q" dict
    , personId = Dict.get "person" dict
    }

stringify : Model -> String
stringify { floorId, query, personId } =
  let
    params =
      List.filterMap
        (\(key, maybeValue) -> Maybe.map (\v -> (key, v)) maybeValue)
        [ ("q", query), ("personId", personId) ]
  in
    "#" ++ Http.url floorId params

updateQuery : String -> Model -> Task a ()
updateQuery newQuery model =
  let
    url = stringify { model | query = Just newQuery }
  in
    HttpUtil.goTo url

updateFloorId : String -> Model -> Task a ()
updateFloorId newId model =
  let
    url = stringify { model | floorId = newId }
  in
    HttpUtil.goTo url
