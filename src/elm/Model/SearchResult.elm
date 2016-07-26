module Model.SearchResult exposing (..)

import Model.Equipment exposing (Equipment)

type alias Id = String

type alias SearchResult =
  { personId : Maybe Id
  , equipmentIdAndFloorId : Maybe (Equipment, Id)
  }
