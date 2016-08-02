module Model.EditingFloor exposing (..)

import Model.Floor as Floor
import Model.FloorDiff as FloorDiff exposing (EquipmentsChange)
import Util.UndoList as UndoList exposing (UndoList)

type alias Floor = Floor.Model


init : (Floor -> EquipmentsChange -> Cmd msg) -> Floor -> (UndoList Floor, Cmd msg)
init saveFloorCmd newFloor =
  let
    (propChanged, equipmentsChange) =
      FloorDiff.diff newFloor Nothing

    newUndoList =
      UndoList.init newFloor

    cmd =
      saveFloorCmd newFloor equipmentsChange
  in
    (newUndoList, cmd)


commit : (Floor -> EquipmentsChange -> Cmd msg) -> Floor.Msg -> UndoList Floor -> (UndoList Floor, Cmd msg)
commit saveFloorCmd msg undoList =
  let
    floor =
      undoList.present

    newFloor =
      Floor.update msg floor

    (propChanged, equipmentsChange) =
      FloorDiff.diff newFloor (Just floor)

    changed =
      propChanged /= [] || equipmentsChange /= FloorDiff.noEquipmentsChange

    newUndoList =
      if changed then
        UndoList.new newFloor undoList
      else
        undoList

    cmd =
      if changed then
        saveFloorCmd newFloor equipmentsChange
      else
        Cmd.none
  in
    (newUndoList, cmd)
