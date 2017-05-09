module CoreType exposing (..)

import Json.Encode


type alias Position =
    { x : Int
    , y : Int
    }


type alias PositionFloat =
    { x : Float
    , y : Float
    }


type alias Size =
    { width : Int
    , height : Int
    }


type alias Id =
    String


type alias ObjectId =
    Id


type alias PersonId =
    Id


type alias FloorId =
    Id


type alias Json =
    Json.Encode.Value



-- DIRECTION


type Direction
    = Up
    | Left
    | Right
    | Down


opposite : Direction -> Direction
opposite direction =
    case direction of
        Left ->
            Right

        Right ->
            Left

        Up ->
            Down

        Down ->
            Up


shiftTowards : Direction -> number -> ( number, number )
shiftTowards direction amount =
    case direction of
        Up ->
            ( 0, -amount )

        Down ->
            ( 0, amount )

        Right ->
            ( amount, 0 )

        Left ->
            ( -amount, 0 )
