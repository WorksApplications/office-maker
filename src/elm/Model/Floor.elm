module Model.Floor exposing (..)

import String
import Date exposing (Date)
import Model.Equipment as Equipment exposing (..)
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Util.File exposing (..)

type alias Id = String

type alias Model =
  { id : Maybe Id
  , name : String
  , ord : Int
  , equipments: List Equipment
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
  , name = "New Floor"
  , ord = 0
  , equipments = []
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
    name = "Copy of " ++ floor.name
  , public = False
  }


type Msg =
    CreateDesk (List (Id, (Int, Int, Int, Int), String, String))
  | CreateLabel (List (Id, (Int, Int, Int, Int), String, String, Float, String))
  | Move (List Id) Int (Int, Int)
  | Paste (List (Equipment, Id)) (Int, Int)
  | Delete (List Id)
  | RotateEquipment Id
  | ChangeId Id
  | ChangeEquipmentBackgroundColor (List Id) String
  | ChangeEquipmentColor (List Id) String
  | ChangeEquipmentShape (List Id) Equipment.Shape
  | ChangeEquipmentName (List Id) String
  | ChangeFontSize (List Id) Float
  | ToFirstNameOnly (List Id)
  | ResizeEquipment Id (Int, Int)
  | ChangeName String
  | ChangeOrd Int
  | SetLocalFile String File String
  | ChangeRealSize (Int, Int)
  | OnSaved Bool
  | SetPerson String String
  | UnsetPerson String


createDesk : List (Id, (Int, Int, Int, Int), String, String) -> Msg
createDesk = CreateDesk


createLabel : List (Id, (Int, Int, Int, Int), String, String, Float, String) -> Msg
createLabel = CreateLabel


move : (List Id) -> Int -> (Int, Int) -> Msg
move = Move


paste : (List (Equipment, Id)) -> (Int, Int) -> Msg
paste = Paste


delete : (List Id) -> Msg
delete = Delete


rotateEquipment : Id -> Msg
rotateEquipment = RotateEquipment


changeId : Id -> Msg
changeId = ChangeId


changeEquipmentColor : List Id -> String -> Msg
changeEquipmentColor = ChangeEquipmentColor


changeEquipmentBackgroundColor : List Id -> String -> Msg
changeEquipmentBackgroundColor = ChangeEquipmentBackgroundColor


changeEquipmentShape : List Id -> Equipment.Shape -> Msg
changeEquipmentShape = ChangeEquipmentShape


changeEquipmentName : List Id -> String -> Msg
changeEquipmentName = ChangeEquipmentName


toFirstNameOnly : List Id -> Msg
toFirstNameOnly = ToFirstNameOnly


resizeEquipment : Id -> (Int, Int) -> Msg
resizeEquipment = ResizeEquipment


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


onSaved : Bool -> Msg
onSaved = OnSaved


setPerson : String -> String -> Msg
setPerson = SetPerson


unsetPerson : String -> Msg
unsetPerson = UnsetPerson


update : Msg -> Model -> Model
update action model =
  case action of
    CreateDesk candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), color, name) =
          Equipment.initDesk newId (x, y, w, h) color name Nothing
      in
        addEquipments
          (List.map create candidateWithNewIds)
          model

    CreateLabel candidateWithNewIds ->
      let
        create (newId, (x, y, w, h), bgColor, name, fontSize, color) =
          Equipment.initLabel newId (x, y, w, h) bgColor name fontSize color Equipment.Rectangle
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

    RotateEquipment id ->
      setEquipments (partiallyChange Equipment.rotate [id] (equipments model)) model

    ChangeId id ->
      { model | id = Just id }

    ChangeEquipmentBackgroundColor ids bgColor ->
      let
        newEquipments =
          partiallyChange (changeBackgroundColor bgColor) ids (equipments model)
      in
        setEquipments newEquipments model

    ChangeEquipmentColor ids color ->
      let
        newEquipments =
          partiallyChange (changeColor color) ids (equipments model)
      in
        setEquipments newEquipments model

    ChangeEquipmentShape ids shape ->
      let
        newEquipments =
          partiallyChange (changeShape shape) ids (equipments model)
      in
        setEquipments newEquipments model

    ChangeEquipmentName ids name ->
      let
        newEquipments =
          partiallyChange (Equipment.changeName name) ids (equipments model)
      in
        setEquipments newEquipments model

    ToFirstNameOnly ids ->
      let
        change name =
          case String.words name of
            [] -> ""
            x :: _ -> x

        newEquipments =
          partiallyChange (\e -> (flip Equipment.changeName) e <| change <| nameOf e) ids (equipments model)
      in
        setEquipments newEquipments model

    ResizeEquipment id size ->
      let
        newEquipments =
          partiallyChange (changeSize size) [id] (equipments model)
      in
        setEquipments newEquipments model

    ChangeFontSize ids fontSize ->
      let
        newEquipments =
          partiallyChange (Equipment.changeFontSize fontSize) ids (equipments model)
      in
        setEquipments newEquipments model

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
          partiallyChange (Equipment.setPerson (Just personId)) [equipmentId] (equipments model)
      in
        setEquipments newEquipments model

    UnsetPerson equipmentId ->
      let
        newEquipments =
          partiallyChange (Equipment.setPerson Nothing) [equipmentId] (equipments model)
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
