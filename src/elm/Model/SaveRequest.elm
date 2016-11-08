module Model.SaveRequest exposing (..)

import Model.Floor exposing (Floor)
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)
import Model.FloorDiff as FloorDiff

type alias Id = String

type SaveRequest
  = SaveFloor Floor Floor
  | PublishFloor Id


type SaveRequestOpt
  = SaveFloorOpt Floor ObjectsChange
  | PublishFloorOpt Id


reduceRequest : List SaveRequest -> List SaveRequestOpt
reduceRequest list =
  fst <| List.foldr reduceRequestHelp ([], Nothing) list


reduceRequestHelp : SaveRequest -> (List SaveRequestOpt, Maybe Floor) -> (List SaveRequestOpt, Maybe Floor)
reduceRequestHelp req (list, maybeBaseFloor) =
  case req of
    SaveFloor floor oldFloor ->
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
            (SaveFloorOpt floor objectsChange :: tail, Just baseFloor)
        else
          (list, maybeBaseFloor)

    PublishFloor id ->
      (PublishFloorOpt id :: list, Nothing)
