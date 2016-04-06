import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import StartApp
import Maybe
import Signal exposing (Signal, Address, forwardTo)
import Task
import Effects exposing (Effects)
import Styles
import Json.Decode exposing (Decoder, object2, object5, (:=), int, bool)
import Keyboard
import Char
import Debug
import Window

import UndoRedo
import HtmlUtil exposing (..)

app = StartApp.start
  { init = init
  , view = view
  , update = update
  , inputs =
    [ Signal.map KeyCtrl Keyboard.ctrl
    , Signal.map KeyDel (Keyboard.isDown 46)
    , Signal.map KeyC (Keyboard.isDown (Char.toCode 'C'))
    , Signal.map KeyV (Keyboard.isDown (Char.toCode 'V'))
    , Signal.map KeyX (Keyboard.isDown (Char.toCode 'X'))
    , Signal.map (\e ->
        if e.keyCode == (Char.toCode 'Y') then
          KeyY
        else if e.keyCode == (Char.toCode 'Z') then
          KeyZ
        else
          NoOp
      ) HtmlUtil.downs
    , Signal.map WindowDimensions (Window.dimensions)
    ]
  }

main : Signal Html
main = app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks

--

type alias Id = String
type alias FloorImage =
  { name: String
  , width: Int
  , height: Int
  }

type Equipment =
  Desk Id (Int, Int, Int, Int) String String -- id (x, y, width, height) color

type alias Floor =
  { name : String
  , equipments: List Equipment
  , image : Maybe FloorImage
  }

type alias Model =
  { idGen : Int
  , pos : Maybe (Int, Int)
  , dragging : Maybe (Id, (Int, Int))
  , selectedEquipments : List Id
  , copiedEquipments : List Id
  , editingEquipment : Maybe (Id, String)
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , ctrl : Bool
  , editMode : EditMode
  , colorPalette : List String
  , contextMenu : ContextMenu
  , floor : UndoRedo.Model Floor Commit
  , windowDimensions : (Int, Int)
  }

type ContextMenu =
    NoContextMenu
  | Equipment (Int, Int) Id

type EditMode = Selector | Pen

type Commit =
    Move (List Id) Int (Int, Int)
  | Paste (List Id) (Int, Int)
  | Delete (List Id)
  | ChangeColor (List Id) String
  | ChangeName Id String

init : (Model, Effects Action)
init =
  (
    { idGen = 0
    , pos = Nothing
    , dragging = Nothing
    , selectedEquipments = []
    , copiedEquipments = []
    , editingEquipment = Nothing
    , gridSize = 8 -- 2^N
    , selectorRect = Nothing
    , ctrl = False
    , editMode = Selector
    , colorPalette = ["#ed9", "#b8f", "#fa9", "#8bd", "#af6", "#6df"] --TODO
    , contextMenu = NoContextMenu
    , floor = UndoRedo.init { data = initFloor, update = updateFloorByCommit }
    , windowDimensions = (50000, 50000) -- TODO
    }
  , Effects.task (Task.succeed Init)
  )

--

type Action = NoOp
  | Init
  | MoveOnCanvas MouseEvent
  | EnterCanvas
  | LeaveCanvas
  | DragStart Id MouseEvent
  | DragEnd MouseEvent
  | MouseDownBackground MouseEvent
  | StartEditEquipment Id MouseEvent
  | KeyCtrl Bool
  | KeyDel Bool
  | KeyC Bool
  | KeyV Bool
  | KeyX Bool
  | KeyY
  | KeyZ
  | SelectColor String MouseEvent
  | InputName Id String
  | KeydownOnNameInput KeyboardEvent
  | ShowContextMenuOnEquipment Id MouseEvent
  | SelectIsland Id MouseEvent
  | WindowDimensions (Int, Int)

initFloor : Floor
initFloor =
  setEquipments
    { name = ""
    , equipments = []
    , image = Nothing
    }
    [ Desk "1" (8*5, 8*20, 8*8, 8*12) "#ed9" "John\nSmith"
    , Desk "2" (8*13, 8*20, 8*8, 8*12) "#8bd" "John\nSmith"
    , Desk "3" (8*5, 8*32, 8*8, 8*12) "#fa9" "John\nSmith"
    , Desk "4" (8*13, 8*32, 8*8, 8*12) "#b8f" "John\nSmith"
    ]

update : Action -> Model -> (Model, Effects Action)
update action model =
  case {--Debug.log "action"--} action of
    NoOp ->
      (model, Effects.none)
    Init ->
      (model, Effects.none) -- TODO fetch from server
    MoveOnCanvas e ->
      let
        newModel =
          { model |
            pos = Just (e.clientX, e.clientY)
          }
      in
        (newModel, Effects.none)
    EnterCanvas ->
      (model, Effects.none)
    LeaveCanvas ->
      (model, Effects.none)
    DragStart lastTouchedId e ->
      let
        newModel =
          { model |
            selectedEquipments =
              if e.ctrlKey
              then
                if List.member lastTouchedId model.selectedEquipments
                then List.filter ((/=) lastTouchedId) model.selectedEquipments
                else lastTouchedId :: model.selectedEquipments
              else
                if List.member lastTouchedId model.selectedEquipments
                then model.selectedEquipments
                else [lastTouchedId]
          , dragging = Just (lastTouchedId, (e.clientX, e.clientY))
          , selectorRect = Nothing
          }
      in
        (newModel, Effects.none)
    DragEnd e ->
      let
        model' =
          case model.dragging of
            Just (_, (x, y)) ->
              let
                shift = (e.clientX - x, e.clientY - y)
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
                    then [id]
                    else model.selectedEquipments
                  _ -> model.selectedEquipments
          }
      in
        (newModel, Effects.none)
    MouseDownBackground e ->
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
              let (x,y) = fitToGrid model.gridSize (e.layerX, e.layerY)
              in Just (x, y, model.gridSize, model.gridSize)
          , editingEquipment = Nothing
          , contextMenu = NoContextMenu
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

    KeyC down ->
      let
        newModel =
          if down && model.ctrl then
            { model |
              copiedEquipments = model.selectedEquipments
            }
          else model
      in
        (newModel, Effects.none)
    KeyV down ->
      let
        newModel =
          if down && model.ctrl then
            let
              base =
                case model.selectorRect of
                  Just (x, y, w, h) ->
                    (x, y)
                  Nothing -> (0, 0) --TODO
              newEquipments =
                pasteEquipments base model.copiedEquipments (UndoRedo.data model.floor).equipments
              model' =
                { model |
                  floor = UndoRedo.commit model.floor (Paste model.copiedEquipments base)
                }
              selected = List.map idOf newEquipments
            in
              { model' |
                selectedEquipments = selected
              , selectorRect = Nothing
              }
          else model
      in
        (newModel, Effects.none)
    KeyX down ->
      let
        newModel = model --TODO
      in
        (newModel, Effects.none)
    KeyY ->
      let
        newModel =
          { model |
            floor = UndoRedo.redo model.floor
          }
      in
        (newModel, Effects.none)
    KeyZ ->
      let
        newModel =
          { model |
            floor = UndoRedo.undo model.floor
          }
      in
        (newModel, Effects.none)
    KeyCtrl bool ->
      let
        newModel =
          { model |
            ctrl = bool
          }
      in
        (newModel, Effects.none)
    KeyDel bool ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (Delete model.selectedEquipments)
          }
      in
        (newModel, Effects.none)
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
                Just _ -> Just (id, name)
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
                      model' =
                        { model |
                          floor = UndoRedo.commit model.floor (ChangeName id name) --TODO if name really changed
                        }
                    in
                      { model' |
                        editingEquipment = Nothing --TODO next cell
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
                island' = island [equipment] (List.filter (\e -> (idOf e) /= id) (UndoRedo.data model.floor).equipments)
              in
                { model |
                  selectedEquipments = List.map idOf island'
                , contextMenu = NoContextMenu
                }
            Nothing ->
              model
      in
        (newModel, Effects.none)
    WindowDimensions (w, h) ->
      let
        newModel =
          { model | windowDimensions = (w, h) }
      in
        (newModel, Effects.none)

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

island : List Equipment -> List Equipment -> List Equipment
island current rest =
  let
    match (Desk id (x1, y1, w1, h1) _ _) =
      List.any (\(Desk id (x2, y2, w2, h2) _ _) ->
        (x1 <= x2+w2 && x2 <= x1+w1 && y1 <= y2+h2 && y2 <= y1+h1)
      ) current
    (newEquipments, rest') = List.partition match rest
  in
    if List.isEmpty newEquipments then
      current ++ newEquipments
    else
      island (current ++ newEquipments) rest'

updateFloorByCommit : Commit -> Floor -> Floor
updateFloorByCommit commit floor =
  case commit of
    Move ids gridSize (dx, dy) ->
      setEquipments
        floor
        (moveEquipments gridSize (dx, dy) ids floor.equipments)
    Paste ids (baseX, baseY) ->
      setEquipments
        floor
        (floor.equipments ++ (pasteEquipments (baseX, baseY) ids floor.equipments))
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


commitInputName : (Id, String) -> List Equipment -> List Equipment
commitInputName (id, name) equipments =
  partiallyChange (changeName name) [id] equipments


setEquipments : Floor -> List Equipment -> Floor
setEquipments floor equipments =
  { floor |
    equipments = equipments
  }

changeColor : String -> Equipment -> Equipment
changeColor color (Desk id rect _ name) = Desk id rect color name

changeName : String -> Equipment -> Equipment
changeName name (Desk id rect color _) = Desk id rect color name

idOf : Equipment -> Id
idOf (Desk id _ _ _) = id

pasteEquipments : (Int, Int) -> List Id -> List Equipment -> List Equipment
pasteEquipments (baseX, baseY) copied allEquipments =
  let
    toBeCopied =
        List.filter (\equipment ->
          List.member (idOf equipment) copied
        ) allEquipments

    (minX, minY) =
      List.foldl (\(Desk _ (x, y, w, h) color _) (minX, minY) -> (Basics.min minX x, Basics.min minY y)) (99999, 99999) toBeCopied

    newEquipments =
      List.map (\equipment ->
        case equipment of
          Desk id (x, y, width, height) color name ->
            let (newX, newY) = (baseX + (x - minX), baseY + (y - minY))
            in Desk (id ++ "x") (newX, newY, width, height) color name --TODO
      ) toBeCopied
  in
    newEquipments

partiallyChange : (Equipment -> Equipment) -> List Id -> List Equipment -> List Equipment
partiallyChange f ids equipments =
  List.map (\equipment ->
    case equipment of
      Desk id _ _ _ ->
        if List.member id ids
        then f equipment
        else equipment
  ) equipments

moveEquipments : Int -> (Int, Int) -> List Id -> List Equipment -> List Equipment
moveEquipments gridSize (dx, dy) ids equipments =
  partiallyChange (\(Desk id (x, y, width, height) color name) ->
    let (newX, newY) = fitToGrid gridSize (x + dx, y + dy)
    in Desk id (newX, newY, width, height) color name
  ) ids equipments

findBy : (a -> Bool) -> List a -> Maybe a
findBy f list =
  List.head (List.filter f list)

findEquipmentById : List Equipment -> Id -> Maybe Equipment
findEquipmentById equipments id =
  findBy (\equipment -> id == (idOf equipment)) equipments

isSelected : Model -> Equipment -> Bool
isSelected model equipment =
  List.member (idOf equipment) model.selectedEquipments

selectedEquipments : Model -> List Equipment
selectedEquipments model =
  List.filter
    (\equipment -> List.member (idOf equipment) model.selectedEquipments)
    (UndoRedo.data model.floor).equipments

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


fitToGrid : Int -> (Int, Int) -> (Int, Int)
fitToGrid gridSize (x, y) =
  (x // gridSize * gridSize, y // gridSize * gridSize)


--

headerView : Address Action -> Model -> Html
headerView address model =
  header [ style Styles.header ]
    [ h1 [ style Styles.h1 ] [text "Office Maker"]
    ]

contextMenuView : Address Action -> Model -> Html
contextMenuView address model =
  case model.contextMenu of
    NoContextMenu ->
      text ""
    Equipment (x, y) id ->
      div
        [ style (Styles.contextMenu (x, y) (fst model.windowDimensions, snd model.windowDimensions) 2)
        ] -- TODO
        [ div
            [ onMouseDown' (forwardTo address (SelectIsland id)) ]
            [ text "Select Island" ]
        , div [] [ text "" ] ]

equipmentView : Address Action -> Model -> Maybe ((Int, Int), (Int, Int)) -> Bool -> Bool -> Equipment -> Bool -> Html
equipmentView address model moving selected alpha equipment contextMenuDisabled =
  case equipment of
    Desk id (left, top, width, height) color name ->
      let
        moovingBool = toBool moving
        (x, y) =
          case moving of
            Just ((startX, startY), (x, y)) ->
              fitToGrid model.gridSize (left + (x - startX), top + (y - startY))
            _ -> (left, top)
      in
        equipmentView' address id (x, y, width, height) color name selected moovingBool alpha contextMenuDisabled

equipmentView' : Address Action -> Id -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> Bool -> Bool -> Html
equipmentView' address id (x, y, w, h) color name selected moving alpha contextMenuDisabled =
  let
    contextMenu =
      if contextMenuDisabled then
        []
      else
        [ onContextMenu' (forwardTo address (ShowContextMenuOnEquipment id)) ]
  in
    div
      (contextMenu ++ [ key (id ++ toString moving)
      , style (Styles.desk x y w h color selected alpha ++ [("display", "table")])
      , onMouseDown' (forwardTo address (DragStart id))
      , onDblClick' (forwardTo address (StartEditEquipment id))
      ])
      [ pre
        [ style
          [ ("display", "table-cell")
          , ("vertical-align", "middle")
          , ("text-align", "center")
          , ("position", "absolute")
           -- TODO vertical align
          ]
        ]
        [ text (toString (x, y) ++ "\n" ++ name)]]

nameInputView : Address Action -> Model -> Html
nameInputView address model =
  case model.editingEquipment of
    Just (id, name) ->
      case findEquipmentById (UndoRedo.data model.floor).equipments id of
        Just (Desk id (x, y, w, h) color _) ->
          textarea
            [ Html.Attributes.id "name-input"
            , style (Styles.deskInput x y w h)
            , onInput' (forwardTo address (InputName id))
            , onKeyDown' (forwardTo address (KeydownOnNameInput))
            , onMouseDown' (forwardTo address (always NoOp))
            , value name
            ]
            [text name]
        Nothing -> text ""
    Nothing ->
      text ""

mainView : Address Action -> Model -> Html
mainView address model =
  let
    isSelected' = isSelected model

    isDragged equipment =
      toBool(model.dragging) && List.member (idOf equipment) model.selectedEquipments

    nonDraggingEquipments =
      List.map
        (\equipment -> equipmentView address model Nothing (isSelected' equipment) (isDragged equipment) equipment model.ctrl)
        (UndoRedo.data model.floor).equipments

    draggingEquipments =
      if toBool(model.dragging)
      then
        let
          equipments = List.filter isDragged (UndoRedo.data model.floor).equipments
          moving =
            case (model.dragging, model.pos) of
              (Just (_, (startX, startY)), Just (x, y)) -> Just ((startX, startY), (x, y))
              _ -> Nothing
        in
          List.map
            (\equipment -> equipmentView address model moving (isSelected' equipment) False equipment model.ctrl)
            equipments
      else []

    equipments =
      draggingEquipments ++ nonDraggingEquipments

    selectorRect =
      case model.selectorRect of
        Just (x, y, w, h) ->
          div [style (Styles.selectorRect x y w h)] []
        Nothing -> text ""

  in
    main' [ style Styles.flex ]
      [ div
        [ style (Styles.flexMain ++ [("position", "relative")])
        , onMouseMove' (forwardTo address MoveOnCanvas)
        -- , onMouseEnter (forwardTo address (always EnterCanvas)) address
        -- , onMouseLeave (forwardTo address (always LeaveCanvas)) address
        ]
        [ text (toString model.copiedEquipments)
        , br [] []
        , text (toString model.ctrl)
        , br [] []
        -- , text (toString model.floor.cursor)
        -- , br [] []
        , div [] equipments
        , nameInputView address model
        , selectorRect
        ]
      , div
          [ style (Styles.subMenu) ]
          [ text "Color"
          , colorPropertyView address model]
      ]

colorPropertyView : Address Action -> Model -> Html
colorPropertyView address model =
  let
    match color =
      case colorProperty model of
        Just c -> color == c
        Nothing -> False
    viewForEach color =
      li
        [ style (Styles.colorProperty color (match color))
        , onMouseDown' (forwardTo address (SelectColor color)) ]
        []
  in
    ul [ style (Styles.ul ++ [("display", "flex")]) ]
      (List.map viewForEach model.colorPalette)

view : Address Action -> Model -> Html
view address model =
  div
    [ onMouseUp' (forwardTo address (DragEnd))
    , onMouseDown' (forwardTo address (MouseDownBackground))
    -- , onKeyPress' (forwardTo address (KeyPress))
    ]
    [ headerView address model
    , mainView address model
    , contextMenuView address model
    ]

--

toBool : Maybe a -> Bool
toBool maybe =
  case maybe of
    Just _ -> True
    Nothing -> False
