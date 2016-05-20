module Model.URL exposing (..) -- where

import String
import Util.UrlDecode

type alias Model =
  { rawHash : String -- deprecated
  , floorId: String
  , query : Maybe String
  , personId : Maybe String
  }

parse : String -> Model
parse hash =
    { rawHash = hash
    , floorId = String.dropLeft 1 hash
    , query = Nothing
    , personId = Nothing
    }
