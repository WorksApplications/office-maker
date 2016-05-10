module Util.DecodeUtil exposing (..) -- where

import Json.Decode exposing (Decoder, maybe, oneOf, succeed, (:=))

(?=) : String -> (Decoder a) -> (Decoder (Maybe a))
(?=) key decorder =
  maybe (key := decorder)
