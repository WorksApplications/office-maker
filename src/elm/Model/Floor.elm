module Model.Floor exposing (..)

import String
import Dict exposing (Dict)
import Regex
import Date exposing (Date)
import Model.Object as Object exposing (Object)
import Model.ObjectsOperation as ObjectsOperation exposing (..)
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)


type alias ObjectId = String
type alias PersonId = String
type alias FloorId = String


type alias FloorBase =
  { id : FloorId
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
  , update : Maybe { by : PersonId, at : Date }
  , objects: Dict ObjectId Object
  }


type alias Floor = Detailed FloorBase


init : FloorId -> Floor
init id =
  { id = id
  , version = 0
  , name = "New Floor"
  , ord = 0
  , objects = Dict.empty
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


initWithOrder : FloorId -> Int -> Floor
initWithOrder id ord =
  let
    floor = init id
  in
    { floor |
      ord = ord
    }


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


src : Floor -> Maybe String
src floor =
  case floor.image of
    Just src -> Just ("/images/floors/" ++ src)
    Nothing -> Nothing


changeId : FloorId -> Floor -> Floor
changeId id floor =
  { floor | id = id }


copy : Bool -> FloorId -> Floor -> Floor
copy withEmptyObjects id floor =
  { floor |
    id = id
  , version = 0
  , name = "Copy of " ++ floor.name
  , public = False
  , update = Nothing
  , objects = if withEmptyObjects then Dict.empty else Dict.empty -- TODO
  }


-- OBJECT OPERATIONS


move : List ObjectId -> Int -> (Int, Int) -> Floor -> Floor
move ids gridSize (dx, dy) floor =
  partiallyChangeObjects
    (moveObjects gridSize (dx, dy))
    ids
    floor


moveObjects : Int -> (Int, Int) -> Object -> Object
moveObjects gridSize (dx, dy) object =
  let
    (x, y, _, _) =
      Object.rect object

    (newX, newY) =
      fitPositionToGrid gridSize (x + dx, y + dy)
  in
    Object.move (newX, newY) object


overrideObjects : List Object -> Floor -> Floor
overrideObjects newObjects floor =
  newObjects
    |> List.foldl (\object memo -> overrideObject object memo) floor


overrideObject : Object -> Floor -> Floor
overrideObject newObject floor =
  if Object.floorIdOf newObject == floor.id then
    let
      remainingObjects =
        List.filter (\object -> (Object.idOf object) /= (Object.idOf newObject)) (objects floor)
    in
      setObjects ( newObject :: remainingObjects ) floor
  else
    floor


paste : List (Object, ObjectId) -> (Int, Int) -> Floor -> Floor
paste copiedWithNewIds (baseX, baseY) floor =
  addObjects
    (pasteObjects floor.id (baseX, baseY) copiedWithNewIds)
    floor


delete : List ObjectId -> Floor -> Floor
delete ids floor =
  setObjects
    (List.filter (\object -> not (List.member (Object.idOf object) ids)) (objects floor))
    floor


rotateObject : ObjectId -> Floor -> Floor
rotateObject id floor =
  partiallyChangeObjects (Object.rotate) [id] floor


changeObjectColor : List ObjectId -> String -> Floor -> Floor
changeObjectColor ids color floor =
  partiallyChangeObjects (Object.changeColor color) ids floor


changeObjectBackgroundColor : List ObjectId -> String -> Floor -> Floor
changeObjectBackgroundColor ids color floor =
  partiallyChangeObjects (Object.changeBackgroundColor color) ids floor


changeObjectShape : List ObjectId -> Object.Shape -> Floor -> Floor
changeObjectShape ids shape floor =
  partiallyChangeObjects (Object.changeShape shape) ids floor


changeObjectName : List ObjectId -> String -> Floor -> Floor
changeObjectName ids name floor =
  partiallyChangeObjects (Object.changeName name) ids floor


changeObjectFontSize : List ObjectId -> Float -> Floor -> Floor
changeObjectFontSize ids fontSize floor =
  partiallyChangeObjects (Object.changeFontSize fontSize) ids floor


changeObjectsByChanges : ObjectsChange -> Floor -> Floor
changeObjectsByChanges change floor =
  let
    separated =
      ObjectsChange.separate change
  in
    overrideObjects (separated.added ++ separated.modified) floor


toFirstNameOnly : List ObjectId -> Floor -> Floor
toFirstNameOnly ids floor =
  let
    change name =
      case String.words name of
        [] -> ""
        x :: _ -> x

    f object =
      Object.changeName (change (Object.nameOf object)) object
  in
    partiallyChangeObjects f ids floor


partiallyChangeObjects : (Object -> Object) -> List ObjectId -> Floor -> Floor
partiallyChangeObjects f ids floor =
  { floor
    | objects =
        ids
          |> List.foldl
              (\objectId dict -> Dict.update objectId (Maybe.map f) dict)
              floor.objects
  }


removeSpaces : List ObjectId -> Floor -> Floor
removeSpaces ids floor =
  let
    change name =
      (Regex.replace Regex.All (Regex.regex "[ \r\n　]") (\_ -> "")) name

    f object =
      Object.changeName (change <| Object.nameOf object) object
  in
    partiallyChangeObjects f ids floor


resizeObject : ObjectId -> (Int, Int) -> Floor -> Floor
resizeObject id size floor =
  partiallyChangeObjects (Object.changeSize size) [id] floor


setPerson : ObjectId -> PersonId -> Floor -> Floor
setPerson objectId personId floor =
  setPeople [(objectId, personId)] floor


unsetPerson : ObjectId -> Floor -> Floor
unsetPerson objectId floor =
  partiallyChangeObjects (Object.setPerson Nothing) [objectId] floor


setPeople : List (ObjectId, PersonId) -> Floor -> Floor
setPeople pairs floor =
  let
    f (objectId, personId) dict =
      dict
        |> Dict.update objectId (Maybe.map (Object.setPerson (Just personId)))

    newObjects =
      List.foldl f (floor.objects) pairs
  in
    { floor | objects = newObjects }


objects : Floor -> List Object
objects floor =
  Dict.values floor.objects


getObject : ObjectId -> Floor -> Maybe Object
getObject objectId floor =
  Dict.get objectId floor.objects


getObjects : List ObjectId -> Floor -> List Object
getObjects ids floor =
  ids
    |> List.filterMap (\id -> getObject id floor)


setObjects : List Object -> Floor -> Floor
setObjects objects floor =
  { floor |
    objects =
      objectsDictFromList floor.id objects
  }


addObjects : List Object -> Floor -> Floor
addObjects objects floor =
  { floor |
    objects =
      objects
        |> filterObjectsInFloor floor.id
        |> List.foldl (\object -> Dict.insert (Object.idOf object) object) floor.objects
  }


objectsDictFromList : FloorId -> List Object -> Dict ObjectId Object
objectsDictFromList floorId objects =
  objects
    |> filterObjectsInFloor floorId
    |> List.map (\object -> (Object.idOf object, object))
    |> Dict.fromList


filterObjectsInFloor : FloorId -> List Object -> List Object
filterObjectsInFloor floorId objects =
  objects
    |> List.filter (\object -> Object.floorIdOf object == floorId)
