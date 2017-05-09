module Util.IdGenerator exposing (..)

import Util.UUID as UUID


type Seed
    = Seed UUID.Seed


init : ( Int, Int ) -> Seed
init ( i1, i2 ) =
    Seed (UUID.init i1 i2)


new : Seed -> ( String, Seed )
new (Seed seed) =
    let
        ( newValue, newSeed ) =
            UUID.step seed
    in
        ( newValue, Seed newSeed )


zipWithNewIds : Seed -> List a -> ( List ( a, String ), Seed )
zipWithNewIds seed list =
    List.foldr
        (\a ( list, seed ) ->
            let
                ( newId, newSeed ) =
                    new seed
            in
                ( ( a, newId ) :: list, newSeed )
        )
        ( [], seed )
        list
