module Util.DecodeUtil exposing (..) -- where

import Json.Decode exposing (Decoder, maybe, oneOf, succeed, (:=))
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

(?=) : String -> (Decoder a) -> (Decoder (Maybe a))
(?=) key decorder =
  maybe (key := decorder)

-- for Pipeline


optional' : String -> Decoder a -> Decoder (Maybe a -> b) -> Decoder b
optional' field decoder =
    custom (field ?= decoder)
