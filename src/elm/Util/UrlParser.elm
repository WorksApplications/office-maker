module Util.UrlParser exposing (..)

import Dict exposing (Dict)
import Util.StringUtil exposing (..)
import Http


type alias URL =
    ( List String, Dict String String )


parseSearch : String -> Dict String String
parseSearch s_ =
    let
        s =
            String.dropLeft 1 s_

        -- drop "?"
        list =
            String.split "&" s

        keyValue indices =
            case indices of
                head :: tail ->
                    Just ( String.slice 0 head, String.dropLeft (head + 1) )

                _ ->
                    Nothing

        maybeKeyValues =
            List.map (split2 "=") list

        updateDict maybe dict =
            case maybe of
                Just ( key, value ) ->
                    Dict.insert key (Http.decodeUri value |> Maybe.withDefault "") dict

                Nothing ->
                    dict
    in
        List.foldl updateDict Dict.empty maybeKeyValues
