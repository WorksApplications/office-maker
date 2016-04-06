module HtmlUtil where

import Native.HtmlUtil
import Signal exposing (Address)
import Html exposing (Attribute)
import Html.Events exposing (on, onWithOptions)
import Json.Decode exposing (Decoder, object2, object5, (:=), int, bool)
import Task exposing (Task)

type HtmlUtilError =
  IdNotFound String

focus : String -> Task HtmlUtilError ()
focus id =
  Task.mapError
    (always (IdNotFound id))
    (Native.HtmlUtil.focus id)

blur  : String -> Task HtmlUtilError ()
blur id =
  Task.mapError
    (always (IdNotFound id))
    (Native.HtmlUtil.blur id)

downs_ : Signal Json.Decode.Value
downs_ = Native.HtmlUtil.downs

downs : Signal KeyboardEvent
downs =
  Signal.filterMap (\value -> case Json.Decode.decodeValue decodeKeyboardEvent value of
    Ok e -> Just e
    _ -> Nothing
  ) initKeyboardEvent downs_

type alias MouseEvent =
  { clientX : Int
  , clientY : Int
  , layerX : Int
  , layerY : Int
  , ctrlKey : Bool
  }
type alias KeyboardEvent =
  { keyCode : Int
  , ctrlKey : Bool
  }
initKeyboardEvent = { keyCode = -1, ctrlKey = False }

decodeMousePosition : Decoder MouseEvent
decodeMousePosition =
  object5
    (\clientX clientY layerX layerY ctrl ->
      { clientX = clientX
      , clientY = clientY
      , layerX = layerX
      , layerY = layerY
      , ctrlKey = ctrl })
    ("clientX" := int)
    ("clientY" := int)
    ("layerX" := int)
    ("layerY" := int)
    ("ctrlKey" := bool)

decodeKeyboardEvent : Decoder KeyboardEvent
decodeKeyboardEvent =
  object2
    (\keyCode ctrlKey -> { keyCode = keyCode, ctrlKey = ctrlKey })
    ("keyCode" := int)
    ("ctrlKey" := bool)

onMouseMove' : Address MouseEvent -> Attribute
onMouseMove' address =
  onWithOptions
    "mousemove" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onMouseUp' : Address MouseEvent -> Attribute
onMouseUp' address =
  on "mouseup" decodeMousePosition (Signal.message address)

onMouseDown' : Address MouseEvent -> Attribute
onMouseDown' address =
  onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onDblClick' : Address MouseEvent -> Attribute
onDblClick' address =
  onWithOptions "dblclick" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onClick' : Address MouseEvent -> Attribute
onClick' address =
  onWithOptions "click" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onInput' : Address String -> Attribute
onInput' address =
  onWithOptions "input" { stopPropagation = True, preventDefault = True } Html.Events.targetValue (Signal.message address)

-- onKeyUp' : Address KeyboardEvent -> Attribute
-- onKeyUp' address =
--   on "keyup" decodeKeyboardEvent (Signal.message address)

onKeyDown' : Address KeyboardEvent -> Attribute
onKeyDown' address =
  on "keydown" decodeKeyboardEvent (Signal.message address)

onContextMenu' : Address MouseEvent -> Attribute
onContextMenu' address =
  onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)
