module Model.EditingFloor exposing (..)

import Dict exposing (Dict)

import Model.Floor as Floor exposing (Floor)
import Model.FloorDiff as FloorDiff
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)

import Util.UndoList as UndoList exposing (UndoList)


type alias EditingFloor =
  { synchronizedFloor : Floor
  , undoList : UndoList Floor
  }


init : Floor -> EditingFloor
init floor =
  { synchronizedFloor = floor
  , undoList = UndoList.init floor
  }


update : (Floor -> Floor) -> EditingFloor -> EditingFloor
update f efloor =
  let
    floor =
      efloor.undoList.present

    newFloor =
      f floor

    (propChanged, objectsChange) =
      FloorDiff.diff newFloor (Just floor)

    changed =
      propChanged /= [] || objectsChange /= ObjectsChange.empty

    newUndoList =
      if changed then
        UndoList.new newFloor efloor.undoList
      else
        efloor.undoList
  in
    { efloor | undoList = newUndoList }


undo : EditingFloor -> EditingFloor
undo efloor =
  { efloor | undoList = UndoList.undo efloor.undoList }


redo : EditingFloor -> EditingFloor
redo efloor =
  { efloor | undoList = UndoList.redo efloor.undoList }


present : EditingFloor -> Floor
present efloor =
  efloor.undoList.present
