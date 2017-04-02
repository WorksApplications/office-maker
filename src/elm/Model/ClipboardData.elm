port module Model.ClipboardData exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)

import HtmlParser exposing (Attributes)
import HtmlParser.Util exposing (..)

import CoreType exposing (..)

import Model.Prototype exposing (Prototype)
import Model.Object exposing (Object)
import API.Serialization as Serialization
import Native.ClipboardData


type alias ClipboardData = Json


type alias PositionedPrototype =
  (Prototype, Position)


type alias Cell =
  { cols : Int
  , rows : Int
  , text : String
  }


getHtml : Json -> String
getHtml =
  Native.ClipboardData.getHtml


getText : Json -> String
getText =
  Native.ClipboardData.getText


decode : (String -> a) -> Decoder a
decode f =
  Decode.field "clipboardData" Decode.value
    |> Decode.map (\clipboardData -> (getHtml clipboardData, getText clipboardData))
    |> Decode.andThen (\(html, text) ->
      if String.trim html /= "" then
        Decode.succeed html
      else if String.trim text /= "" then
        Decode.succeed text
      else
        Decode.fail "no data"
      )
    |> Decode.map f


port copy : String -> Cmd msg


copyObjects : List Object -> Cmd msg
copyObjects objects =
  Encode.list (List.map Serialization.encodeObject objects)
    |> Encode.encode 0
    |> copy


toObjects : String -> List Object
toObjects s =
  Decode.decodeString (Decode.list Serialization.decodeObject) s
    |> Result.withDefault []


toObjectCandidates : Prototype -> Position -> String -> List PositionedPrototype
toObjectCandidates prototype pos s =
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
              , calcPosition prototype pos rowIndex colIndex
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
  HtmlParser.parse table
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


calcPosition : Prototype -> Position -> Int -> Int -> Position
calcPosition prototype pos rowIndex colIndex =
  Position
    (pos.x + colIndex * prototype.width)
    (pos.y + rowIndex * prototype.height)
