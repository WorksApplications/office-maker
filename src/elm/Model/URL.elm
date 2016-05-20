module Model.URL exposing (..) -- where

import Util.UrlDecode

type alias Result =
  { floorId: Maybe String
  , query : Maybe String
  , person : Maybe String
  }
