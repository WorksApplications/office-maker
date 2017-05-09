module Model.Mode exposing (..)


type Mode
    = Mode
        { printMode : Bool
        , searchResult : Bool
        , editing : Bool
        , editMode : EditingMode
        }


type EditingMode
    = Select
    | Pen
    | Stamp
    | Label


init : Bool -> Mode
init isEditMode =
    Mode
        { printMode = False
        , searchResult = False
        , editing = isEditMode
        , editMode = Select
        }


showingSearchResult : Mode -> Bool
showingSearchResult (Mode mode) =
    mode.searchResult


toggleEditing : Mode -> Mode
toggleEditing (Mode mode) =
    Mode
        { mode
            | editing = not (mode.editing)
        }


togglePrintView : Mode -> Mode
togglePrintView (Mode mode) =
    Mode
        { mode
            | printMode = not (mode.printMode)
        }


toSelectMode : Mode -> Mode
toSelectMode (Mode mode) =
    Mode
        { mode
            | editing = True
            , editMode = Select
        }


toStampMode : Mode -> Mode
toStampMode (Mode mode) =
    Mode
        { mode
            | editing = True
            , editMode = Stamp
        }


isEditMode : Mode -> Bool
isEditMode ((Mode mode) as mode_) =
    mode.editing && not (isPrintMode mode_)


currentEditMode : Mode -> Maybe EditingMode
currentEditMode (Mode mode) =
    if mode.editing then
        Just mode.editMode
    else
        Nothing


isSelectMode : Mode -> Bool
isSelectMode (Mode mode) =
    mode.editing && mode.editMode == Select


isPenMode : Mode -> Bool
isPenMode (Mode mode) =
    mode.editing && mode.editMode == Pen


isStampMode : Mode -> Bool
isStampMode (Mode mode) =
    mode.editing && mode.editMode == Stamp


isLabelMode : Mode -> Bool
isLabelMode (Mode mode) =
    mode.editing && mode.editMode == Label


isViewMode : Mode -> Bool
isViewMode (Mode mode) =
    not mode.editing


isPrintMode : Mode -> Bool
isPrintMode (Mode mode) =
    mode.printMode


changeEditingMode : EditingMode -> Mode -> Mode
changeEditingMode editingMode (Mode mode) =
    Mode
        { mode
            | editing = True
            , editMode = editingMode
        }


showSearchResult : Mode -> Mode
showSearchResult (Mode mode) =
    Mode
        { mode
            | searchResult = True
        }


hideSearchResult : Mode -> Mode
hideSearchResult (Mode mode) =
    Mode
        { mode
            | searchResult = False
        }
