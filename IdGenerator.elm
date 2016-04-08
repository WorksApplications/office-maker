module IdGenerator where

type Seed = Seed Int
type alias Id = String

init : Seed
init = Seed 0

new : Seed -> (Id, Seed)
new (Seed i) = (toString i, Seed (i + 1))

zipWithNewIds : Seed -> List a -> (List (a, Id), Seed)
zipWithNewIds seed list =
  List.foldr (\a (list, seed) ->
    let
      (newId, newSeed) = new seed
    in
      ((a, newId) :: list, newSeed)
  ) ([], seed) list
