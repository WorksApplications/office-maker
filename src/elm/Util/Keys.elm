module Util.Keys where

import Native.Keys

import Keyboard
import Char
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
  | Enter Bool
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
  , Signal.map Enter (Keyboard.isDown 13)
  , Signal.map KeyC (Keyboard.isDown (Char.toCode 'C'))
  , Signal.map KeyV (Keyboard.isDown (Char.toCode 'V'))
  , Signal.map KeyX (Keyboard.isDown (Char.toCode 'X'))
  , Signal.map (\keyCode ->
      if keyCode == (Char.toCode 'Y') then
        KeyY
      else if keyCode == (Char.toCode 'Z') then
        KeyZ
      else if keyCode == 37 then
        KeyLeftArrow
      else if keyCode == 38 then
        KeyUpArrow
      else if keyCode == 39 then
        KeyRightArrow
      else if keyCode == 40 then
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
      { model | shift = down }
    _ -> model

----

downs_ : Signal Json.Decode.Value
downs_ = Native.Keys.downs

downs : Signal Int
downs =
  Signal.filterMap (\value ->
    case Json.Decode.decodeValue (at ["keyCode"] int) value of
      Ok e -> Just e
      _ -> Nothing
  ) -1 downs_
