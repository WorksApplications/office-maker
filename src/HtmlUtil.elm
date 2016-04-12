module HtmlUtil where

import HtmlEvent exposing (..)
import Native.HtmlUtil
import Signal exposing (Address)
import Html exposing (Attribute)
import Html.Events exposing (on, onWithOptions)
import Json.Decode exposing (..)
import Task exposing (Task)

type HtmlUtilError =
  IdNotFound String

type alias KeyboardEvent = HtmlEvent.KeyboardEvent
type alias MouseEvent = HtmlEvent.MouseEvent

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

onMouseMove' : Address MouseEvent -> Attribute
onMouseMove' address =
  onWithOptions
    "mousemove" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onMouseEnter' : Address MouseEvent -> Attribute
onMouseEnter' address =
  onWithOptions
    "mouseenter" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onMouseLeave' : Address MouseEvent -> Attribute
onMouseLeave' address =
  onWithOptions
    "mouseleave" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

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

onChange' : Address String -> Attribute
onChange' address =
  onWithOptions "change" { stopPropagation = True, preventDefault = True } Html.Events.targetValue (Signal.message address)

-- onKeyUp' : Address KeyboardEvent -> Attribute
-- onKeyUp' address =
--   on "keyup" decodeKeyboardEvent (Signal.message address)

onKeyDown' : Address KeyboardEvent -> Attribute
onKeyDown' address =
  onWithOptions "keydown" { stopPropagation = True, preventDefault = True } decodeKeyboardEvent (Signal.message address)

onKeyDown'' : Address KeyboardEvent -> Attribute
onKeyDown'' address =
  on "keydown" decodeKeyboardEvent (Signal.message address)

onContextMenu' : Address MouseEvent -> Attribute
onContextMenu' address =
  onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } decodeMousePosition (Signal.message address)

onMouseWheel : Address a -> (MouseWheelEvent -> a) -> Attribute
onMouseWheel address toAction =
  let
    handler v = Signal.message address (toAction v)
  in
    onWithOptions "wheel" { stopPropagation = True, preventDefault = True } decodeWheelEvent handler

mouseDownDefence : Address a -> a -> Attribute
mouseDownDefence address noOp =
  onMouseDown' (Signal.forwardTo address (always noOp))


decodeMousePosition : Decoder MouseEvent
decodeMousePosition =
  object6
    (\clientX clientY layerX layerY ctrl shift ->
      { clientX = clientX
      , clientY = clientY
      , layerX = layerX
      , layerY = layerY
      , ctrlKey = ctrl
      , shiftKey = shift
      }
    )
    ("clientX" := int)
    ("clientY" := int)
    ("layerX" := int)
    ("layerY" := int)
    ("ctrlKey" := bool)
    ("shiftKey" := bool)


type alias MouseWheelEvent =
  { clientX : Int
  , clientY : Int
  , layerX : Int
  , layerY : Int
  , ctrlKey : Bool
  , shiftKey : Bool
  , value : Float
  }

decodeWheelEvent : Json.Decode.Decoder MouseWheelEvent
decodeWheelEvent =
  (object7
    (\clientX clientY layerX layerY ctrl shift value ->
      { clientX = clientX
      , clientY = clientY
      , layerX = layerX
      , layerY = layerY
      , ctrlKey = ctrl
      , shiftKey = shift
      , value = value
      }
    )
    ("clientX" := int)
    ("clientY" := int)
    ("layerX" := int)
    ("layerY" := int)
    ("ctrlKey" := bool)
    ("shiftKey" := bool)
    (oneOf
      [ at [ "deltaY" ] float
      , at [ "wheelDelta" ] float |> map (\v -> -v)
      ]))
    `andThen` (\e -> if e.value /= 0 then succeed e else fail "Wheel of 0")
