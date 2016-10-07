module Model.EditMode exposing (..)


type EditMode =
    Viewing Bool
  | Select
  | Pen
  | Stamp
  | LabelMode


isEditMode : EditMode -> Bool
isEditMode mode =
  case mode of
    Viewing _ -> False
    _ -> True


isPrintMode : EditMode -> Bool
isPrintMode mode =
  case mode of
    Viewing True -> True
    _ -> False
