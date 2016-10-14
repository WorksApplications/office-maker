module Model.SaveRequestDebouncer exposing (..)


import Model.Floor exposing (Floor)
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)
import Model.FloorDiff as FloorDiff

type alias Id = String


type SaveRequest
  = SaveFloor Int Floor Floor
  | PublishFloor Id


type SaveRequestOpt
  = SaveFloorOpt Floor Int ObjectsChange
  | PublishFloorOpt Id


type SaveRequestDebouncer
  = SaveRequestDebouncer { ready : Bool, requests : List SaveRequest }


init : SaveRequestDebouncer
init =
  SaveRequestDebouncer { ready = True, requests = [] }


isReady : SaveRequestDebouncer -> Bool
isReady (SaveRequestDebouncer { ready }) =
  ready


isEmpty : SaveRequestDebouncer -> Bool
isEmpty (SaveRequestDebouncer { requests }) =
  List.isEmpty requests


push : SaveRequest -> SaveRequestDebouncer -> SaveRequestDebouncer
push request (SaveRequestDebouncer debouncer) =
  SaveRequestDebouncer { debouncer | requests = request :: debouncer.requests }


unlock : SaveRequestDebouncer -> SaveRequestDebouncer
unlock (SaveRequestDebouncer debouncer) =
  SaveRequestDebouncer { debouncer | ready = True }


lockAndGetReducedRequests : SaveRequestDebouncer -> (SaveRequestDebouncer, List SaveRequestOpt)
lockAndGetReducedRequests (SaveRequestDebouncer debouncer) =
  let
    (list, maybeOldFloor) =
      debouncer.requests
        |> List.foldr reduceRequest ([], Nothing)
  in
    (SaveRequestDebouncer { debouncer | ready = False, requests = [] }, list)


reduceRequest : SaveRequest -> (List SaveRequestOpt, Maybe Floor) -> (List SaveRequestOpt, Maybe Floor)
reduceRequest req (list, maybeBaseFloor) =
  case req of
    SaveFloor version floor oldFloor ->
      let
        baseFloor =
          case maybeBaseFloor of
            Just baseFloor ->
              if floor.id == baseFloor.id then
                baseFloor
              else
                oldFloor

            _ ->
              oldFloor

        (propChanged, objectsChange) =
          FloorDiff.diff floor (Just baseFloor)

        changed =
          propChanged /= [] || objectsChange /= ObjectsChange.empty
      in
        if changed then
          let
            tail =
              case (maybeBaseFloor, list) of
                (Just baseFloor, _ :: rest) ->
                  if floor.id == baseFloor.id then
                    rest
                  else
                    list

                _ ->
                  list
          in
            (SaveFloorOpt floor version objectsChange :: tail, Just baseFloor)
        else
          (list, maybeBaseFloor)

    PublishFloor id ->
      (PublishFloorOpt id :: list, Nothing)
