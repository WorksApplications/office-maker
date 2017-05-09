module Model.ClipboardData exposing (..)

import Dict exposing (Dict)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import HtmlParser exposing (Attributes)
import HtmlParser.Util exposing (..)
import CoreType exposing (..)
import Model.Prototype exposing (Prototype)
import Model.Object exposing (Object)
import Model.ObjectsOperation as ObjectsOperation
import API.Serialization as Serialization
import Native.ClipboardData


type alias ClipboardData =
    Json


type alias PositionedPrototype =
    ( Prototype, Position )


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
        |> Decode.map (\clipboardData -> ( getHtml clipboardData, getText clipboardData ))
        |> Decode.andThen
            (\( html, text ) ->
                if String.trim html /= "" then
                    Decode.succeed html
                else if String.trim text /= "" then
                    Decode.succeed text
                else
                    Decode.fail "no data"
            )
        |> Decode.map f


fromObjects : List Object -> String
fromObjects objects =
    Encode.list (List.map Serialization.encodeObject objects)
        |> Encode.encode 0


toObjects : String -> List Object
toObjects s =
    Decode.decodeString (Decode.list Serialization.decodeObject) s
        |> Result.withDefault []


toObjectCandidates : Int -> Size -> Prototype -> Position -> String -> List PositionedPrototype
toObjectCandidates gridSize cellSizePerDesk prototype pos s =
    let
        rows =
            if String.toLower s |> String.contains "</table>" then
                parseHtml s
            else
                parseString s
    in
        rows
            |> List.foldl (consRow gridSize cellSizePerDesk prototype pos) ( Dict.empty, 0, [] )
            |> (\( _, _, result ) -> result)
            |> List.reverse
            |> List.concatMap identity


consRow : Int -> Size -> Prototype -> Position -> List Cell -> ( Dict ( Int, Int ) Int, Int, List (List PositionedPrototype) ) -> ( Dict ( Int, Int ) Int, Int, List (List PositionedPrototype) )
consRow gridSize cellSizePerDesk prototype pos row ( skipCells, rowIndex, resultRows ) =
    row
        |> List.foldl (consCell gridSize cellSizePerDesk prototype pos rowIndex) ( skipCells, 0, [] )
        |> (\( skipCells, _, result ) ->
                result
                    |> List.reverse
                    |> flip (::) resultRows
                    |> (,,) skipCells (rowIndex + 1)
           )


consCell : Int -> Size -> Prototype -> Position -> Int -> Cell -> ( Dict ( Int, Int ) Int, Int, List PositionedPrototype ) -> ( Dict ( Int, Int ) Int, Int, List PositionedPrototype )
consCell gridSize cellSizePerDesk prototype pos rowIndex cell ( skipCells, colIndex, resultCols ) =
    skipCells
        |> Dict.get ( rowIndex, colIndex )
        |> Maybe.map
            (\amount ->
                ( skipCells, colIndex + amount, resultCols )
            )
        |> Maybe.withDefault
            (let
                newSkipCells =
                    updateSkipCells rowIndex colIndex cell skipCells
             in
                if String.trim cell.text /= "" then
                    let
                        protoWithPos =
                            ( { prototype
                                | name = cell.text
                                , width = prototype.width * cell.cols // cellSizePerDesk.width |> ObjectsOperation.fitToGrid gridSize
                                , height = prototype.height * cell.rows // cellSizePerDesk.height |> ObjectsOperation.fitToGrid gridSize
                              }
                            , calcPosition gridSize cellSizePerDesk prototype pos rowIndex colIndex
                            )
                    in
                        ( newSkipCells, colIndex + cell.cols, protoWithPos :: resultCols )
                else
                    ( newSkipCells, colIndex + 1, resultCols )
            )


updateSkipCells : Int -> Int -> Cell -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
updateSkipCells rowIndex colIndex cell skipCells =
    List.range 0 (cell.rows - 1)
        |> List.foldl
            (\row dict ->
                Dict.insert ( rowIndex + row, colIndex ) cell.cols dict
            )
            skipCells


parseString : String -> List (List Cell)
parseString s =
    String.split "\n" s
        |> List.map
            (\s ->
                String.split "\t" s
                    |> List.map (Cell 1 1)
            )


parseHtml : String -> List (List Cell)
parseHtml table =
    HtmlParser.parse table
        |> getElementsByTagName "tr"
        |> mapElements
            (\_ _ innerTr ->
                innerTr
                    |> mapElements
                        (\_ attrs innerTd ->
                            let
                                cols =
                                    getIntValueWithDefault "colspan" attrs 1

                                rows =
                                    getIntValueWithDefault "rowspan" attrs 1

                                s =
                                    textContent innerTd
                            in
                                Cell cols rows s
                        )
            )


getIntValueWithDefault : String -> Attributes -> Int -> Int
getIntValueWithDefault attrName attrs value =
    getValue attrName attrs
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.withDefault value


calcPosition : Int -> Size -> Prototype -> Position -> Int -> Int -> Position
calcPosition gridSize cellSizePerDesk prototype pos rowIndex colIndex =
    Position
        (pos.x + colIndex * prototype.width // cellSizePerDesk.width)
        (pos.y + rowIndex * prototype.height // cellSizePerDesk.height)
        |> ObjectsOperation.fitPositionToGrid gridSize
