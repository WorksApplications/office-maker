module Model.ClipboardData exposing (..)

import Model.Prototype exposing (Prototype)
import HtmlParser exposing (..)
import HtmlParser.Util exposing (..)

type alias PositionedPrototype =
  (Prototype, (Int, Int))


toObjectCandidates : Prototype -> (Int, Int) -> String -> List PositionedPrototype
toObjectCandidates prototype (left, top) s =
  let
    rows =
      if String.toLower s |> String.contains "</table>" then
        parseHtml s
      else
        parseString s

    rows_ =
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
    List.concatMap (List.filterMap identity) rows_


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
              getValue "bgcolor" attrs
                |> Maybe.andThen (\bgColor ->
                  if bgColor /= "#FFFFFF" then
                    Just (textContent innerTd)
                  else
                    Nothing
                )
            )
      )


calcPosition : Prototype -> (Int, Int) -> Int -> Int -> (Int, Int)
calcPosition prototype (left, top) rowIndex colIndex =
  ( left + colIndex * prototype.width
  , top + rowIndex * prototype.height
  )
