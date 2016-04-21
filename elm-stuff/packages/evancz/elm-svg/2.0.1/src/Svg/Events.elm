module Svg.Events
    ( onBegin, onEnd, onRepeat
    , onAbort, onError, onResize, onScroll, onLoad, onUnload, onZoom
    , onActivate, onClick, onFocusIn, onFocusOut, onMouseDown, onMouseMove
    , onMouseOut, onMouseOver, onMouseUp
    ) where

{-|

# Animation event attributes
@docs onBegin, onEnd, onRepeat

# Document event attributes
@docs onAbort, onError, onResize, onScroll, onLoad, onUnload, onZoom

# Graphical event attributes
@docs onActivate, onClick, onFocusIn, onFocusOut, onMouseDown, onMouseMove,
  onMouseOut, onMouseOver, onMouseUp

-}

import Svg exposing (Attribute)
import Json.Decode as Json
import Signal
import VirtualDom



{-|-}
on : String -> Json.Decoder a -> (a -> Signal.Message) -> Attribute
on =
  VirtualDom.on


messageOn : String -> Signal.Message -> Attribute
messageOn name msg =
  on name Json.value (always msg)


-- Animation event attributes


{-|-}
onBegin : Signal.Message -> Attribute
onBegin =
  messageOn "begin"


{-|-}
onEnd : Signal.Message -> Attribute
onEnd =
  messageOn "end"


{-|-}
onRepeat : Signal.Message -> Attribute
onRepeat =
  messageOn "repeat"


-- Document event attributes


{-|-}
onAbort : Signal.Message -> Attribute
onAbort =
  messageOn "abort"


{-|-}
onError : Signal.Message -> Attribute
onError =
  messageOn "error"


{-|-}
onResize : Signal.Message -> Attribute
onResize =
  messageOn "resize"


{-|-}
onScroll : Signal.Message -> Attribute
onScroll =
  messageOn "scroll"


{-|-}
onLoad : Signal.Message -> Attribute
onLoad =
  messageOn "load"


{-|-}
onUnload : Signal.Message -> Attribute
onUnload =
  messageOn "unload"


{-|-}
onZoom : Signal.Message -> Attribute
onZoom =
  messageOn "zoom"


-- Graphical event attributes


{-|-}
onActivate : Signal.Message -> Attribute
onActivate =
  messageOn "activate"


{-|-}
onClick : Signal.Message -> Attribute
onClick =
  messageOn "click"


{-|-}
onFocusIn : Signal.Message -> Attribute
onFocusIn =
  messageOn "focusin"


{-|-}
onFocusOut : Signal.Message -> Attribute
onFocusOut =
  messageOn "focusout"


{-|-}
onMouseDown : Signal.Message -> Attribute
onMouseDown =
  messageOn "mousedown"


{-|-}
onMouseMove : Signal.Message -> Attribute
onMouseMove =
  messageOn "mousemove"


{-|-}
onMouseOut : Signal.Message -> Attribute
onMouseOut =
  messageOn "mouseout"


{-|-}
onMouseOver : Signal.Message -> Attribute
onMouseOver =
  messageOn "mouseover"


{-|-}
onMouseUp : Signal.Message -> Attribute
onMouseUp =
  messageOn "mouseup"
