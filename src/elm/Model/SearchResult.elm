module Model.SearchResult exposing (..)

import Model.Equipments exposing (Equipment)

type alias Id = String

type alias SearchResult =
  { personId : Maybe Id
  , equipmentIdAndFloorId : Maybe (Equipment, Id)
  }
