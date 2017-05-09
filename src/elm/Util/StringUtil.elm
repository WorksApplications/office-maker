module Util.StringUtil exposing (..)


split2 : String -> String -> Maybe ( String, String )
split2 separator s =
    case String.indices separator s of
        head :: tail ->
            Just ( String.slice 0 head s, String.dropLeft (head + 1) s )

        _ ->
            Nothing
