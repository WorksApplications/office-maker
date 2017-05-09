module Page.Map.KeyOperation exposing (..)

import Char
import Json.Decode as Decode exposing (Decoder)
import CoreType exposing (..)
import Page.Map.Msg exposing (Msg(..))


c : Int
c =
    Char.toCode 'C'


x : Int
x =
    Char.toCode 'X'


y : Int
y =
    Char.toCode 'Y'


z : Int
z =
    Char.toCode 'Z'


left : Int
left =
    37


up : Int
up =
    38


right : Int
right =
    39


down : Int
down =
    40


backSpace : Int
backSpace =
    8


delete : Int
delete =
    46


tab : Int
tab =
    9


ctrl : Int
ctrl =
    17


isCommand : Int -> Bool
isCommand keyCode =
    (keyCode == 224)
        || (keyCode == 17)
        || (keyCode == 91)
        || (keyCode == 93)


isCtrlOrCommand : Int -> Bool
isCtrlOrCommand keyCode =
    keyCode == ctrl || isCommand keyCode


decodeOperation : Decoder Msg
decodeOperation =
    decodeOperationHelp toMsg


toMsg : Bool -> Bool -> Int -> Maybe Msg
toMsg ctrl shift keyCode =
    if ctrl && keyCode == c then
        Just Copy
    else if ctrl && keyCode == x then
        Just Cut
    else if ctrl && keyCode == y then
        Just Redo
    else if ctrl && keyCode == z then
        Just Undo
    else if keyCode == delete || keyCode == backSpace then
        Just Delete
    else if shift && keyCode == up then
        Just (ExpandOrShrinkToward Up)
    else if shift && keyCode == down then
        Just (ExpandOrShrinkToward Down)
    else if shift && keyCode == left then
        Just (ExpandOrShrinkToward Left)
    else if shift && keyCode == right then
        Just (ExpandOrShrinkToward Right)
    else if keyCode == up then
        Just (MoveSelecedObjectsToward Up)
    else if keyCode == down then
        Just (MoveSelecedObjectsToward Down)
    else if keyCode == left then
        Just (MoveSelecedObjectsToward Left)
    else if keyCode == right then
        Just (MoveSelecedObjectsToward Right)
    else if keyCode == tab then
        Just ShiftSelectionByTab
    else
        Nothing


decodeOperationHelp : (Bool -> Bool -> Int -> Maybe msg) -> Decoder msg
decodeOperationHelp toMsg =
    Decode.map3 toMsg
        decodeCtrlOrCommand
        decodeShift
        decodeKeyCode
        |> Decode.andThen
            (\maybeMsg ->
                maybeMsg
                    |> Maybe.map Decode.succeed
                    |> Maybe.withDefault (Decode.fail "")
            )


decodeShift : Decoder Bool
decodeShift =
    Decode.field "shiftKey" Decode.bool


decodeCtrlOrCommand : Decoder Bool
decodeCtrlOrCommand =
    Decode.map2 (||)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)


decodeKeyCode : Decoder Int
decodeKeyCode =
    Decode.field "keyCode" Decode.int
