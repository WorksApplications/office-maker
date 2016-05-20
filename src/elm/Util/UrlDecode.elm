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

urlOf : String -> URL
urlOf s =
  case split2 "&" s of
    Just (s1, s2) ->
      (String.split "/" s1, paramsOf s2)
    Nothing ->
      (String.split "/" s, Dict.empty)

paramsOf : String -> Dict String String
paramsOf s =
  let
    list = String.split "&" s

    keyValue indices =
      case indices of
        head :: tail ->
          Just (String.slice 0 head, String.dropLeft (head + 1))
        _ ->
          Nothing

    maybeKeyValues =
      List.map (split2 "=") list

    updateDict maybe dict =
      case maybe of
        Just (key, value) ->
          Dict.insert key value dict
        Nothing ->
          dict
  in
    List.foldl updateDict Dict.empty maybeKeyValues


split2 : String -> String -> Maybe (String, String)
split2 separator s =
  case String.indices separator s of
    head :: tail ->
      Just (String.slice 0 head s, String.dropLeft (head + 1) s)
    _ ->
      Nothing
