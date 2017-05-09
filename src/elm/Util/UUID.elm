module Util.UUID exposing (Seed, init, step)

-- TODO maybe this implementation is incorrect. Use library instead.

import Random


type Seed
    = Seed Random.Seed Random.Seed


r1 : Random.Generator String
r1 =
    Random.map toHex <| Random.int 0 15


r2 : Random.Generator String
r2 =
    Random.map toHex <| Random.int 8 11


toHex : Int -> String
toHex i =
    if i == 0 then
        "0"
    else if i == 1 then
        "1"
    else if i == 2 then
        "2"
    else if i == 3 then
        "3"
    else if i == 4 then
        "4"
    else if i == 5 then
        "5"
    else if i == 6 then
        "6"
    else if i == 7 then
        "7"
    else if i == 8 then
        "8"
    else if i == 9 then
        "9"
    else if i == 10 then
        "a"
    else if i == 11 then
        "b"
    else if i == 12 then
        "c"
    else if i == 13 then
        "d"
    else if i == 14 then
        "e"
    else if i == 15 then
        "f"
    else
        Debug.crash ""


f : Char -> ( String, Random.Seed, Random.Seed ) -> ( String, Random.Seed, Random.Seed )
f c ( s, s1, s2 ) =
    if c == 'x' then
        let
            ( c_, s1_ ) =
                Random.step r1 s1
        in
            ( s ++ c_, s1_, s2 )
    else if c == 'y' then
        let
            ( c_, s2_ ) =
                Random.step r2 s2
        in
            ( s ++ c_, s1, s2_ )
    else
        ( s ++ String.fromChar c, s1, s2 )


init : Int -> Int -> Seed
init i1 i2 =
    Seed (Random.initialSeed i1) (Random.initialSeed i2)


step : Seed -> ( String, Seed )
step (Seed s1 s2) =
    let
        ( s, s1_, s2_ ) =
            List.foldl f ( "", s1, s2 ) (String.toList "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx")
    in
        ( s, Seed s1_ s2_ )
