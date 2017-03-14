module Model.ClipboardData exposing (..)

import Model.Prototype exposing (Prototype)
import HtmlParser exposing (..)
import HtmlParser.Util exposing (..)

type alias PositionedPrototype =
  (Prototype, (Int, Int))


type alias Cell =
  { cols : Int
  , rows : Int
  , text : String
  }


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
        List.indexedMap (\colIndex maybeCell ->
          Maybe.map
            (\cell ->
              ( { prototype |
                  name = cell.text
                }
              , calcPosition prototype (left, top) rowIndex colIndex
              )
            )
            maybeCell
        ) row
      ) rows
  in
    List.concatMap (List.filterMap identity) rows_


parseString : String -> List (List (Maybe Cell))
parseString s =
  String.split "\n" s
    |> List.map
      (\s ->
         String.split "\t" s
           |> List.map (Cell 1 1 >> Just)
      )


parseHtml : String -> List (List (Maybe Cell))
parseHtml table =
  parse table
    |> getElementsByTagName "tr"
    |> mapElements
      (\_ _ innerTr ->
        innerTr
          |> mapElements
            (\_ attrs innerTd ->
              let
                cols = getIntValueWithDefault "colspan" attrs 1
                rows = getIntValueWithDefault "rowspan" attrs 1
                s = textContent innerTd
              in
                if String.trim s /= "" then
                  Just (Cell cols rows s)
                else
                  Nothing
            )
      )


getIntValueWithDefault : String -> Attributes -> Int -> Int
getIntValueWithDefault attrName attrs value =
  getValue attrName attrs
    |> Maybe.andThen (String.toInt >> Result.toMaybe)
    |> Maybe.withDefault value


calcPosition : Prototype -> (Int, Int) -> Int -> Int -> (Int, Int)
calcPosition prototype (left, top) rowIndex colIndex =
  ( left + colIndex * prototype.width
  , top + rowIndex * prototype.height
  )
