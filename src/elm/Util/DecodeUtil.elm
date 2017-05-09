module Util.DecodeUtil exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


tuple2 : (a -> b -> c) -> Decoder a -> Decoder b -> Decoder c
tuple2 f a b =
    D.map2 f (D.index 0 a) (D.index 1 b)



-- for Pipeline


optional_ : String -> Decoder a -> Decoder (Maybe a -> b) -> Decoder b
optional_ key decoder =
    Pipeline.custom (D.maybe (D.field key decoder))
