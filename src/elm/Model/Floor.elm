module Model.Floor exposing (..) -- where

import Model.Equipments as Equipments exposing (..)
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Util.File exposing (..)

type alias Id = String

type alias Model =
  { id : Id
  , name : String
  , equipments: List Equipment
  , width : Int
  , height : Int
  , realSize : Maybe (Int, Int)
  , imageSource : ImageSource
  }

type ImageSource =
  LocalFile String File String | URL String | None

init : Id -> Model
init id =
    { id = id
    , name = "1F"
    , equipments = []
    , width = 800
    , height = 600
    , realSize = Nothing
    , imageSource = None
    }

type Action =
    Create (List (Id, (Int, Int, Int, Int), String, String))
  | Move (List Id) Int (Int, Int)
  | Paste (List (Equipment, Id)) (Int, Int)
  | Delete (List Id)
  | Rotate Id
  | ChangeEquipmentColor (List Id) String
  | ChangeEquipmentName Id String
  | ChangeName String
  | SetLocalFile String File String
  | ChangeRealWidth Int
  | ChangeRealHeight Int
  | UseURL
  | ChangeUserCandidate String (List String)

create : (List (Id, (Int, Int, Int, Int), String, String)) -> Action
create = Create

move : (List Id) -> Int -> (Int, Int) -> Action
move = Move

paste : (List (Equipment, Id)) -> (Int, Int) -> Action
paste = Paste

delete : (List Id) -> Action
delete = Delete

rotate : Id -> Action
rotate = Rotate

changeEquipmentColor : (List Id) -> String -> Action
changeEquipmentColor = ChangeEquipmentColor

changeEquipmentName : Id -> String -> Action
changeEquipmentName = ChangeEquipmentName

changeName : String -> Action
changeName = ChangeName

setLocalFile : String -> File -> String -> Action
setLocalFile = SetLocalFile

changeRealWidth : Int -> Action
changeRealWidth = ChangeRealWidth

changeRealHeight : Int -> Action
changeRealHeight = ChangeRealHeight

useURL : Action
useURL = UseURL

changeUserCandidate : String -> List String -> Action
changeUserCandidate = ChangeUserCandidate

update : Action -> Model -> Model
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
    ChangeRealWidth width ->
      let
        newRealSize =
          case model.realSize of
            Just (w, h) -> Just (width, h)
            Nothing -> Just (width, pixelToReal model.height)
      in
        { model |
          realSize = newRealSize
        -- , useReal = True
        }
    ChangeRealHeight height ->
      let
        newRealSize =
          case model.realSize of
            Just (w, h) -> Just (w, height)
            Nothing -> Just (pixelToReal model.width, height)
      in
        { model |
          realSize = newRealSize
        -- , useReal = True
        }
    UseURL ->
      { model |
        imageSource =
          case model.imageSource of
            LocalFile id list dataURL ->
              URL id
            _ ->
              model.imageSource
      }
    ChangeUserCandidate equipmentId ids ->
      let
        newEquipments =
          case ids of
            head :: [] ->
              partiallyChange (Equipments.setPerson (Just head)) [equipmentId] (equipments model)
            _ ->
              partiallyChange (Equipments.setPerson Nothing) [equipmentId] (equipments model)
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
    URL src -> Just ("/images/" ++ src)
    None -> Nothing
