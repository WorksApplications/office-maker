module Util.DecodeUtil exposing (..)

import Json.Decode exposing (Decoder, maybe, succeed, (:=), int, tuple2)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

(?=) : String -> (Decoder a) -> (Decoder (Maybe a))
(?=) key decorder =
  maybe (key := decorder)


intSize : Decoder (Int, Int)
intSize = tuple2 (,) int int


-- for Pipeline


optional' : String -> Decoder a -> Decoder (Maybe a -> b) -> Decoder b
optional' field decoder =
    custom (field ?= decoder)
