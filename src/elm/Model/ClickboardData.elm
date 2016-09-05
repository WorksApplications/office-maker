module Model.ClickboardData exposing (..)

import Model.Prototype exposing (Prototype)
import String
import HtmlParser exposing (..)
import HtmlParser.Util exposing (..)

type alias StampCandidate =
  (Prototype, (Int, Int))


toObjectCandidates : Prototype -> (Int, Int) -> String -> List StampCandidate
toObjectCandidates prototype (left, top) s =
  let
    rows =
      if String.toLower s |> String.contains "</table>" then
        parseHtml s
      else
        parseString s

    rows' =
      List.indexedMap (\rowIndex row ->
        List.indexedMap (\colIndex maybeName ->
          Maybe.map
            (\name ->
              ( { prototype |
                  name = name
                }
              , calcPosition prototype (left, top) rowIndex colIndex
              )
            )
            maybeName
        ) row
      ) rows
  in
    List.concatMap (List.filterMap identity) rows'


parseString : String -> List (List (Maybe String))
parseString s =
  List.map (\s -> (List.map Just <| String.split "\t" s)) (String.split "\n" s)


parseHtml : String -> List (List (Maybe String))
parseHtml table =
  parse table
    |> getElementsByTagName "tr"
    |> mapElements
      (\_ _ innerTr ->
        innerTr
          |> mapElements
            (\_ attrs innerTd ->
              getValue "bgcolor" attrs `Maybe.andThen` \bgColor ->
                if bgColor /= "#FFFFFF" then
                  Just (textContent innerTd)
                else
                  Nothing
            )
      )


calcPosition : Prototype -> (Int, Int) -> Int -> Int -> (Int, Int)
calcPosition prototype (left, top) rowIndex colIndex =
  let
    (width, height) = prototype.size
    x = left + colIndex * width
    y = top + rowIndex * height
  in
    (x, y)
