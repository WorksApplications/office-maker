module Model.Floor exposing (..)

import String
import Regex
import Date exposing (Date)
import Model.Object as Object exposing (..)
import Model.ObjectsOperation as ObjectsOperation exposing (..)

type alias Id = String


type alias FloorBase =
  { id : Id
  , version : Int
  , name : String
  , ord : Int
  , public : Bool
  }


type alias Detailed a =
  { a |
    width : Int
  , height : Int
  , realSize : Maybe (Int, Int)
  , image : Maybe String
  , update : Maybe { by : Id, at : Date }
  , objects: List Object
  }


type alias Floor = Detailed FloorBase


init : Id -> Floor
init id =
  { id = id
  , version = 0
  , name = "New Floor"
  , ord = 0
  , objects = []
  , width = 800
  , height = 600
  , realSize = Nothing
  , image = Nothing
  , public = False
  , update = Nothing
  }


empty : Floor
empty = init ""


baseOf : Floor -> FloorBase
baseOf { id, version, name, ord, public } =
  FloorBase id version name ord public


initWithOrder : Id -> Int -> Floor
initWithOrder id ord =
  let
    floor = init id
  in
    { floor |
      ord = ord
    }


copy : Id -> Floor -> Floor
copy id floor =
  { floor |
    id = id
  , version = 0
  , name = "Copy of " ++ floor.name
  , public = False
  , update = Nothing
  }


move : List Id -> Int -> (Int, Int) -> Floor -> Floor
move ids gridSize (dx, dy) floor =
  setObjects
    (moveObjects gridSize (dx, dy) ids (objects floor))
    floor


paste : List (Object, Id) -> (Int, Int) -> Floor -> Floor
paste copiedWithNewIds (baseX, baseY) floor =
  setObjects
    (floor.objects ++ (pasteObjects (baseX, baseY) copiedWithNewIds (objects floor)))
    floor


delete : List Id -> Floor -> Floor
delete ids floor =
  setObjects
    (List.filter (\object -> not (List.member (idOf object) ids)) (objects floor))
    floor


rotateObject : Id -> Floor -> Floor
rotateObject id floor =
  setObjects (partiallyChange Object.rotate [id] (objects floor)) floor


changeId : Id -> Floor -> Floor
changeId id floor =
  { floor | id = id }


changeObjectColor : List Id -> String -> Floor -> Floor
changeObjectColor ids bgColor floor =
  let
    newObjects =
      partiallyChange (changeBackgroundColor bgColor) ids (objects floor)
  in
    setObjects newObjects floor


changeObjectBackgroundColor : List Id -> String -> Floor -> Floor
changeObjectBackgroundColor ids color floor =
  let
    newObjects =
      partiallyChange (changeColor color) ids (objects floor)
  in
    setObjects newObjects floor


changeObjectShape : List Id -> Object.Shape -> Floor -> Floor
changeObjectShape ids shape floor =
  let
    newObjects =
      partiallyChange (changeShape shape) ids (objects floor)
  in
    setObjects newObjects floor


changeObjectName : List Id -> String -> Floor -> Floor
changeObjectName ids name floor =
  let
    newObjects =
      partiallyChange (Object.changeName name) ids (objects floor)
  in
    setObjects newObjects floor


changeObjectFontSize : List Id -> Float -> Floor -> Floor
changeObjectFontSize ids fontSize floor =
  let
    newObjects =
      partiallyChange (Object.changeFontSize fontSize) ids (objects floor)
  in
    setObjects newObjects floor


toFirstNameOnly : List Id -> Floor -> Floor
toFirstNameOnly ids floor =
  let
    change name =
      case String.words name of
        [] -> ""
        x :: _ -> x

    newObjects =
      partiallyChange (\e -> (flip Object.changeName) e <| change <| nameOf e) ids (objects floor)
  in
    setObjects newObjects floor


removeSpaces : List Id -> Floor -> Floor
removeSpaces ids floor =
  let
    change name =
      (Regex.replace Regex.All (Regex.regex "[ \r\n　]") (\_ -> "")) name

    newObjects =
      partiallyChange (\e -> (flip Object.changeName) e <| change <| nameOf e) ids (objects floor)
  in
    setObjects newObjects floor


resizeObject : Id -> (Int, Int) -> Floor -> Floor
resizeObject id size floor =
  let
    newObjects =
      partiallyChange (changeSize size) [id] (objects floor)
  in
    setObjects newObjects floor


changeName : String -> Floor -> Floor
changeName name floor =
  { floor | name = name }


changeOrd : Int -> Floor -> Floor
changeOrd ord floor =
  { floor | ord = ord }


setImage : String -> Int -> Int -> Floor -> Floor
setImage url width height floor =
  { floor |
    width = width
  , height = height
  , image = Just url
  }


changeRealSize : (Int, Int) -> Floor -> Floor
changeRealSize (width, height) floor =
  { floor |
    realSize = Just (width, height)
  }


setPerson : String -> String -> Floor -> Floor
setPerson objectId personId floor =
  let
    newObjects =
      partiallyChange (Object.setPerson (Just personId)) [objectId] (objects floor)
  in
    setObjects newObjects floor


setPeople : List (String, String) -> Floor -> Floor
setPeople pairs floor =
  let
    f (objectId, personId) objects =
      partiallyChange (Object.setPerson (Just personId)) [objectId] objects

    newObjects =
      List.foldl f (objects floor) pairs
  in
    setObjects newObjects floor


unsetPerson : String -> Floor -> Floor
unsetPerson objectId floor =
  let
    newObjects =
      partiallyChange (Object.setPerson Nothing) [objectId] (objects floor)
  in
    setObjects newObjects floor


{- 10cm -> 8px -}
realToPixel : Int -> Int
realToPixel real =
  Basics.floor (toFloat real * 80)


pixelToReal : Int -> Int
pixelToReal pixel =
  Basics.floor (toFloat pixel / 80)


size : Floor -> (Int, Int)
size floor =
  case floor.realSize of
    Just (w, h) -> (realToPixel w, realToPixel h)
    Nothing -> (floor.width, floor.height)


name : Floor -> String
name floor = floor.name


width : Floor -> Int
width floor = size floor |> fst


height : Floor -> Int
height floor = size floor |> snd


-- TODO confusing...
realSize : Floor -> (Int, Int)
realSize floor =
  case floor.realSize of
    Just (w, h) -> (w, h)
    Nothing -> (pixelToReal floor.width, pixelToReal floor.height)


objects : Floor -> List Object
objects floor =
  floor.objects


setObjects : List Object -> Floor -> Floor
setObjects objects floor =
  { floor |
    objects = objects
  }


addObjects : List Object -> Floor -> Floor
addObjects objects floor =
  setObjects (floor.objects ++ objects) floor


src : Floor -> Maybe String
src floor =
  case floor.image of
    Just src -> Just ("/images/floors/" ++ src)
    Nothing -> Nothing
