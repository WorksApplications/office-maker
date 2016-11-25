module Model.Mode exposing (..)


type Tab
  = SearchTab
  | EditTab


type Mode
  = Viewing Bool EditingMode
  | Editing Tab EditingMode


type EditingMode
  = Select
  | Pen
  | Stamp
  | Label


init : Bool -> Mode
init isEditMode =
  if isEditMode then
    Editing EditTab Select
  else
    Viewing False Select


toggleEditing : Mode -> Mode
toggleEditing mode =
  case mode of
    Viewing _ editMode -> Editing EditTab editMode
    Editing _ editMode -> Viewing False editMode


togglePrintView : Mode -> Mode
togglePrintView mode =
  case mode of
    Viewing printMode editMode -> Viewing (not printMode) editMode
    Editing _ editMode -> Viewing True editMode


toSelectMode : Mode -> Mode
toSelectMode mode =
  case mode of
    Editing tab _ -> Editing tab Select
    _ -> Editing EditTab Select


toStampMode : Mode -> Mode
toStampMode mode =
  case mode of
    Editing tab _ -> Editing tab Stamp
    _ -> Editing EditTab Stamp


isEditMode : Mode -> Bool
isEditMode mode =
  case mode of
    Editing _ _ -> True
    _ -> False


isSelectMode : Mode -> Bool
isSelectMode mode =
  case mode of
    Editing _ Select -> True
    _ -> False


isPenMode : Mode -> Bool
isPenMode mode =
  case mode of
    Editing _ Pen -> True
    _ -> False


isStampMode : Mode -> Bool
isStampMode mode =
  case mode of
    Editing _ Stamp -> True
    _ -> False


isLabelMode : Mode -> Bool
isLabelMode mode =
  case mode of
    Editing _ Label -> True
    _ -> False


isViewMode : Mode -> Bool
isViewMode mode =
  case mode of
    Viewing _ _ -> True
    _ -> False


isPrintMode : Mode -> Bool
isPrintMode mode =
  case mode of
    Viewing True _ -> True
    _ -> False


changeTab : Tab -> Mode -> Mode
changeTab tab mode =
  case mode of
    Editing _ editingMode -> Editing tab editingMode
    x -> x


changeEditingMode : EditingMode -> Mode -> Mode
changeEditingMode editingMode mode =
  case mode of
    Editing tab _ -> Editing tab editingMode
    _ -> Editing EditTab editingMode


showSearchTab : Mode -> Mode
showSearchTab mode =
  case mode of
    Editing _ editingMode -> Editing SearchTab editingMode
    x -> x
