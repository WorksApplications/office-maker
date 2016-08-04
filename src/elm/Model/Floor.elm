module Model.Floor exposing (..)

import String
import Date exposing (Date)
import Model.Object as Object exposing (..)
import Model.ObjectsOperation as ObjectsOperation exposing (..)

import Util.File exposing (..)


type alias Id = String

type alias Model =
  { id : Maybe Id
  , version : Int
  , name : String
  , ord : Int
  , objects: List Object
  , width : Int
  , height : Int
  , realSize : Maybe (Int, Int)
  , imageSource : ImageSource
  , public : Bool
  , update : Maybe { by : Id, at : Date }
  }


type ImageSource
  = LocalFile String File String
  | URL String
  | None


init : Maybe Id -> Model
init id =
  { id = id
  , version = 0
  , name = "New Floor"
  , ord = 0
  , objects = []
  , width = 800
  , height = 600
  , realSize = Nothing
  , imageSource = None
  , public = False
  , update = Nothing
  }


initWithOrder : Maybe Id -> Int -> Model
initWithOrder id ord =
  let
    floor = init id
  in
    { floor |
      ord = ord
    }


copy : Maybe Id -> Model -> Model
copy id floor =
  { floor |
    id = id
  , version = 0
  , name = "Copy of " ++ floor.name
  , public = False
  , update = Nothing
  }


type Msg =
    CreateDesk (List (Id, (Int, Int, Int, Int), String, String))
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
  | ChangeFontSize (List Id) Float
  | ToFirstNameOnly (List Id)
  | ResizeObject Id (Int, Int)
  | ChangeName String
  | ChangeOrd Int
  | SetLocalFile String File String
  | ChangeRealSize (Int, Int)
  | SetPerson String String
  | UnsetPerson String


createDesk : List (Id, (Int, Int, Int, Int), String, String) -> Msg
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


toFirstNameOnly : List Id -> Msg
toFirstNameOnly = ToFirstNameOnly


resizeObject : Id -> (Int, Int) -> Msg
resizeObject = ResizeObject


changeFontSize : List Id -> Float -> Msg
changeFontSize = ChangeFontSize


changeName : String -> Msg
changeName = ChangeName


changeOrd : Int -> Msg
changeOrd = ChangeOrd


setLocalFile : String -> File -> String -> Msg
setLocalFile = SetLocalFile


changeRealSize : (Int, Int) -> Msg
changeRealSize = ChangeRealSize


setPerson : String -> String -> Msg
setPerson = SetPerson


unsetPerson : String -> Msg
unsetPerson = UnsetPerson


update : Msg -> Model -> Model
update msg model =
  case msg of
    CreateDesk candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), color, name) =
          Object.initDesk newId (x, y, w, h) color name Nothing
      in
        addObjects
          (List.map create candidateWithNewIds)
          model

    CreateLabel candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), bgColor, name, fontSize, color) =
          Object.initLabel newId (x, y, w, h) bgColor name fontSize color Object.Rectangle
      in
        addObjects
          (List.map create candidateWithNewIds)
          model

    Move ids gridSize (dx, dy) ->
      setObjects
        (moveObjects gridSize (dx, dy) ids (objects model))
        model

    Paste copiedWithNewIds (baseX, baseY) ->
      setObjects
        (model.objects ++ (pasteObjects (baseX, baseY) copiedWithNewIds (objects model)))
        model

    Delete ids ->
      setObjects
        (List.filter (\object -> not (List.member (idOf object) ids)) (objects model))
        model

    RotateObject id ->
      setObjects (partiallyChange Object.rotate [id] (objects model)) model

    ChangeId id ->
      { model | id = Just id }

    ChangeObjectBackgroundColor ids bgColor ->
      let
        newObjects =
          partiallyChange (changeBackgroundColor bgColor) ids (objects model)
      in
        setObjects newObjects model

    ChangeObjectColor ids color ->
      let
        newObjects =
          partiallyChange (changeColor color) ids (objects model)
      in
        setObjects newObjects model

    ChangeObjectShape ids shape ->
      let
        newObjects =
          partiallyChange (changeShape shape) ids (objects model)
      in
        setObjects newObjects model

    ChangeObjectName ids name ->
      let
        newObjects =
          partiallyChange (Object.changeName name) ids (objects model)
      in
        setObjects newObjects model

    ToFirstNameOnly ids ->
      let
        change name =
          case String.words name of
            [] -> ""
            x :: _ -> x

        newObjects =
          partiallyChange (\e -> (flip Object.changeName) e <| change <| nameOf e) ids (objects model)
      in
        setObjects newObjects model

    ResizeObject id size ->
      let
        newObjects =
          partiallyChange (changeSize size) [id] (objects model)
      in
        setObjects newObjects model

    ChangeFontSize ids fontSize ->
      let
        newObjects =
          partiallyChange (Object.changeFontSize fontSize) ids (objects model)
      in
        setObjects newObjects model

    ChangeName name ->
      { model | name = name }

    ChangeOrd ord ->
      { model | ord = ord }

    SetLocalFile id file dataURL ->
      setLocalFile' id file dataURL model

    ChangeRealSize (width, height) ->
        { model |
          realSize = Just (width, height)
        -- , useReal = True
        }

    SetPerson objectId personId ->
      let
        newObjects =
          partiallyChange (Object.setPerson (Just personId)) [objectId] (objects model)
      in
        setObjects newObjects model

    UnsetPerson objectId ->
      let
        newObjects =
          partiallyChange (Object.setPerson Nothing) [objectId] (objects model)
      in
        setObjects newObjects model

{- 10cm -> 8px -}
realToPixel : Int -> Int
realToPixel real =
  Basics.floor (toFloat real * 80)


pixelToReal : Int -> Int
pixelToReal pixel =
  Basics.floor (toFloat pixel / 80)


size : Model -> (Int, Int)
size model =
  case model.realSize of
    Just (w, h) -> (realToPixel w, realToPixel h)
    Nothing -> (model.width, model.height)


name : Model -> String
name model = model.name


width : Model -> Int
width model = size model |> fst


height : Model -> Int
height model = size model |> snd


-- TODO confusing...
realSize : Model -> (Int, Int)
realSize model =
  case model.realSize of
    Just (w, h) -> (w, h)
    Nothing -> (pixelToReal model.width, pixelToReal model.height)


objects : Model -> List Object
objects model =
  model.objects


setObjects : List Object -> Model -> Model
setObjects objects model =
  { model |
    objects = objects
  }


addObjects : List Object -> Model -> Model
addObjects objects model =
  setObjects (model.objects ++ objects) model


setLocalFile' : String -> File -> String -> Model -> Model
setLocalFile' id file dataURL model =
  let
    (width, height) =
      getSizeOfImage dataURL
  in
    { model |
      width = width
    , height = height
    , imageSource = LocalFile id file dataURL
    }


src : Model -> Maybe String
src model =
  case model.imageSource of
    LocalFile id list dataURL -> Just dataURL
    URL src -> Just ("/images/floors/" ++ src)
    None -> Nothing
