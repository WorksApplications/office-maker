module Model.URL exposing (..) -- where

import Dict
import String
import Util.UrlParser as UrlParser

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
