module Model.SearchResult exposing (..)

import Model.Object exposing (Object)

type alias Id = String

type alias SearchResult =
  { personId : Maybe Id
  , objectIdAndFloorId : Maybe (Object, Id)
  }
