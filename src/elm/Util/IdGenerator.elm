module Util.IdGenerator exposing (..) -- where

type Seed = Seed Int

init : (Int, Int) -> Seed
init randomSeed = Seed 0

new : Seed -> (String, Seed)
new (Seed seed) =
  (toString seed, Seed (seed + 1))

zipWithNewIds : Seed -> List a -> (List (a, String), Seed)
zipWithNewIds seed list =
  List.foldr (\a (list, seed) ->
    let
      (newId, newSeed) = new seed
    in
      ((a, newId) :: list, newSeed)
  ) ([], seed) list
