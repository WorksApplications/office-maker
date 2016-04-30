module Util.HtmlUtil where

import Util.HtmlEvent as HtmlEvent exposing (..)
import Native.HtmlUtil
import Signal exposing (Address)
import Html exposing (Html, Attribute)
import Html.Attributes
import Html.Events exposing (on, onWithOptions)
import Json.Decode exposing (..)
import Util.File exposing (..)
import Task exposing (Task)

type Error =
  IdNotFound String | Unexpected String

type alias KeyboardEvent = HtmlEvent.KeyboardEvent
type alias MouseEvent = HtmlEvent.MouseEvent


focus : String -> Task Error ()
focus id =
  Task.sleep 100 `Task.andThen` \_ ->
  Task.mapError
    (always (IdNotFound id))
    (Native.HtmlUtil.focus id)


blur : String -> Task Error ()
blur id =
  Task.sleep 100 `Task.andThen` \_ ->
  Task.mapError
    (always (IdNotFound id))
    (Native.HtmlUtil.blur id)

locationHash : Signal String
locationHash =
  Native.HtmlUtil.locationHash

onMouseMove' : Address (Int, Int) -> Attribute
onMouseMove' address =
  onWithOptions
    "mousemove" { stopPropagation = True, preventDefault = True } decodeClientXY (Signal.message address)

onMouseEnter' : Address a -> a -> Attribute
onMouseEnter' address e =
  onWithOptions
    "mouseenter" { stopPropagation = True, preventDefault = True } decodeMousePosition (always <| Signal.message address e)

onMouseLeave' : Address a -> a -> Attribute
onMouseLeave' address e =
  onWithOptions
    "mouseleave" { stopPropagation = True, preventDefault = True } decodeMousePosition (always <| Signal.message address e)

onMouseUp' : Address a -> a -> Attribute
onMouseUp' address e =
  on "mouseup" decodeMousePosition (always <| Signal.message address e)

onMouseDown' : Address a -> a -> Attribute
onMouseDown' address e =
  onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } decodeMousePosition (always <| Signal.message address e)

onDblClick' : Address a -> a -> Attribute
onDblClick' address e =
  onWithOptions "dblclick" { stopPropagation = True, preventDefault = True } decodeMousePosition (always <| Signal.message address e)

onClick' : Address a -> a -> Attribute
onClick' address e =
  onWithOptions "click" { stopPropagation = True, preventDefault = True } decodeMousePosition (always <| Signal.message address e)

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

onContextMenu' : Address a -> a -> Attribute
onContextMenu' address e =
  onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } decodeMousePosition (always <| Signal.message address e)

onMouseWheel : Address a -> (Float -> a) -> Attribute
onMouseWheel address toAction =
  let
    handler v = Signal.message address (toAction v)
  in
    onWithOptions "wheel" { stopPropagation = True, preventDefault = True } decodeWheelEvent handler

mouseDownDefence : Address a -> a -> Attribute
mouseDownDefence address e =
  onMouseDown' address e

decodeClientXY : Decoder (Int, Int)
decodeClientXY =
  Json.Decode.map (\e -> (e.clientX, e.clientY)) decodeMousePosition

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

decodeWheelEvent : Json.Decode.Decoder Float
decodeWheelEvent =
    (oneOf
      [ at [ "deltaY" ] float
      , at [ "wheelDelta" ] float |> map (\v -> -v)
      ])
    `andThen` (\value -> if value /= 0 then succeed value else fail "Wheel of 0")

fileLoadButton : Address FileList -> List (String, String) -> String -> Html
fileLoadButton address styles text =
  Html.label
    [ Html.Attributes.style styles ]
    [ Html.text text
    , Html.input
        [ Html.Attributes.type' "file"
        , Html.Attributes.style [("display", "none")]
        , on
            "change"
            decodeFile
            (Signal.message address)
        ]
        []
    ]
