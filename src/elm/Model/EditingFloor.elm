module Model.EditingFloor exposing (..)

import Model.Floor as Floor exposing (Floor)
import Model.FloorDiff as FloorDiff exposing (ObjectsChange)

import Util.UndoList as UndoList exposing (UndoList)


type alias EditingFloor =
  { version : Int
  , undoList : UndoList Floor
  }


init : Floor -> EditingFloor
init floor =
  { version = floor.version
  , undoList = UndoList.init floor
  }


create : (Floor -> ObjectsChange -> Cmd msg) -> Floor -> (EditingFloor, Cmd msg)
create saveFloorCmd newFloor =
  let
    (propChanged, objectsChange) =
      FloorDiff.diff newFloor Nothing

    newUndoList =
      UndoList.init newFloor

    cmd =
      saveFloorCmd newFloor objectsChange
  in
    ({ version = newFloor.version, undoList = newUndoList }, cmd)


commit : (Floor -> ObjectsChange -> Cmd msg) -> (Floor -> Floor) -> EditingFloor -> (EditingFloor, Cmd msg)
commit saveFloorCmd f efloor =
  let
    floor =
      efloor.undoList.present

    newFloor =
      f floor

    (propChanged, objectsChange) =
      FloorDiff.diff newFloor (Just floor)

    changed =
      propChanged /= [] || objectsChange /= FloorDiff.noObjectsChange

    newUndoList =
      if changed then
        UndoList.new newFloor efloor.undoList
      else
        efloor.undoList

    cmd =
      if changed then
        saveFloorCmd
          { newFloor |
            version = efloor.version -- TODO better API
          }
          objectsChange
      else
        Cmd.none
  in
    ({ efloor | undoList = newUndoList }, cmd)


undo : EditingFloor -> EditingFloor
undo efloor =
  { efloor | undoList = UndoList.undo efloor.undoList }


redo : EditingFloor -> EditingFloor
redo efloor =
  { efloor | undoList = UndoList.redo efloor.undoList }


present : EditingFloor -> Floor
present efloor =
  efloor.undoList.present


changeFloorAfterSave : Floor -> EditingFloor -> EditingFloor
changeFloorAfterSave newFloor efloor =
  { efloor |
    version = newFloor.version
  }
