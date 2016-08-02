module Model.EditingFloor exposing (..)

import Model.Floor as Floor
import Model.FloorDiff as FloorDiff
import Util.UndoList as UndoList exposing (UndoList)

type alias Floor = Floor.Model


commit : (Floor -> Cmd msg) -> Floor.Msg -> UndoList Floor -> (UndoList Floor, Cmd msg)
commit saveFloorCmd msg undoList =
  let
    floor =
      undoList.present

    newFloor =
      Floor.update msg floor

    (propChanged, equipmentsChange) =
      FloorDiff.getChanges newFloor floor

    changed =
      propChanged || equipmentsChange == FloorDiff.noEquipmentsChange

    newUndoList =
      if changed then
        UndoList.new newFloor undoList
      else
        undoList

    cmd =
      if changed then
        saveFloorCmd newFloor
      else
        Cmd.none
  in
    (newUndoList, cmd)
