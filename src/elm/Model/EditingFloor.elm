module Model.EditingFloor exposing (..)

import Model.Floor as Floor exposing (Floor)
import Model.FloorDiff as FloorDiff
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)

import Util.UndoList as UndoList exposing (UndoList)


type alias EditingFloor =
  { undoList : UndoList Floor
  }


init : Floor -> EditingFloor
init floor =
  { undoList = UndoList.init floor
  }


updateFloor : (Floor -> Floor) -> EditingFloor -> (EditingFloor, Floor)
updateFloor f efloor =
  let
    floor =
      efloor.undoList.present

    newFloor =
      f floor

    propChanged =
      FloorDiff.diffPropertyChanges newFloor (Just floor)

    changed =
      propChanged /= []

    newUndoList =
      if changed then
        UndoList.new newFloor efloor.undoList
      else
        efloor.undoList
  in
    ( { efloor | undoList = newUndoList }
    , newFloor
    )


updateObjects : (Floor -> Floor) -> EditingFloor -> (EditingFloor, ObjectsChange)
updateObjects f efloor =
  let
    floor =
      efloor.undoList.present

    newFloor =
      f floor

    objectsChange =
      FloorDiff.diffObjects newFloor.objects floor.objects |> ObjectsChange.simplify

    changed =
      not <| ObjectsChange.isEmpty objectsChange

    newUndoList =
      if changed then
        UndoList.new newFloor efloor.undoList
      else
        efloor.undoList
  in
    ({ efloor | undoList = newUndoList }, objectsChange)


syncObjects : ObjectsChange -> EditingFloor -> EditingFloor
syncObjects change efloor =
  let
    undoList =
      efloor.undoList

    -- Unsafe operation!
    newUndoList =
      { undoList
      | present = Floor.changeObjectsByChanges change undoList.present
      }
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
