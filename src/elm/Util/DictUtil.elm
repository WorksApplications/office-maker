module Util.DictUtil exposing (..)

import Dict exposing (Dict)


addAll : (a -> comparable) -> List a -> Dict comparable a -> Dict comparable a
addAll toKey list dict =
    List.foldl (\a d -> Dict.update (toKey a) (always (Just a)) d) dict list
