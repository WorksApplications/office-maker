module ListUtil where

findBy : (a -> Bool) -> List a -> Maybe a
findBy f list =
  List.head (List.filter f list)
