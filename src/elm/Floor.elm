module Floor where

import Equipments exposing (..)
import EquipmentsOperation exposing (..)
import HtmlUtil exposing (..)

type alias Id = String

type alias Model =
  { id : Id
  , name : String
  , equipments: List Equipment
  , width : Int
  , height : Int
  , dataURL : Maybe String
  }

init : Model
init =
    { id = "1"
    , name = "1F"
    , equipments = []
    , width = 800
    , height = 600
    , dataURL = Nothing
    }

type Action =
    Create (List (Id, (Int, Int, Int, Int), String, String))
  | Move (List Id) Int (Int, Int)
  | Paste (List (Equipment, Id)) (Int, Int)
  | Delete (List Id)
  | ChangeEquipmentColor (List Id) String
  | ChangeEquipmentName Id String
  | ChangeImage String

create : (List (Id, (Int, Int, Int, Int), String, String)) -> Action
create = Create

move : (List Id) -> Int -> (Int, Int) -> Action
move = Move

paste : (List (Equipment, Id)) -> (Int, Int) -> Action
paste = Paste

delete : (List Id) -> Action
delete = Delete

changeEquipmentColor : (List Id) -> String -> Action
changeEquipmentColor = ChangeEquipmentColor

changeEquipmentName : Id -> String -> Action
changeEquipmentName = ChangeEquipmentName

changeImage : String -> Action
changeImage = ChangeImage

update : Action -> Model -> Model
update action floor =
  case action of
    Create candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), color, name)=
          Equipments.init newId (x, y, w, h) color name
      in
        addEquipments
          (List.map create candidateWithNewIds)
          floor
    Move ids gridSize (dx, dy) ->
      setEquipments
        (moveEquipments gridSize (dx, dy) ids (equipments floor))
        floor
    Paste copiedWithNewIds (baseX, baseY) ->
      setEquipments
        (floor.equipments ++ (pasteEquipments (baseX, baseY) copiedWithNewIds (equipments floor)))
        floor
    Delete ids ->
      setEquipments
        (List.filter (\equipment -> not (List.member (idOf equipment) ids)) (equipments floor))
        floor
    ChangeEquipmentColor ids color ->
      let
        newEquipments =
          partiallyChange (changeColor color) ids (equipments floor)
      in
        setEquipments newEquipments floor
    ChangeEquipmentName id name ->
      setEquipments
        (commitInputName (id, name) (equipments floor))
        floor
    ChangeImage dataURL ->
      setImage dataURL floor


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
