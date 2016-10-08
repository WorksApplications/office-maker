module Util.HtmlUtil exposing (..)

import Html exposing (Html, Attribute, text)
import Html.App
import Html.Attributes
import Html.Events exposing (on, onWithOptions)
import Json.Decode as Decode exposing (..)
import Util.File exposing (..)


type Error =
  IdNotFound String | Unexpected String


-- TODO maybe pageX, pageY is better
decodeClientXY : Decoder (Int, Int)
decodeClientXY =
  object2 (,)
    ("clientX" := int)
    ("clientY" := int)


decodeClientXYandButton : Decoder (Int, Int, Bool)
decodeClientXYandButton =
  object3 (\x y button ->
    (x, y, button > 0)
    )
    ("clientX" := int)
    ("clientY" := int)
    ("button" := int)


decodeRightButton : Decoder Bool
decodeRightButton =
  object1 (\button -> button > 0)
    ("button" := int)


decodeKeyCode : Decoder Int
decodeKeyCode =
  at [ "keyCode" ] int


targetSelectionStart : Decoder Int
targetSelectionStart =
  Decode.at ["target", "selectionStart"] Decode.int


decodeKeyCodeAndSelectionStart : Decoder (Int, Int)
decodeKeyCodeAndSelectionStart =
  Decode.object2 (,)
    ("keyCode" := int)
    ("target" := Decode.object1 identity ("selectionStart" := int))


onSubmit' : a -> Attribute a
onSubmit' e =
  onWithOptions
    "onsubmit" { stopPropagation = True, preventDefault = False } (Decode.succeed e)


onMouseMove' : ((Int, Int) -> a) -> Attribute a
onMouseMove' f =
  onWithOptions
    "mousemove" { stopPropagation = True, preventDefault = True } (Decode.map f decodeClientXY)


onMouseEnter' : a -> Attribute a
onMouseEnter' e =
  onWithOptions
    "mouseenter" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onMouseLeave' : a -> Attribute a
onMouseLeave' e =
  onWithOptions
    "mouseleave" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


-- onMouseUp' : a -> Attribute a
-- onMouseUp' e =
--   on "mouseup" (Decode.succeed e)


onMouseDown' : a -> Attribute a
onMouseDown' e =
  onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onDblClick' : a -> Attribute a
onDblClick' e =
  onWithOptions "dblclick" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onClick' : a -> Attribute a
onClick' e =
  onWithOptions "click" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onInput : (String -> a) -> Attribute a
onInput f =
  on "input" (Decode.map f Html.Events.targetValue)


onInput' : (String -> a) -> Attribute a
onInput' f =
  onWithOptions "input" { stopPropagation = True, preventDefault = True } (Decode.map f Html.Events.targetValue)


onChange' : (String -> a) -> Attribute a
onChange' f =
  onWithOptions "change" { stopPropagation = True, preventDefault = True } (Decode.map f Html.Events.targetValue)

-- onKeyUp' : Address KeyboardEvent -> Attribute
-- onKeyUp' address =
--   on "keyup" decodeKeyboardEvent (Signal.message address)

onKeyDown' : (Int -> a) -> Attribute a
onKeyDown' f =
  onWithOptions "keydown" { stopPropagation = True, preventDefault = True } (Decode.map f decodeKeyCode)


onKeyDown'' : (Int -> a) -> Attribute a
onKeyDown'' f =
  on "keydown" (Decode.map f decodeKeyCode)


onContextMenu' : a -> Attribute a
onContextMenu' e =
  onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onMouseWheel : (Float -> a) -> Attribute a
onMouseWheel toMsg =
  onWithOptions "wheel" { stopPropagation = True, preventDefault = True } (Decode.map toMsg decodeWheelEvent)


mouseDownDefence : a -> Attribute a
mouseDownDefence e =
  onMouseDown' e


decodeWheelEvent : Decoder Float
decodeWheelEvent =
    (oneOf
      [ at [ "deltaY" ] float
      , at [ "wheelDelta" ] float |> map (\v -> -v)
      ])
    `andThen` (\value -> if value /= 0 then succeed value else fail "Wheel of 0")


form' : a -> List (Attribute a) -> List (Html a) -> Html a
form' msg attribtes children =
  Html.form
    ([ Html.Attributes.action "javascript:void(0);"
    , Html.Attributes.method "POST"
    , Html.Events.onSubmit msg
    ] ++ attribtes)
    children


fileLoadButton : (FileList -> msg) -> List (String, String) -> String -> Html msg
fileLoadButton tagger styles text =
  Html.label
    [ Html.Attributes.style styles ]
    [ Html.text text
    , Html.input
        [ Html.Attributes.type' "file"
        , Html.Attributes.style [("display", "none")]
        , on "change" decodeFile
        ]
        [] |> Html.App.map tagger
    ]
