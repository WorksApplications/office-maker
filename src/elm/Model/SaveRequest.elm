module Model.SaveRequest exposing (..)

import Model.Floor exposing (Floor)
import Model.EditingFloor as EditingFloor exposing (EditingFloor)
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)
import CoreType exposing (..)


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


reduceRequest : Maybe EditingFloor -> List SaveRequest -> ReducedSaveRequest
reduceRequest maybeEditingFloor list =
    case maybeEditingFloor of
        Just efloor ->
            List.foldr (reduceRequestHelp efloor) emptyReducedSaveRequest list

        Nothing ->
            emptyReducedSaveRequest


reduceRequestHelp : EditingFloor -> SaveRequest -> ReducedSaveRequest -> ReducedSaveRequest
reduceRequestHelp efloor req reducedSaveRequest =
    case req of
        SaveFloor floor ->
            { reducedSaveRequest
                | floor = Just floor
            }

        PublishFloor floorId ->
            { reducedSaveRequest
                | publish = Just floorId
            }

        SaveObjects objectsChange ->
            { reducedSaveRequest
                | objects =
                    ObjectsChange.merge
                        (EditingFloor.present efloor).objects
                        objectsChange
                        reducedSaveRequest.objects
            }
