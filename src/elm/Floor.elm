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
  , dataURL : Maybe String
  }

init : Id -> Model
init id =
    { id = id
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
  | ChangeName String
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

changeName : String -> Action
changeName = ChangeName

changeImage : String -> Action
changeImage = ChangeImage

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
