module Model.FloorInfo exposing (..)

import Dict exposing (Dict)

import CoreType exposing (..)
import Model.Floor exposing (FloorBase)


type FloorInfo
  = FloorInfo (Maybe FloorBase) FloorBase


init : Maybe FloorBase -> FloorBase -> FloorInfo
init publicFloor editingFloor =
  FloorInfo publicFloor editingFloor


isNeverPublished : FloorInfo -> Bool
isNeverPublished floorsInfo =
  case floorsInfo of
    FloorInfo Nothing _ ->
      True

    _ ->
      False


idOf : FloorInfo -> FloorId
idOf (FloorInfo publicFloor editingFloor) =
  editingFloor.id


publicFloor : FloorInfo -> Maybe FloorBase
publicFloor (FloorInfo publicFloor editingFloor) =
  publicFloor


editingFloor : FloorInfo -> FloorBase
editingFloor (FloorInfo publicFloor editingFloor) =
  editingFloor


findPublicFloor : FloorId -> Dict FloorId FloorInfo -> Maybe FloorBase
findPublicFloor floorId floorsInfo =
  floorsInfo
    |> findFloor floorId
    |> Maybe.andThen publicFloor


findFloor : FloorId -> Dict FloorId FloorInfo -> Maybe FloorInfo
findFloor floorId floorsInfo =
  floorsInfo
    |> Dict.get floorId


mergeFloor : FloorBase -> Dict FloorId FloorInfo -> Dict FloorId FloorInfo
mergeFloor editingFloor floorsInfo =
  floorsInfo
    |> Dict.update editingFloor.id (Maybe.map (mergeFloorHelp editingFloor))


mergeFloorHelp : FloorBase -> FloorInfo -> FloorInfo
mergeFloorHelp floor (FloorInfo publicFloor editingFloor) =
  if floor.version < 0 then
    FloorInfo publicFloor floor
  else
    FloorInfo (Just floor) editingFloor


toValues : Dict FloorId FloorInfo -> List FloorInfo
toValues floorsInfo =
  floorsInfo
    |> Dict.toList
    |> List.map Tuple.second


toPublicList : Dict FloorId FloorInfo -> List FloorBase
toPublicList floorsInfo =
  floorsInfo
    |> toValues
    |> List.filterMap publicFloor
    |> List.sortBy .ord


toEditingList : Dict FloorId FloorInfo -> List FloorBase
toEditingList floorsInfo =
  floorsInfo
    |> toValues
    |> List.map editingFloor
    |> List.sortBy .ord


sortByPublicOrder : Dict FloorId FloorInfo -> Maybe FloorInfo
sortByPublicOrder floorsInfo =
  floorsInfo
    |> toValues
    |> List.map (\info -> publicFloor info |> Maybe.map .ord |> Maybe.withDefault 999999 |> (,) info)
    |> List.sortBy Tuple.second
    |> List.map Tuple.first
    |> List.head
