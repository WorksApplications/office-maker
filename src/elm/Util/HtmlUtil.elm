module Util.HtmlUtil exposing (..)

import Mouse exposing (Position)
import Html exposing (Html, Attribute, text)
import Html.Attributes
import Html.Events exposing (on, onWithOptions, targetValue, defaultOptions)
import Json.Decode as Decode exposing (..)
import Util.File exposing (..)
import Native.HtmlUtil


type Error
    = IdNotFound String
    | Unexpected String


decodeRightButton : Decoder Bool
decodeRightButton =
    Decode.map (\button -> button > 0)
        (field "button" int)


decodeKeyCode : Decoder Int
decodeKeyCode =
    at [ "keyCode" ] int


targetSelectionStart : Decoder Int
targetSelectionStart =
    Decode.at [ "target", "selectionStart" ] Decode.int


decodeKeyCodeAndSelectionStart : Decoder ( Int, Int )
decodeKeyCodeAndSelectionStart =
    Decode.map2 (,)
        (field "keyCode" int)
        (field "target" (field "selectionStart" int))


decodeTargetValueAndSelectionStart : Decoder ( String, Int )
decodeTargetValueAndSelectionStart =
    Decode.map2 (,)
        targetValue
        (field "target" (field "selectionStart" int))


onMouseEnter_ : a -> Attribute a
onMouseEnter_ e =
    onWithOptions
        "mouseenter"
        { stopPropagation = True, preventDefault = True }
        (Decode.succeed e)


onMouseLeave_ : a -> Attribute a
onMouseLeave_ e =
    onWithOptions
        "mouseleave"
        { stopPropagation = True, preventDefault = True }
        (Decode.succeed e)


onMouseDown_ : a -> Attribute a
onMouseDown_ e =
    onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onDblClick_ : a -> Attribute a
onDblClick_ e =
    onWithOptions "dblclick" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onClick_ : a -> Attribute a
onClick_ e =
    onWithOptions "click" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onInput : (String -> a) -> Attribute a
onInput f =
    on "input" (Decode.map f Html.Events.targetValue)


onChange_ : (String -> a) -> Attribute a
onChange_ f =
    onWithOptions "change" { stopPropagation = True, preventDefault = True } (Decode.map f Html.Events.targetValue)



-- onKeyUp_ : Address KeyboardEvent -> Attribute
-- onKeyUp_ address =
--   on "keyup" decodeKeyboardEvent (Signal.message address)


onKeyDown_ : (Int -> a) -> Attribute a
onKeyDown_ f =
    onWithOptions "keydown" { stopPropagation = True, preventDefault = True } (Decode.map f decodeKeyCode)


onKeyDown__ : (Int -> a) -> Attribute a
onKeyDown__ f =
    on "keydown" (Decode.map f decodeKeyCode)


onContextMenu_ : a -> Attribute a
onContextMenu_ e =
    onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } (Decode.succeed e)


onMouseWheel : (Float -> Position -> a) -> Attribute a
onMouseWheel toMsg =
    onWithOptions "wheel"
        { stopPropagation = True, preventDefault = True }
        (Decode.map (\( value, pos ) -> toMsg value pos) decodeWheelEvent)


decodeWheelEvent : Decoder ( Float, Position )
decodeWheelEvent =
    (oneOf
        [ at [ "deltaY" ] float
        , at [ "wheelDelta" ] float |> map (\v -> -v)
        ]
    )
        |> andThen
            (\value ->
                if value /= 0 then
                    succeed value
                else
                    fail "Wheel of 0"
            )
        |> andThen
            (\value ->
                Mouse.position
                    |> map
                        (\position -> ( value, position ))
            )


form_ : a -> List (Attribute a) -> List (Html a) -> Html a
form_ msg attribtes children =
    Html.form
        ([ Html.Attributes.action "javascript:void(0);"
         , Html.Attributes.method "POST"
         , Html.Events.onSubmit msg
         ]
            ++ attribtes
        )
        children


fileLoadButton : (FileList -> msg) -> List ( String, String ) -> String -> String -> Html msg
fileLoadButton tagger styles accept text =
    Html.label
        [ Html.Attributes.style styles ]
        [ Html.text text
        , Html.input
            [ Html.Attributes.type_ "file"
            , Html.Attributes.accept accept
            , Html.Attributes.style [ ( "display", "none" ) ]
            , on "change" decodeFile
            ]
            []
            |> Html.map tagger
        ]



-- NAVIGATION
{-
   https://github.com/elm-lang/navigation/issues/13#issuecomment-272996582
-}


onPreventDefaultClick : msg -> Attribute msg
onPreventDefaultClick message =
    onWithOptions "click"
        { defaultOptions | preventDefault = True }
        (preventDefault2
            |> Decode.andThen (maybePreventDefault message)
        )


preventDefault2 : Decoder Bool
preventDefault2 =
    Decode.map2
        invertedOr
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)


maybePreventDefault : msg -> Bool -> Decoder msg
maybePreventDefault msg preventDefault =
    if preventDefault then
        Decode.succeed msg
    else
        Decode.fail "Normal link"


invertedOr : Bool -> Bool -> Bool
invertedOr x y =
    not (x || y)


measureText : String -> Float -> String -> Float
measureText =
    Native.HtmlUtil.measureText
