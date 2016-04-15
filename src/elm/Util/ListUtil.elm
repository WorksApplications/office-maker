module Util.ListUtil where

import List.Extra as ListX

findBy : (a -> Bool) -> List a -> Maybe a
findBy f list =
  List.head (List.filter f list)

zipWithIndex : List a -> List (a, Int)
zipWithIndex =
  zipWithIndexFrom 0

zipWithIndexFrom : Int -> List a -> List (a, Int)
zipWithIndexFrom index list =
  case list of
    h :: t ->
      (h, index) :: zipWithIndexFrom (index + 1) t
    _ ->
      []

getAt : Int -> List a -> Maybe a
getAt index list = ListX.getAt list index
