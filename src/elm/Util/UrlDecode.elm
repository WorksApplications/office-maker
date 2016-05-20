module Util.UrlDecode exposing (..) -- where

import Dict exposing (Dict)
import String

type alias URL = (List String, Dict String String)

type Decoder a =
    Succeed a
  | Fail String
  | Field Requrement String (ParamDecoder a)
  | Decoder (String -> Result String a)
  -- | AndThen (Decoder z) (z -> a)

type Requrement =
  Required | Optional

type alias ParamDecoder a =
  (String -> Result String a)


int : ParamDecoder Int
int = \s ->
  case String.toInt s of
    Ok i -> Ok i
    _ -> Err (s ++ " is not Int.")

string : ParamDecoder String
string s = Ok s

field : Requrement -> String -> (ParamDecoder a) -> Decoder a
field = Field

custom : Decoder a -> Decoder (a -> b) -> Decoder b
custom delegated decoder =
  andThen decoder (\wrappedFn -> map wrappedFn delegated)

required : String -> ParamDecoder a -> Decoder (a -> b) -> Decoder b
required key paramDecoder decoder =
  custom (field Required key paramDecoder) decoder

optional : String -> ParamDecoder a -> Decoder (a -> b) -> Decoder b
optional key paramDecoder decoder =
  custom (field Optional key paramDecoder) decoder

decodeString : Decoder a -> String -> Result String a
decodeString decoder s =
  case decoder of
    Decoder f -> f s
    _ -> Debug.crash "TODO"

succeed : a -> Decoder a
succeed = Succeed

fail : String -> Decoder a
fail = Fail

map : (a -> b) -> Decoder a -> Decoder b
map g decoder =
  let
    f s =
      case decodeString decoder s of
        Ok a -> Ok (g a)
        Err s -> Err s
  in
    Decoder f

andThen : Decoder a -> (a -> Decoder b) -> Decoder b
andThen decoder g =
  let
    f s =
      case decodeString decoder s of
        Ok a -> decodeString (g a) s
        Err s -> Err s
  in
    Decoder f

decode : a -> Decoder a
decode =
  succeed
