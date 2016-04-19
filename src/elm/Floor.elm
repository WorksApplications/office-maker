module Floor where

import Equipments exposing (..)
import EquipmentsOperation exposing (..)
import Util.HtmlUtil exposing (..)

type alias Id = String

type alias Model =
  { id : Id
  , name : String
  , equipments: List Equipment
  , width : Int
  , height : Int
  , realSize : Maybe (Int, Int)
  , dataURL : Maybe String
  }

init : Id -> Model
init id =
    { id = id
    , name = "1F"
    , equipments = []
    , width = 800
    , height = 600
    , realSize = Nothing
    , dataURL = Nothing
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
  | ChangeImage String
  | ChangeRealWidth Int
  | ChangeRealHeight Int

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

changeImage : String -> Action
changeImage = ChangeImage

changeRealWidth : Int -> Action
changeRealWidth = ChangeRealWidth

changeRealHeight : Int -> Action
changeRealHeight = ChangeRealHeight

update : Action -> Model -> Model
update action model =
  case action of
    Create candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), color, name) =
          Equipments.init newId (x, y, w, h) color name
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
      setEquipments (partiallyChange EquipmentsOperation.rotate [id] (equipments model)) model
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
    ChangeImage dataURL ->
      setImage dataURL model
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


setImage : String -> Model -> Model
setImage dataURL model =
  let
    (width, height) = getWidthAndHeightOfImage dataURL
  in
    { model |
      width = width
    , height = height
    , dataURL = Just dataURL
    }
