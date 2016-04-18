module Model (..) where

import Maybe
import Signal exposing (Signal, Address, forwardTo)
import Task
import Effects exposing (Effects)
import Debug
import Window

import Util.UndoRedo as UndoRedo
import Util.Keys as Keys exposing (..)
import Util.HtmlUtil as HtmlUtil exposing (..)
import Util.EffectsUtil as EffectsUtil exposing (..)
import Util.IdGenerator as IdGenerator exposing (Seed)

import Equipments exposing (..)
import EquipmentsOperation exposing (..)
import Scale
import API
import Prototypes exposing (..)
import Floor exposing (Model, setEquipments, setImage, equipments, addEquipments)

type alias Floor = Floor.Model

type alias Commit = Floor.Action

type alias Model =
  { seed : Seed
  , pos : Maybe (Int, Int)
  , draggingContext : DraggingContext
  , selectedEquipments : List Id
  , copiedEquipments : List Equipment
  , editingEquipment : Maybe (Id, String)
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , keys : Keys.Model
  , editMode : EditMode
  , colorPalette : List String
  , contextMenu : ContextMenu
  , floor : UndoRedo.Model Floor Commit
  , windowDimensions : (Int, Int)
  , scale : Scale.Model
  , offset : (Int, Int)
  , scaling : Bool
  , prototypes : Prototypes.Model
  , errors : List Error
  }

type Error =
    APIError API.Error
  | HtmlError HtmlUtil.Error

type ContextMenu =
    NoContextMenu
  | Equipment (Int, Int) Id

type EditMode = Select | Pen | Stamp

type DraggingContext =
    None
  | MoveEquipment Id (Int, Int)
  | Selector
  | ShiftOffsetPrevScreenPos (Int, Int)
  | StampScreenPos (Int, Int)

inputs : List (Signal Action)
inputs =
  (List.map (Signal.map KeysAction) Keys.inputs) ++
  [Signal.map WindowDimensions (Window.dimensions)]

gridSize : Int
gridSize = 8 -- 2^N

init : (Int, Int) -> (Model, Effects Action)
init initialSize =
  (
    { seed = IdGenerator.init
    , pos = Nothing
    , draggingContext = None
    , selectedEquipments = []
    , copiedEquipments = []
    , editingEquipment = Nothing
    , gridSize = gridSize
    , selectorRect = Nothing
    , keys = Keys.init
    , editMode = Select
    , colorPalette = ["#ed9", "#b8f", "#fa9", "#8bd", "#af6", "#6df"] --TODO
    , contextMenu = NoContextMenu
    , floor = UndoRedo.init { data = Floor.init, update = Floor.update }
    , windowDimensions = initialSize
    , scale = Scale.init
    , offset = (35, 35)
    , scaling = False
    , prototypes = Prototypes.init
    , errors = []
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
  | ScaleEnd
  | PrototypesAction Prototypes.Action
  | RegisterPrototype Id
  | Error Error

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
        model' =
          { model |
            pos = Just (e.clientX, e.clientY - 37)
          }
        newModel =
          case model.draggingContext of
            ShiftOffsetPrevScreenPos (prevX, prevY) ->
              let
                (x, y) = (e.clientX, e.clientY - 37)
              in
                { model' |
                  draggingContext =
                    ShiftOffsetPrevScreenPos (x, y)
                , offset =
                    let
                      (offsetX, offsetY) = model.offset
                      (dx, dy) =
                        ((x - prevX), (y - prevY))
                    in
                      ( offsetX + Scale.screenToImage model.scale dx
                      , offsetY + Scale.screenToImage model.scale dy
                      )
                }
            _ -> model'
      in
        (newModel, Effects.none)
    EnterCanvas ->
      (model, Effects.none)
    LeaveCanvas ->
      let
        newModel =
          { model |
              draggingContext =
                case model.draggingContext of
                  ShiftOffsetPrevScreenPos _ -> None
                  _ -> model.draggingContext
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
          , draggingContext = MoveEquipment lastTouchedId (e.clientX, e.clientY - 37)
          , selectorRect = Nothing
          }
      in
        (newModel, Effects.none)
    MouseUpOnCanvas e ->
      let
        (model', effects) =
          case model.draggingContext of
            MoveEquipment id (x, y) ->
              ( updateByMoveEquipmentEnd id (x, y) (e.clientX, e.clientY - 37) e.ctrlKey e.shiftKey model
              , Effects.none)
            Selector ->
              ({ model |
                selectorRect =
                  case model.selectorRect of
                    Just (x, y, _, _) ->
                      let
                        (w, h) =
                          ( Scale.screenToImage model.scale e.clientX - x
                          , Scale.screenToImage model.scale e.clientY - 37 - y
                          )
                      in
                        Just (x, y, w, h)
                    _ -> model.selectorRect
              }, Effects.none)
            StampScreenPos _ ->
              let
                (candidatesWithNewIds, newSeed) =
                  IdGenerator.zipWithNewIds model.seed (stampCandidates model)
                effects =
                  fromTask (Error << APIError) (always NoOp) (API.saveFloor (UndoRedo.data model.floor))
                candidatesWithNewIds' =
                  List.map
                    (\(((_, color, name, (w, h)), (x, y)), newId) -> (newId, (x, y, w, h), color, name))
                    candidatesWithNewIds
              in
                ({ model |
                  seed = newSeed
                , floor = UndoRedo.commit model.floor (Floor.create candidatesWithNewIds')
                }, effects)
            _ -> (model, Effects.none)
        newModel =
          { model' |
            draggingContext = None
          }
      in
        (newModel, effects)
    MouseDownOnCanvas e ->
      let
        model' =
          case model.editingEquipment of
            Just (id, name) ->
              { model |
                floor = UndoRedo.commit model.floor (Floor.changeEquipmentName id name)
              }
            Nothing -> model

        selectorRect =
          case model.editMode of
            Select ->
              let
                (x, y) = fitToGrid model.gridSize <|
                  Scale.screenToImageForPosition model.scale (e.layerX, e.layerY)
              in
                Just (x, y, model.gridSize, model.gridSize)
            _ -> model.selectorRect

        draggingContext =
          case model.editMode of
            Stamp ->
              StampScreenPos (e.clientX, e.clientY - 37)
            Pen -> None -- TODO
            Select -> ShiftOffsetPrevScreenPos (e.clientX, e.clientY - 37)

        newModel =
          { model' |
            selectedEquipments = []
          , selectorRect = selectorRect
          , editingEquipment = Nothing
          , contextMenu = NoContextMenu
          , draggingContext = draggingContext
          }
      in
        (newModel, Effects.none)
    StartEditEquipment id e ->
      case findEquipmentById (UndoRedo.data model.floor).equipments id of
        Just e ->
          let
            newModel =
              { model |
                editingEquipment = Just (idOf e, nameOf e)
              , contextMenu = NoContextMenu
              }
          in
            (newModel, focusEffect "name-input")
        Nothing ->
          (model, Effects.none)
    SelectColor color e ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (Floor.changeEquipmentColor model.selectedEquipments color)
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
                        floor = UndoRedo.commit model.floor (Floor.changeEquipmentName id name) --TODO if name really changed
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
          , scaling = True
          }
        effects =
          fromTaskWithNoError (always ScaleEnd) (Task.sleep 200.0)
      in
        (newModel, effects)
    ScaleEnd ->
      let
        newModel =
          { model | scaling = False }
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
        effects =
          fromTask (Error << HtmlError) GotDataURL (readFirstAsDataURL fileList)
      in
        (model, effects)
    GotDataURL dataURL ->
      let
        newModel =
          { model | floor = UndoRedo.commit model.floor (Floor.changeImage dataURL) }
      in
        (newModel, Effects.none)
    PrototypesAction action ->
      let
        newModel =
          { model | prototypes = Prototypes.update action model.prototypes }
      in
        (newModel, Effects.none)
    RegisterPrototype id ->
      let
        equipment =
          findEquipmentById (UndoRedo.data model.floor).equipments id
        model' =
          { model |
            contextMenu = NoContextMenu
          }
        newModel =
          case equipment of
            Just e ->
              let
                (_, _, w, h) = rect e
                (newId, seed) = IdGenerator.new model.seed
                newPrototypes =
                  Prototypes.register (newId, colorOf e, nameOf e, (w, h)) model.prototypes
              in
                { model' |
                  seed = seed
                , prototypes = newPrototypes
                }
            Nothing ->
              model'
      in
        (newModel, Effects.none)
    Error e ->
      let
        newModel =
          { model | errors = e :: model.errors }
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
            Just (x, y, w, h) ->
              (x, y)
            Nothing -> (0, 0) --TODO
        (copiedIdsWithNewIds, newSeed) =
          IdGenerator.zipWithNewIds model.seed model.copiedEquipments
        model' =
          { model |
            floor = UndoRedo.commit model.floor (Floor.paste copiedIdsWithNewIds base)
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
            floor = UndoRedo.commit model.floor (Floor.delete model.selectedEquipments)
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
            floor = UndoRedo.commit model.floor (Floor.delete model.selectedEquipments)
          }
      in
        (newModel, Effects.none)
    _ ->
      (model, Effects.none)


updateByMoveEquipmentEnd : Id -> (Int, Int) -> (Int, Int) -> Bool -> Bool -> Model -> Model
updateByMoveEquipmentEnd id (x0, y0) (x1, y1) ctrlKey shiftKey model =
  let
    shift = Scale.screenToImageForPosition model.scale (x1 - x0, y1 - y0)
  in
    if shift /= (0, 0) then
      { model |
        floor = UndoRedo.commit model.floor (Floor.move model.selectedEquipments model.gridSize shift)
      }
    else if not ctrlKey && not shiftKey then
      { model |
        selectedEquipments = [id]
      }
    else
      model

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
  fromTask (Error << HtmlError) (always NoOp) (HtmlUtil.focus id)

blurEffect : String -> Effects Action
blurEffect id =
  fromTask (Error << HtmlError) (always NoOp) (HtmlUtil.blur id)

isSelected : Model -> Equipment -> Bool
isSelected model equipment =
  List.member (idOf equipment) model.selectedEquipments

primarySelectedEquipment : Model -> Maybe Equipment
primarySelectedEquipment model =
  case model.selectedEquipments of
    head :: _ ->
      findEquipmentById (equipments <| UndoRedo.data model.floor) head
    _ -> Nothing

selectedEquipments : Model -> List Equipment
selectedEquipments model =
  List.filterMap (\id ->
    findEquipmentById (UndoRedo.data model.floor).equipments id
  ) model.selectedEquipments

stampCandidates : Model -> List StampCandidate
stampCandidates model =
  case model.editMode of
    Stamp ->
      let
        prototype =
          selectedPrototype model.prototypes
        (prototypeId, color, name, deskSize) =
          prototype
        (offsetX, offsetY) = model.offset
        (x2, y2) =
          Maybe.withDefault (0, 0) model.pos
        (x2', y2') =
          ( Scale.screenToImage model.scale x2 - offsetX
          , Scale.screenToImage model.scale y2 - offsetY
          )
      in
        case model.draggingContext of
          StampScreenPos (x1, y1) ->
            let
              (x1', y1') =
                ( Scale.screenToImage model.scale x1 - offsetX
                , Scale.screenToImage model.scale y1 - offsetY
                )
            in
              stampCandidatesOnDragging model.gridSize prototype (x1', y1') (x2', y2')
          _ ->
            let
              (deskWidth, deskHeight) = deskSize
              (left, top) =
                fitToGrid model.gridSize (x2' - deskWidth // 2, y2' - deskHeight // 2)
            in
              [ ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top))
              ]
    _ -> []

--
