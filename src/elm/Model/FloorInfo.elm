module Model.FloorInfo exposing (..)

import Dict exposing (Dict)
import Model.Floor exposing (FloorBase)


type alias FloorId = String


type FloorInfo
  = FloorInfo FloorBase FloorBase


init : FloorBase -> FloorBase -> FloorInfo
init publicFloor editingFloor =
  if publicFloor.id /= editingFloor.id then
    Debug.crash "IDs are not same: "
  else
    FloorInfo publicFloor editingFloor


idOf : FloorInfo -> FloorId
idOf (FloorInfo publicFloor editingFloor) =
  editingFloor.id


publicFloor : FloorInfo -> FloorBase
publicFloor (FloorInfo publicFloor editingFloor) =
  publicFloor


editingFloor : FloorInfo -> FloorBase
editingFloor (FloorInfo publicFloor editingFloor) =
  editingFloor


replaceEditingFloor : FloorBase -> FloorInfo -> FloorInfo
replaceEditingFloor editingFloor (FloorInfo publicFloor _) =
  FloorInfo publicFloor editingFloor


findPublicFloor : FloorId -> Dict FloorId FloorInfo -> Maybe FloorBase
findPublicFloor floorId floorsInfo =
  floorsInfo
    |> findFloor floorId
    |> Maybe.map publicFloor


findFloor : FloorId -> Dict FloorId FloorInfo -> Maybe FloorInfo
findFloor floorId floorsInfo =
  floorsInfo
    |> Dict.get floorId


addEditingFloor : FloorBase -> Dict FloorId FloorInfo -> Dict FloorId FloorInfo
addEditingFloor editingFloor floorsInfo =
  floorsInfo
    |> Dict.update editingFloor.id (Maybe.map (replaceEditingFloor editingFloor))


toPublicList : Dict FloorId FloorInfo -> List FloorBase
toPublicList floorsInfo =
  floorsInfo
    |> Dict.toList
    |> List.map (snd >> publicFloor)
    |> List.sortBy .ord


toEditingList : Dict FloorId FloorInfo -> List FloorBase
toEditingList floorsInfo =
  floorsInfo
    |> Dict.toList
    |> List.map (snd >> editingFloor)
    |> List.sortBy .ord
