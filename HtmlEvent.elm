module HtmlEvent where

import Json.Decode exposing (..)

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
  , shiftKey : Bool
  }

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
  object3
    (\keyCode ctrlKey shiftKey ->
      { keyCode = keyCode
      , ctrlKey = ctrlKey
      , shiftKey = shiftKey })
    ("keyCode" := int)
    ("ctrlKey" := bool)
    ("shiftKey" := bool)
