module Util.IdGenerator where

import Uuid
import Random.PCG exposing (initialSeed2, generate)

type alias Seed' = Random.PCG.Seed

type Seed = Seed Seed'

init : (Int, Int) -> Seed
init randomSeed = Seed ((uncurry initialSeed2) randomSeed)

new : Seed -> (String, Seed)
new (Seed seed) =
  let
    (newUuid, newSeed) = generate Uuid.uuidGenerator seed
  in
    (Uuid.toString newUuid, Seed newSeed)

zipWithNewIds : Seed -> List a -> (List (a, String), Seed)
zipWithNewIds seed list =
  List.foldr (\a (list, seed) ->
    let
      (newId, newSeed) = new seed
    in
      ((a, newId) :: list, newSeed)
  ) ([], seed) list
