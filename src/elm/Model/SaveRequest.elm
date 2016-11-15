module Model.SaveRequest exposing (..)

import Model.Floor exposing (Floor)
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)

type alias FloorId = String

type SaveRequest
  = SaveFloor Floor
  | PublishFloor FloorId
  | SaveObjects ObjectsChange


type alias ReducedSaveRequest =
  { floor : Maybe Floor
  , publish : Maybe FloorId
  , objects : ObjectsChange
  }


emptyReducedSaveRequest : ReducedSaveRequest
emptyReducedSaveRequest =
  { floor = Nothing
  , publish = Nothing
  , objects = ObjectsChange.empty
  }


reduceRequest : List SaveRequest -> ReducedSaveRequest
reduceRequest list =
  List.foldr reduceRequestHelp emptyReducedSaveRequest list


reduceRequestHelp : SaveRequest -> ReducedSaveRequest -> ReducedSaveRequest
reduceRequestHelp req reducedSaveRequest =
  case req of
    SaveFloor floor ->
      { reducedSaveRequest |
        floor = Just floor
      }

    PublishFloor floorId ->
      { reducedSaveRequest |
        publish = Just floorId
      }

    SaveObjects objectsChange ->
      { reducedSaveRequest |
        objects = ObjectsChange.merge objectsChange reducedSaveRequest.objects
      }
