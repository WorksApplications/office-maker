module Model.Floor exposing (..) -- where

import Date exposing (Date)
import Model.Equipments as Equipments exposing (..)
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Util.File exposing (..)

type alias Id = String

type alias Model =
  { id : Maybe Id
  , name : String
  , equipments: List Equipment
  , width : Int
  , height : Int
  , realSize : Maybe (Int, Int)
  , imageSource : ImageSource
  , public : Bool
  , update : Maybe { by : Id, at : Date }
  }

type ImageSource =
  LocalFile String File String | URL String | None

init : Maybe Id -> Model
init id =
    { id = id
    , name = "1F"
    , equipments = []
    , width = 800
    , height = 600
    , realSize = Nothing
    , imageSource = None
    , public = False
    , update = Nothing
    }

type Msg =
    Create (List (Id, (Int, Int, Int, Int), String, String))
  | Move (List Id) Int (Int, Int)
  | Paste (List (Equipment, Id)) (Int, Int)
  | Delete (List Id)
  | Rotate Id
  | ChangeId Id
  | ChangeEquipmentColor (List Id) String
  | ChangeEquipmentName Id String
  | ChangeName String
  | SetLocalFile String File String
  | ChangeRealSize (Int, Int)
  | OnSaved Bool
  | SetPerson String String

create : (List (Id, (Int, Int, Int, Int), String, String)) -> Msg
create = Create

move : (List Id) -> Int -> (Int, Int) -> Msg
move = Move

paste : (List (Equipment, Id)) -> (Int, Int) -> Msg
paste = Paste

delete : (List Id) -> Msg
delete = Delete

rotate : Id -> Msg
rotate = Rotate

changeId : Id -> Msg
changeId = ChangeId

changeEquipmentColor : (List Id) -> String -> Msg
changeEquipmentColor = ChangeEquipmentColor

changeEquipmentName : Id -> String -> Msg
changeEquipmentName = ChangeEquipmentName

changeName : String -> Msg
changeName = ChangeName

setLocalFile : String -> File -> String -> Msg
setLocalFile = SetLocalFile

changeRealSize : (Int, Int) -> Msg
changeRealSize = ChangeRealSize

onSaved : Bool -> Msg
onSaved = OnSaved

setPerson : String -> String -> Msg
setPerson = SetPerson

update : Msg -> Model -> Model
update action model =
  case action of
    Create candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), color, name) =
          Equipments.init newId (x, y, w, h) color name Nothing
      in
        addEquipments
          (List.map create candidateWithNewIds)
          model
    Move ids gridSize (dx, dy) ->
      setEquipments
        (moveEquipments gridSize (dx, dy) ids (equipments model))
        model
    Paste copiedWithNewIds (baseX, baseY) ->
      setEquipments
        (model.equipments ++ (pasteEquipments (baseX, baseY) copiedWithNewIds (equipments model)))
        model
    Delete ids ->
      setEquipments
        (List.filter (\equipment -> not (List.member (idOf equipment) ids)) (equipments model))
        model
    Rotate id ->
      setEquipments (partiallyChange Equipments.rotate [id] (equipments model)) model
    ChangeId id ->
      { model | id = Just id }
    ChangeEquipmentColor ids color ->
      let
        newEquipments =
          partiallyChange (changeColor color) ids (equipments model)
      in
        setEquipments newEquipments model
    ChangeEquipmentName id name ->
      setEquipments
        (commitInputName (id, name) (equipments model))
        model
    ChangeName name ->
      { model | name = name }
    SetLocalFile id file dataURL ->
      setLocalFile' id file dataURL model
    ChangeRealSize (width, height) ->
        { model |
          realSize = Just (width, height)
        -- , useReal = True
        }
    OnSaved isPublish ->
      { model |
        imageSource =
          case model.imageSource of
            LocalFile id list dataURL ->
              URL id
            _ ->
              model.imageSource
      , public = isPublish
      }
    SetPerson equipmentId personId ->
      let
        newEquipments =
          partiallyChange (Equipments.setPerson (Just personId)) [equipmentId] (equipments model)
      in
        setEquipments newEquipments model

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

width : Model -> Int
width model = size model |> fst

height : Model -> Int
height model = size model |> snd

realSize : Model -> (Int, Int)
realSize model =
  case model.realSize of
    Just (w, h) -> (w, h)
    Nothing -> (pixelToReal model.width, pixelToReal model.height)

equipments : Model -> List Equipment
equipments model =
  model.equipments

setEquipments : List Equipment -> Model -> Model
setEquipments equipments model =
  { model |
    equipments = equipments
  }

addEquipments : List Equipment -> Model -> Model
addEquipments equipments model =
  setEquipments (model.equipments ++ equipments) model


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
