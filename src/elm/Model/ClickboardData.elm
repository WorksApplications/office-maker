module Model.ClickboardData exposing (..)

import Model.Prototype exposing (Prototype)
import String

type alias StampCandidate =
  (Prototype, (Int, Int))


toObjectCandidates : Prototype -> (Int, Int) -> String -> List StampCandidate
toObjectCandidates prototype (left, top) s =
  let
    rows =
      parse s

    rows' =
      List.indexedMap (\rowIndex row ->
        List.indexedMap (\colIndex name ->
          if String.trim name == "" then
            Nothing
          else
            Just
              ( { prototype |
                  name = name
                }
              , calcPosition prototype (left, top) rowIndex colIndex
              )
        ) row
      ) rows
  in
    List.concatMap (List.filterMap identity) rows'


parse : String -> List (List String)
parse s =
  List.map (\s -> String.split "\t" s) (String.split "\n" s)


calcPosition : Prototype -> (Int, Int) -> Int -> Int -> (Int, Int)
calcPosition prototype (left, top) rowIndex colIndex =
  let
    (width, height) = prototype.size
    x = left + colIndex * width
    y = top + rowIndex * height
  in
    (x, y)
