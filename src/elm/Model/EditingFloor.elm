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


updateFloorAndObjects : (Floor -> Floor) -> EditingFloor -> ( EditingFloor, Floor, ObjectsChange )
updateFloorAndObjects f efloor =
    let
        floor =
            efloor.undoList.present

        newFloor =
            f floor

        propChanged =
            FloorDiff.diffPropertyChanges newFloor (Just floor)

        objectsChange =
            FloorDiff.diffObjects newFloor.objects floor.objects
                |> ObjectsChange.simplify

        changed =
            propChanged /= [] || (not <| ObjectsChange.isEmpty objectsChange)

        newUndoList =
            if changed then
                UndoList.new newFloor efloor.undoList
            else
                efloor.undoList
    in
        ( { efloor | undoList = newUndoList }
        , newFloor
        , objectsChange
        )


updateFloor : (Floor -> Floor) -> EditingFloor -> ( EditingFloor, Floor )
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


updateObjects : (Floor -> Floor) -> EditingFloor -> ( EditingFloor, ObjectsChange )
updateObjects f efloor =
    let
        floor =
            efloor.undoList.present

        newFloor =
            f floor

        objectsChange =
            FloorDiff.diffObjects newFloor.objects floor.objects
                |> ObjectsChange.simplify

        changed =
            not <| ObjectsChange.isEmpty objectsChange

        newUndoList =
            if changed then
                UndoList.new newFloor efloor.undoList
            else
                efloor.undoList
    in
        ( { efloor | undoList = newUndoList }, objectsChange )


syncObjects : ObjectsChange -> EditingFloor -> EditingFloor
syncObjects change efloor =
    let
        undoList =
            efloor.undoList

        separated =
            ObjectsChange.separate change

        -- Unsafe operation!
        newUndoList =
            { undoList
                | present = Floor.addObjects (separated.added ++ separated.modified) undoList.present
            }
    in
        { efloor | undoList = newUndoList }


undo : EditingFloor -> ( EditingFloor, ObjectsChange )
undo efloor =
    let
        ( undoList, objectsChange ) =
            UndoList.undoReplace
                ObjectsChange.empty
                (\prev current ->
                    let
                        objectsChange =
                            FloorDiff.diffObjects prev.objects current.objects
                    in
                        ( Floor.changeObjectsByChanges objectsChange current
                        , objectsChange |> ObjectsChange.simplify
                        )
                )
                efloor.undoList
    in
        ( { efloor | undoList = undoList }, objectsChange )


redo : EditingFloor -> ( EditingFloor, ObjectsChange )
redo efloor =
    let
        ( undoList, objectsChange ) =
            UndoList.redoReplace
                ObjectsChange.empty
                (\next current ->
                    let
                        objectsChange =
                            FloorDiff.diffObjects next.objects current.objects
                    in
                        ( Floor.changeObjectsByChanges objectsChange current
                        , objectsChange |> ObjectsChange.simplify
                        )
                )
                efloor.undoList
    in
        ( { efloor | undoList = undoList }, objectsChange )


present : EditingFloor -> Floor
present efloor =
    efloor.undoList.present
