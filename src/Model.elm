module Model (..) where

import Maybe
import Signal exposing (Signal, Address, forwardTo)
import Task
import Effects exposing (Effects)
import Debug
import Window

import UndoRedo
import Keys exposing (..)
import HtmlUtil exposing (..)
import Equipments exposing (..)
import EquipmentsOperation exposing (..)
import IdGenerator exposing (Seed)
import Scale

type alias Floor =
  { name : String
  , equipments: List Equipment
  , width : Int
  , height : Int
  , dataURL : Maybe String
  }

type alias Model =
  { seed : Seed
  , pos : Maybe (Int, Int)
  , dragging : Maybe (Id, (Int, Int))
  , selectedEquipments : List Id
  , copiedEquipments : List Equipment
  , editingEquipment : Maybe (Id, String)
  , gridSize : Int
  , selectorRect : Maybe ((Int, Int, Int, Int), Bool) -- rect, dragging
  , keys : Keys.Model
  , editMode : EditMode
  , colorPalette : List String
  , contextMenu : ContextMenu
  , floor : UndoRedo.Model Floor Commit
  , windowDimensions : (Int, Int)
  , scale : Scale.Model
  , offset : (Int, Int)
  , shiftOffsetPrevScreenPos : Maybe (Int, Int)
  }

type ContextMenu =
    NoContextMenu
  | Equipment (Int, Int) Id

type EditMode = Select | Pen | Stamp

type Commit =
    Move (List Id) Int (Int, Int)
  | Paste (List (Equipment, Id)) (Int, Int)
  | Delete (List Id)
  | ChangeColor (List Id) String
  | ChangeName Id String
  | ChangeImage String


inputs : List (Signal Action)
inputs =
  (List.map (Signal.map KeysAction) Keys.inputs) ++
  [Signal.map WindowDimensions (Window.dimensions)]

init : (Int, Int) -> (Model, Effects Action)
init initialSize =
  (
    { seed = IdGenerator.init
    , pos = Nothing
    , dragging = Nothing
    , selectedEquipments = []
    , copiedEquipments = []
    , editingEquipment = Nothing
    , gridSize = 8 -- 2^N
    , selectorRect = Nothing
    , keys = Keys.init
    , editMode = Select
    , colorPalette = ["#ed9", "#b8f", "#fa9", "#8bd", "#af6", "#6df"] --TODO
    , contextMenu = NoContextMenu
    , floor = UndoRedo.init { data = initFloor, update = updateFloorByCommit }
    , windowDimensions = initialSize
    , scale = Scale.init
    , offset = (35, 35)
    , shiftOffsetPrevScreenPos = Nothing
    }
  , Effects.task (Task.succeed Init)
  )
--

type Action = NoOp
  | Init
  | MoveOnCanvas MouseEvent
  | EnterCanvas
  | LeaveCanvas
  | MouseUpOnCanvas MouseEvent
  | MouseDownOnCanvas MouseEvent
  | MouseDownOnEquipment Id MouseEvent
  | StartEditEquipment Id MouseEvent
  | KeysAction Keys.Action
  | SelectColor String MouseEvent
  | InputName Id String
  | KeydownOnNameInput KeyboardEvent
  | ShowContextMenuOnEquipment Id MouseEvent
  | SelectIsland Id MouseEvent
  | WindowDimensions (Int, Int)
  | MouseWheel MouseWheelEvent
  | ChangeMode EditMode
  | LoadFile FileList
  | GotDataURL String

initFloor : Floor
initFloor =
  setEquipments
    { name = ""
    , equipments = []
    , width = 1610
    , height = 810
    , dataURL = Nothing
    }
    [ Desk "1" (8*5, 8*20, 8*6, 8*10) "#ed9" "John\nSmith"
    , Desk "2" (8*11, 8*20, 8*6, 8*10) "#8bd" "John\nSmith"
    , Desk "3" (8*5, 8*30, 8*6, 8*10) "#fa9" "John\nSmith"
    , Desk "4" (8*11, 8*30, 8*6, 8*10) "#b8f" "John\nSmith"
    , Desk "5" (8*5, 8*40, 8*6, 8*10) "#fa9" "John\nSmith"
    , Desk "6" (8*11, 8*40, 8*6, 8*10) "#b8f" "John\nSmith"
    ]

debug : Bool
debug = False

debugAction : Action -> Action
debugAction action =
  if debug then
    case action of
      MoveOnCanvas _ -> action
      GotDataURL _ -> action
      _ -> Debug.log "action" action
  else
    action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case debugAction action of
    NoOp ->
      (model, Effects.none)
    Init ->
      (model, Effects.none) -- TODO fetch from server
    MoveOnCanvas e ->
      let
        newModel =
          { model |
            pos =
              Just (e.clientX, e.clientY)
          , shiftOffsetPrevScreenPos =
              case model.shiftOffsetPrevScreenPos of
                Just (prevX, prevY) -> Just (e.clientX, e.clientY)
                Nothing -> Nothing
          , offset =
              case model.shiftOffsetPrevScreenPos of
                Just (prevX, prevY) ->
                  let
                    (offsetX, offsetY) = model.offset
                    (dx, dy) =
                      ((e.clientX - prevX), (e.clientY - prevY))
                  in
                    ( offsetX + Scale.screenToImage model.scale dx
                    , offsetY + Scale.screenToImage model.scale dy
                    )
                Nothing -> model.offset
          }
      in
        (newModel, Effects.none)
    EnterCanvas ->
      (model, Effects.none)
    LeaveCanvas ->
      let
        newModel =
          { model |
              shiftOffsetPrevScreenPos = Nothing
          }
      in
        (newModel, Effects.none)
    MouseDownOnEquipment lastTouchedId e ->
      let
        newModel =
          { model |
            selectedEquipments =
              if e.ctrlKey then
                if List.member lastTouchedId model.selectedEquipments
                then List.filter ((/=) lastTouchedId) model.selectedEquipments
                else lastTouchedId :: model.selectedEquipments
              else if e.shiftKey then
                let
                  allEquipments =
                    (UndoRedo.data model.floor).equipments
                  equipmentsExcept target =
                    List.filter (\e -> idOf e /= idOf target) allEquipments
                in
                  case (findEquipmentById allEquipments lastTouchedId, primarySelectedEquipment model) of
                    (Just e, Just primary) ->
                      List.map idOf <|
                        primary :: (withinRange (primary, e) (equipmentsExcept primary)) --keep primary
                    _ -> [lastTouchedId]
              else
                if List.member lastTouchedId model.selectedEquipments
                then model.selectedEquipments
                else [lastTouchedId]
          , dragging = Just (lastTouchedId, (e.clientX, e.clientY))
          , selectorRect = Nothing
          }
      in
        (newModel, Effects.none)
    MouseUpOnCanvas e ->
      let
        model' =
          case model.dragging of
            Just (_, (x, y)) ->
              let
                shift = Scale.screenToImageForPosition model.scale (e.clientX - x, e.clientY - y)
              in
                if shift /= (0, 0) then
                  { model |
                    floor = UndoRedo.commit model.floor (Move model.selectedEquipments model.gridSize shift)
                  }
                else
                  model
            _ -> model
        newModel =
          { model' |
            dragging = Nothing
          , selectedEquipments =
              if e.ctrlKey
              then
                model.selectedEquipments
              else
                case model.dragging of
                  Just (id, (startX, startY)) ->
                    if e.clientX == startX && e.clientY == startY
                    then (if e.shiftKey then model.selectedEquipments else [id])
                    else model.selectedEquipments
                  _ -> model.selectedEquipments
          , selectorRect =
              case model.selectorRect of
                Just (rect, _) -> Just (rect, False)
                Nothing -> Nothing
          , shiftOffsetPrevScreenPos = Nothing
          }
      in
        (newModel, Effects.none)
    MouseDownOnCanvas e ->
      let
        model' =
          case model.editingEquipment of
            Just (id, name) ->
              { model |
                floor = UndoRedo.commit model.floor (ChangeName id name)
              }
            Nothing -> model
        newModel =
          { model' |
            selectedEquipments = []
          , selectorRect =
              let
                (x,y) = fitToGrid model.gridSize <|
                  Scale.screenToImageForPosition model.scale (e.layerX, e.layerY)
              in
                Just ((x, y, model.gridSize, model.gridSize), True)
          , editingEquipment = Nothing
          , contextMenu = NoContextMenu
          , shiftOffsetPrevScreenPos = Just (e.clientX, e.clientY)
          }
      in
        (newModel, Effects.none)
    StartEditEquipment id e ->
      case findEquipmentById (UndoRedo.data model.floor).equipments id of
        Just (Desk id (x, y, w, h) color name) ->
          let
            newModel =
              { model |
                editingEquipment = Just (id, name)
              }
          in
            (newModel, focusEffect "name-input")
        Nothing ->
          (model, Effects.none)
    SelectColor color e ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (ChangeColor model.selectedEquipments color)
          }
      in
        (newModel, Effects.none)
    InputName id name ->
      let
        newModel =
          { model |
            editingEquipment =
              case model.editingEquipment of
                Just (id', name') ->
                  if id == id' then
                    Just (id, name)
                  else
                    Just (id', name')
                Nothing -> Nothing
          }
      in
        (newModel, Effects.none)
    KeydownOnNameInput e ->
      let
        (newModel, effects) =
          if e.keyCode == 13 && not e.ctrlKey then
            let
              newModel =
                case model.editingEquipment of
                  Just (id, name) ->
                    let
                      allEquipments = (UndoRedo.data model.floor).equipments
                      editingEquipment =
                        case findEquipmentById allEquipments id of
                          Just equipment ->
                            let
                              island' =
                                island
                                  [equipment]
                                  (List.filter (\e -> (idOf e) /= id) allEquipments)
                            in
                              case EquipmentsOperation.nearest EquipmentsOperation.Down equipment island' of
                                Just equipment -> Just (idOf equipment, nameOf equipment)
                                Nothing -> Nothing
                          Nothing -> Nothing
                    in
                      { model |
                        floor = UndoRedo.commit model.floor (ChangeName id name) --TODO if name really changed
                      , editingEquipment = editingEquipment
                      }
                  Nothing ->
                    model
            in
              (newModel, Effects.none)
          else if e.keyCode == 13 then
            let
              newModel =
                { model |
                  editingEquipment =
                    case model.editingEquipment of
                      Just (id, name) -> Just (id, name ++ "\n")
                      Nothing -> Nothing
                }
            in
              (newModel, Effects.none)
          else
            (model, Effects.none)
      in
        (newModel, effects)
    ShowContextMenuOnEquipment id e ->
      let
        newModel =
          { model |
            contextMenu = Equipment (e.clientX, e.clientY) id
          }
      in
        (newModel, Effects.none)
    SelectIsland id e ->
      let
        newModel =
          case findEquipmentById (UndoRedo.data model.floor).equipments id of
            Just equipment ->
              let
                island' =
                  island
                    [equipment]
                    (List.filter (\e -> (idOf e) /= id)
                    (UndoRedo.data model.floor).equipments)
              in
                { model |
                  selectedEquipments = List.map idOf island'
                , contextMenu = NoContextMenu
                }
            Nothing ->
              model
      in
        (newModel, Effects.none)
    KeysAction action ->
      let
        model' =
          { model | keys = Keys.update action model.keys }
      in
        updateByKeyAction action model'
    MouseWheel e ->
      let
        newScale =
            if e.value < 0 then
              Scale.update Scale.ScaleUp model.scale
            else
              Scale.update Scale.ScaleDown model.scale
        ratio =
          Scale.ratio model.scale newScale
        (offsetX, offsetY) =
          model.offset
        newOffset =
          let
            x = Scale.screenToImage model.scale e.clientX
            y = Scale.screenToImage model.scale (e.clientY - 37) --TODO header hight
          in
          ( floor (toFloat (x - floor (ratio * (toFloat (x - offsetX)))) / ratio)
          , floor (toFloat (y - floor (ratio * (toFloat (y - offsetY)))) / ratio)
          )
        newModel =
          { model |
            scale = newScale
          , offset = newOffset
          }
      in
        (newModel, Effects.none)
    WindowDimensions (w, h) ->
      let
        newModel =
          { model | windowDimensions = (w, h) }
      in
        (newModel, Effects.none)
    ChangeMode mode ->
      let
        newModel =
          { model | editMode = mode }
      in
        (newModel, Effects.none)
    LoadFile fileList ->
      let
        task =
          (readFirstAsDataURL fileList)
          `Task.andThen` (\dataURL -> Task.succeed (GotDataURL dataURL))
          `Task.onError` (\error -> Task.succeed NoOp)
        effects = Effects.task task
      in
        (model, effects)
    GotDataURL dataURL ->
      let
        newModel =
          { model | floor = UndoRedo.commit model.floor (ChangeImage dataURL) }
      in
        (newModel, Effects.none)


updateByKeyAction : Keys.Action -> Model -> (Model, Effects Action)
updateByKeyAction action model =
  case (model.keys.ctrl, action) of
    (True, KeyC True) ->
      let
        newModel =
          { model |
            copiedEquipments = selectedEquipments model
          }
      in
        (newModel, Effects.none)
    (True, KeyV True) ->
      let
        base =
          case model.selectorRect of
            Just ((x, y, w, h), _) ->
              (x, y)
            Nothing -> (0, 0) --TODO
        (copiedIdsWithNewIds, newSeed) =
          IdGenerator.zipWithNewIds model.seed model.copiedEquipments
        model' =
          { model |
            floor = UndoRedo.commit model.floor (Paste copiedIdsWithNewIds base)
          , seed = newSeed
          }
        selected = List.map snd copiedIdsWithNewIds
        newModel =
          { model' |
            selectedEquipments = selected
          , selectorRect = Nothing
          }
      in
        (newModel, Effects.none)
    (True, KeyX True) ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (Delete model.selectedEquipments)
          , copiedEquipments = selectedEquipments model
          , selectedEquipments = []
          }
      in
        (newModel, Effects.none)
    (True, KeyY) ->
      let
        newModel =
          { model |
            floor = UndoRedo.redo model.floor
          }
      in
        (newModel, Effects.none)
    (True, KeyZ) ->
      let
        newModel =
          { model |
            floor = UndoRedo.undo model.floor
          }
      in
        (newModel, Effects.none)
    (_, KeyUpArrow) ->
      let
        newModel =
          shiftSelectionToward EquipmentsOperation.Up model
      in
        (newModel, Effects.none)
    (_, KeyDownArrow) ->
      let
        newModel =
          shiftSelectionToward EquipmentsOperation.Down model
      in
        (newModel, Effects.none)
    (_, KeyLeftArrow) ->
      let
        newModel =
          shiftSelectionToward EquipmentsOperation.Left model
      in
        (newModel, Effects.none)
    (_, KeyRightArrow) ->
      let
        newModel =
          shiftSelectionToward EquipmentsOperation.Right model
      in
        (newModel, Effects.none)
    (_, KeyDel True) ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (Delete model.selectedEquipments)
          }
      in
        (newModel, Effects.none)
    _ ->
      (model, Effects.none)

shiftSelectionToward : EquipmentsOperation.Direction -> Model -> Model
shiftSelectionToward direction model =
  let
    floor = UndoRedo.data model.floor
    selected = selectedEquipments model
  in
    case selected of
      primary :: tail ->
        let
          toBeSelected =
            if model.keys.shift then
              List.map idOf <|
                expandOrShrink direction primary selected floor.equipments
            else
              case nearest direction primary floor.equipments of
                Just e ->
                  let
                    newEquipments = [e]
                  in
                    List.map idOf newEquipments
                _ -> model.selectedEquipments
        in
          { model |
            selectedEquipments = toBeSelected
          }
      _ -> model


focusEffect : String -> Effects Action
focusEffect id =
  let
    task =
      (HtmlUtil.focus id)
        `Task.andThen` (\_ -> Task.succeed NoOp)
        `Task.onError` (\error -> Task.succeed NoOp)
  in
    Effects.task task

blurEffect : String -> Effects Action
blurEffect id =
  let
    task =
      (HtmlUtil.blur id)
        `Task.andThen` (\_ -> Task.succeed NoOp)
        `Task.onError` (\error -> Task.succeed NoOp)
  in
    Effects.task task

updateFloorByCommit : Commit -> Floor -> Floor
updateFloorByCommit commit floor =
  case commit of
    Move ids gridSize (dx, dy) ->
      setEquipments
        floor
        (moveEquipments gridSize (dx, dy) ids floor.equipments)
    Paste copiedWithNewIds (baseX, baseY) ->
      setEquipments
        floor
        (floor.equipments ++ (pasteEquipments (baseX, baseY) copiedWithNewIds floor.equipments))
    Delete ids ->
      setEquipments
        floor
        (List.filter (\equipment -> not (List.member (idOf equipment) ids)) floor.equipments)
    ChangeColor ids color ->
      let
        newEquipments =
          partiallyChange (changeColor color) ids floor.equipments
      in
        setEquipments floor newEquipments
    ChangeName id name ->
      setEquipments
        floor
        (commitInputName (id, name) floor.equipments)
    ChangeImage dataURL ->
      setImage dataURL floor


setEquipments : Floor -> List Equipment -> Floor
setEquipments floor equipments =
  { floor |
    equipments = equipments
  }

setImage : String -> Floor -> Floor
setImage dataURL floor =
  let
    (width, height) = getWidthAndHeightOfImage dataURL
  in
    { floor |
      width = width
    , height = height
    , dataURL = Just dataURL
    }

isSelected : Model -> Equipment -> Bool
isSelected model equipment =
  List.member (idOf equipment) model.selectedEquipments

primarySelectedEquipment : Model -> Maybe Equipment
primarySelectedEquipment model =
  case model.selectedEquipments of
    head :: _ ->
      findEquipmentById (UndoRedo.data model.floor).equipments head
    _ -> Nothing

selectedEquipments : Model -> List Equipment
selectedEquipments model =
  List.filterMap (\id ->
    findEquipmentById (UndoRedo.data model.floor).equipments id
  ) model.selectedEquipments

colorProperty : Model -> Maybe String
colorProperty model =
  let
    selected = selectedEquipments model
  in
    case List.head selected of
      Just (Desk _ _ firstColor _) ->
        List.foldl (\(Desk _ _ color _) maybeColor ->
          case maybeColor of
            Just color_ ->
              if color == color_ then Just color else Nothing
            Nothing -> Nothing
        ) (Just firstColor) selected
      Nothing -> Nothing


--