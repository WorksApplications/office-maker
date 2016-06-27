module Util.ShortCut exposing
  ( Model
  , Event(..)
  , init
  , update
  )

import Char

type Event =
    Ctrl
  | Shift
  | Del
  | A
  | C
  | F
  | P
  | S
  | V
  | X
  | Y
  | Z
  | Enter
  | LeftArrow
  | UpArrow
  | RightArrow
  | DownArrow
  | Other Int
  | None

type alias Model =
  { ctrl : Bool
  , shift : Bool
  }

init : Model
init =
  { ctrl = False
  , shift = False
  }

update : Bool -> Int -> Model -> (Model, Event)
update isDown keyCode model =
  let
    event =
      if not isDown then None
      else if keyCode == 13 then Enter
      else if keyCode == 16 then Shift
      else if keyCode == 17 then Ctrl
      else if keyCode == 46 then Del
      else if keyCode == (Char.toCode 'A') then A
      else if keyCode == (Char.toCode 'C') then C
      else if keyCode == (Char.toCode 'F') then F
      else if keyCode == (Char.toCode 'S') then S
      else if keyCode == (Char.toCode 'P') then P
      else if keyCode == (Char.toCode 'V') then V
      else if keyCode == (Char.toCode 'X') then X
      else if keyCode == (Char.toCode 'Y') then Y
      else if keyCode == (Char.toCode 'Z') then Z
      else if keyCode == 37 then LeftArrow
      else if keyCode == 38 then UpArrow
      else if keyCode == 39 then RightArrow
      else if keyCode == 40 then DownArrow
      else Other keyCode
    newModel =
      if keyCode == 16 then
        { model | shift = isDown }
      else if keyCode == 17 then
        { model | ctrl = isDown }
      else
        model
  in
    (newModel, event)
