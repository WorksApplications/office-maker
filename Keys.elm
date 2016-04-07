module Keys where

import Native.Keys

import Keyboard
import Char
import HtmlEvent exposing (..)
import Json.Decode exposing (..)

type Action =
    KeyCtrl Bool
  | KeyShift Bool
  | KeyDel Bool
  | KeyC Bool
  | KeyV Bool
  | KeyX Bool
  | KeyY
  | KeyZ
  | KeyLeftArrow
  | KeyUpArrow
  | KeyRightArrow
  | KeyDownArrow
  | Other

type alias Model =
  { ctrl : Bool
  , shift : Bool
  }

init : Model
init =
  { ctrl = False
  , shift = False
  }

inputs : List (Signal Action)
inputs =
  [ Signal.map KeyCtrl Keyboard.ctrl
  , Signal.map KeyShift Keyboard.shift
  , Signal.map KeyDel (Keyboard.isDown 46)
  , Signal.map KeyC (Keyboard.isDown (Char.toCode 'C'))
  , Signal.map KeyV (Keyboard.isDown (Char.toCode 'V'))
  , Signal.map KeyX (Keyboard.isDown (Char.toCode 'X'))
  , Signal.map (\e ->
      if e.keyCode == (Char.toCode 'Y') then
        KeyY
      else if e.keyCode == (Char.toCode 'Z') then
        KeyZ
      else if e.keyCode == 37 then
        KeyLeftArrow
      else if e.keyCode == 38 then
        KeyUpArrow
      else if e.keyCode == 39 then
        KeyRightArrow
      else if e.keyCode == 40 then
        KeyDownArrow
      else
        Other
    ) downs
  ]

update : Action -> Model -> Model
update action model =
  case action of
    KeyCtrl down ->
      { model | ctrl = down }
    KeyShift down ->
      { model | ctrl = down }
    _ -> model

----

downs_ : Signal Json.Decode.Value
downs_ = Native.Keys.downs

downs : Signal KeyboardEvent
downs =
  Signal.filterMap (\value ->
    case Json.Decode.decodeValue decodeKeyboardEvent value of
      Ok e -> Just e
      _ -> Nothing
  ) initKeyboardEvent downs_


initKeyboardEvent : KeyboardEvent
initKeyboardEvent = { keyCode = -1, ctrlKey = False, shiftKey = False }
