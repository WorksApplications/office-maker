module Util.ListUtil exposing (..)

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
getAt idx xs  =
  if idx < 0 then
    Nothing
  else
    List.head <| List.drop idx xs


setAt : Int -> a -> List a -> List a
setAt index value list =
  case list of
    head :: tail ->
      if index == 0 then
        value :: tail
      else
        head :: setAt (index - 1) value tail

    [] ->
      list
