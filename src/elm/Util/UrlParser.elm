module Util.UrlParser exposing (..) -- where

import Dict exposing (Dict)
import String
import Util.StringUtil exposing (..)

type alias URL = (List String, Dict String String)

parse : String -> URL
parse s =
  case split2 "?" s of
    Just (s1, s2) ->
      (String.split "/" s1, parseParams s2)
    Nothing ->
      (String.split "/" s, Dict.empty)

parseParams : String -> Dict String String
parseParams s =
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
