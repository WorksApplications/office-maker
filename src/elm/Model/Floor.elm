module Model.Floor exposing (..)

import String
import Regex
import Date exposing (Date)
import Model.Object as Object exposing (Object)
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


copy : Bool -> Id -> Floor -> Floor
copy withEmptyObjects id floor =
  { floor |
    id = id
  , version = 0
  , name = "Copy of " ++ floor.name
  , public = False
  , update = Nothing
  , objects = if withEmptyObjects then [] else [] -- TODO
  }


move : List Id -> Int -> (Int, Int) -> Floor -> Floor
move ids gridSize (dx, dy) floor =
  setObjects
    (moveObjects gridSize (dx, dy) ids (objects floor))
    floor


overrideObject : Int -> Object -> Floor -> Floor
overrideObject gridSize newObject floor =
  let
    remainingObjects =
      List.filter (\object -> (Object.idOf object) /= (Object.idOf newObject)) (objects floor)
  in
    setObjects ( remainingObjects ++ [ newObject ] ) floor


paste : List (Object, Id) -> (Int, Int) -> Floor -> Floor
paste copiedWithNewIds (baseX, baseY) floor =
  addObjects
    (pasteObjects floor.id (baseX, baseY) copiedWithNewIds)
    floor


delete : List Id -> Floor -> Floor
delete ids floor =
  setObjects
    (List.filter (\object -> not (List.member (Object.idOf object) ids)) (objects floor))
    floor


rotateObject : Id -> Floor -> Floor
rotateObject id floor =
  changeObjects (Object.rotate) [id] floor


changeId : Id -> Floor -> Floor
changeId id floor =
  { floor | id = id }


changeObjectColor : List Id -> String -> Floor -> Floor
changeObjectColor ids color floor =
  changeObjects (Object.changeColor color) ids floor


changeObjectBackgroundColor : List Id -> String -> Floor -> Floor
changeObjectBackgroundColor ids color floor =
  changeObjects (Object.changeBackgroundColor color) ids floor


changeObjectShape : List Id -> Object.Shape -> Floor -> Floor
changeObjectShape ids shape floor =
  changeObjects (Object.changeShape shape) ids floor


changeObjectName : List Id -> String -> Floor -> Floor
changeObjectName ids name floor =
  changeObjects (Object.changeName name) ids floor


changeObjectFontSize : List Id -> Float -> Floor -> Floor
changeObjectFontSize ids fontSize floor =
  changeObjects (Object.changeFontSize fontSize) ids floor


changeObjects : (Object -> Object) -> List Id -> Floor -> Floor
changeObjects f ids floor =
  setObjects (partiallyChange f ids (objects floor)) floor


toFirstNameOnly : List Id -> Floor -> Floor
toFirstNameOnly ids floor =
  let
    change name =
      case String.words name of
        [] -> ""
        x :: _ -> x

    newObjects =
      partiallyChange (\e -> (flip Object.changeName) e <| change <| Object.nameOf e) ids (objects floor)
  in
    setObjects newObjects floor


removeSpaces : List Id -> Floor -> Floor
removeSpaces ids floor =
  let
    change name =
      (Regex.replace Regex.All (Regex.regex "[ \r\n　]") (\_ -> "")) name

    newObjects =
      partiallyChange (\e -> (flip Object.changeName) e <| change <| Object.nameOf e) ids (objects floor)
  in
    setObjects newObjects floor


resizeObject : Id -> (Int, Int) -> Floor -> Floor
resizeObject id size floor =
  changeObjects (Object.changeSize size) [id] floor


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
  changeObjects (Object.setPerson (Just personId)) [objectId] floor


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
  changeObjects (Object.setPerson Nothing) [objectId] floor


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
