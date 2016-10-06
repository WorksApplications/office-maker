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


type Msg
  = CreateDesk (List (Id, (Int, Int, Int, Int), String, String, Float))
  | CreateLabel (List (Id, (Int, Int, Int, Int), String, String, Float, String))
  | Move (List Id) Int (Int, Int)
  | Paste (List (Object, Id)) (Int, Int)
  | Delete (List Id)
  | RotateObject Id
  | ChangeId Id
  | ChangeObjectBackgroundColor (List Id) String
  | ChangeObjectColor (List Id) String
  | ChangeObjectShape (List Id) Object.Shape
  | ChangeObjectName (List Id) String
  | ChangeObjectFontSize (List Id) Float
  | ToFirstNameOnly (List Id)
  | RemoveSpaces (List Id)
  | ResizeObject Id (Int, Int)
  | ChangeName String
  | ChangeOrd Int
  | SetImage String Int Int
  | ChangeRealSize (Int, Int)
  | SetPerson String String
  | SetPeople (List (String, String))
  | UnsetPerson String


createDesk : List (Id, (Int, Int, Int, Int), String, String, Float) -> Msg
createDesk = CreateDesk


createLabel : List (Id, (Int, Int, Int, Int), String, String, Float, String) -> Msg
createLabel = CreateLabel


move : (List Id) -> Int -> (Int, Int) -> Msg
move = Move


paste : (List (Object, Id)) -> (Int, Int) -> Msg
paste = Paste


delete : (List Id) -> Msg
delete = Delete


rotateObject : Id -> Msg
rotateObject = RotateObject


changeId : Id -> Msg
changeId = ChangeId


changeObjectColor : List Id -> String -> Msg
changeObjectColor = ChangeObjectColor


changeObjectBackgroundColor : List Id -> String -> Msg
changeObjectBackgroundColor = ChangeObjectBackgroundColor


changeObjectShape : List Id -> Object.Shape -> Msg
changeObjectShape = ChangeObjectShape


changeObjectName : List Id -> String -> Msg
changeObjectName = ChangeObjectName


changeObjectFontSize : List Id -> Float -> Msg
changeObjectFontSize = ChangeObjectFontSize


toFirstNameOnly : List Id -> Msg
toFirstNameOnly = ToFirstNameOnly


removeSpaces : List Id -> Msg
removeSpaces = RemoveSpaces


resizeObject : Id -> (Int, Int) -> Msg
resizeObject = ResizeObject


changeName : String -> Msg
changeName = ChangeName


changeOrd : Int -> Msg
changeOrd = ChangeOrd


setImage : String -> Int -> Int -> Msg
setImage = SetImage


changeRealSize : (Int, Int) -> Msg
changeRealSize = ChangeRealSize


setPerson : String -> String -> Msg
setPerson = SetPerson


setPeople : List (String, String) -> Msg
setPeople = SetPeople


unsetPerson : String -> Msg
unsetPerson = UnsetPerson


update : Msg -> Floor -> Floor
update msg floor =
  case msg of
    CreateDesk candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), color, name, fontSize) =
          Object.initDesk newId (x, y, w, h) color name fontSize Nothing
      in
        addObjects
          (List.map create candidateWithNewIds)
          floor

    CreateLabel candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), bgColor, name, fontSize, color) =
          Object.initLabel newId (x, y, w, h) bgColor name fontSize color Object.Rectangle
      in
        addObjects
          (List.map create candidateWithNewIds)
          floor

    Move ids gridSize (dx, dy) ->
      setObjects
        (moveObjects gridSize (dx, dy) ids (objects floor))
        floor

    Paste copiedWithNewIds (baseX, baseY) ->
      setObjects
        (floor.objects ++ (pasteObjects (baseX, baseY) copiedWithNewIds (objects floor)))
        floor

    Delete ids ->
      setObjects
        (List.filter (\object -> not (List.member (idOf object) ids)) (objects floor))
        floor

    RotateObject id ->
      setObjects (partiallyChange Object.rotate [id] (objects floor)) floor

    ChangeId id ->
      { floor | id = id }

    ChangeObjectBackgroundColor ids bgColor ->
      let
        newObjects =
          partiallyChange (changeBackgroundColor bgColor) ids (objects floor)
      in
        setObjects newObjects floor

    ChangeObjectColor ids color ->
      let
        newObjects =
          partiallyChange (changeColor color) ids (objects floor)
      in
        setObjects newObjects floor

    ChangeObjectShape ids shape ->
      let
        newObjects =
          partiallyChange (changeShape shape) ids (objects floor)
      in
        setObjects newObjects floor

    ChangeObjectName ids name ->
      let
        newObjects =
          partiallyChange (Object.changeName name) ids (objects floor)
      in
        setObjects newObjects floor

    ChangeObjectFontSize ids fontSize ->
      let
        newObjects =
          partiallyChange (Object.changeFontSize fontSize) ids (objects floor)
      in
        setObjects newObjects floor

    ToFirstNameOnly ids ->
      let
        change name =
          case String.words name of
            [] -> ""
            x :: _ -> x

        newObjects =
          partiallyChange (\e -> (flip Object.changeName) e <| change <| nameOf e) ids (objects floor)
      in
        setObjects newObjects floor

    RemoveSpaces ids ->
      let
        change name =
          (Regex.replace Regex.All (Regex.regex "[ \r\n　]") (\_ -> "")) name

        newObjects =
          partiallyChange (\e -> (flip Object.changeName) e <| change <| nameOf e) ids (objects floor)
      in
        setObjects newObjects floor

    ResizeObject id size ->
      let
        newObjects =
          partiallyChange (changeSize size) [id] (objects floor)
      in
        setObjects newObjects floor

    ChangeName name ->
      { floor | name = name }

    ChangeOrd ord ->
      { floor | ord = ord }

    SetImage url width height ->
      setImage' url width height floor

    ChangeRealSize (width, height) ->
        { floor |
          realSize = Just (width, height)
        -- , useReal = True
        }

    SetPerson objectId personId ->
      let
        newObjects =
          partiallyChange (Object.setPerson (Just personId)) [objectId] (objects floor)
      in
        setObjects newObjects floor

    SetPeople pairs ->
      let
        f (objectId, personId) objects =
          partiallyChange (Object.setPerson (Just personId)) [objectId] objects

        newObjects =
          List.foldl f (objects floor) pairs
      in
        setObjects newObjects floor

    UnsetPerson objectId ->
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


setImage' : String -> Int -> Int -> Floor -> Floor
setImage' url width height floor =
  { floor |
    width = width
  , height = height
  , image = Just url
  }


src : Floor -> Maybe String
src floor =
  case floor.image of
    Just src -> Just ("/images/floors/" ++ src)
    Nothing -> Nothing
