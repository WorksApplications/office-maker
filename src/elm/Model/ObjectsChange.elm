module Model.ObjectsChange exposing(..)

import Maybe
import Dict exposing (Dict)

import Model.Object as Object exposing (..)
import Model.Floor as Floor exposing (Floor)


type alias Id = String


type alias ObjectModification =
  { new : Object, old : Object, changes : List String }


type alias ObjectsChange =
  { added : List Object
  , modified : List ObjectModification
  , deleted : List Object
  }


empty : ObjectsChange
empty =
  { added = [], modified = [], deleted = [] }
