module View.View(view) where

import Html exposing (..)
import Html.Attributes exposing (..)
-- import Html.Lazy exposing (..)
import Maybe
import Signal exposing (Address, forwardTo)
import View.Styles as Styles
import View.Icons as Icons
-- import Debug

import Util.UndoRedo as UndoRedo
import Util.HtmlUtil exposing (..)
import Floor
import Equipments exposing (..)
import Model exposing (..)
import Scale
import EquipmentsOperation exposing (..)
import Util.ListUtil exposing (..)
import Prototypes exposing (Prototype, StampCandidate)



headerView : Address Action -> Model -> Html
headerView address model =
  header
    [ style Styles.header
    , mouseDownDefence address NoOp ]
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
        [ contextMenuItemView address (SelectIsland id) "Select Island"
        , contextMenuItemView address (always <| RegisterPrototype id) "Register as stamp"
        , contextMenuItemView address (always <| Rotate id) "Rotate"
        ]

contextMenuItemView : Address Action -> (MouseEvent -> Action) -> String -> Html
contextMenuItemView address action text' =
  div
    [ class "hovarable"
    , style Styles.contextMenuItem
    , onMouseDown' (forwardTo address action)
    ]
    [ text text' ]


equipmentView : Address Action -> Model -> Maybe ((Int, Int), (Int, Int)) -> Bool -> Bool -> Equipment -> Bool -> Bool -> Html
equipmentView address model moving selected alpha equipment contextMenuDisabled disableTransition =
  case equipment of
    Desk id (left, top, width, height) color name ->
      let
        movingBool = moving /= Nothing
        (x, y) =
          case moving of
            Just ((startX, startY), (x, y)) ->
              let
                (dx, dy) = Scale.screenToImageForPosition model.scale ((x - startX), (y - startY))
              in
                fitToGrid model.gridSize (left + dx, top + dy)
            _ -> (left, top)
        contextMenu =
          if contextMenuDisabled then
            []
          else
            [ onContextMenu' (forwardTo address (ShowContextMenuOnEquipment id)) ]
        eventHandlers =
          contextMenu ++
            [ onMouseDown' (forwardTo address (MouseDownOnEquipment id))
            , onDblClick' (forwardTo address (StartEditEquipment id))
            ]
      in
        equipmentView'
          (id ++ toString movingBool)
          (x, y, width, height)
          color
          name
          selected
          alpha
          eventHandlers
          model.scale
          disableTransition

equipmentView' : String -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> List Html.Attribute -> Scale.Model -> Bool -> Html
equipmentView' key' rect color name selected alpha eventHandlers scale disableTransition =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect
    styles =
      Styles.desk screenRect color selected alpha ++
        [("display", "table")] ++
        Styles.transition disableTransition
  in
    div
      ( eventHandlers ++ [ key key', style styles ] )
      [ equipmentLabelView scale disableTransition name
      ]

equipmentLabelView : Scale.Model -> Bool -> String -> Html
equipmentLabelView scale disableTransition name =
  let
    styles =
      Styles.nameLabel (1.0 / (toFloat <| Scale.screenToImage scale 1)) ++  --TODO
        Styles.transition disableTransition
  in
    pre
      [ style styles ]
      [ text name ]



transitionDisabled : Model -> Bool
transitionDisabled model =
  not model.scaling

nameInputView : Address Action -> Model -> Html
nameInputView address model =
  case model.editingEquipment of
    Just (id, name) ->
      case findEquipmentById (UndoRedo.data model.floor).equipments id of
        Just (Desk id rect color _) ->
          let
            styles =
              Styles.deskInput (Scale.imageToScreenForRect model.scale rect) ++
              Styles.transition (transitionDisabled model)
          in
            textarea
              ([ Html.Attributes.id "name-input"
              , style styles
              ] ++ (inputAttributes address (InputName id) KeydownOnNameInput name True))
              [text name]
        Nothing -> text ""
    Nothing ->
      text ""

inputAttributes : Address Action -> (String -> Action) -> (KeyboardEvent -> Action) -> String -> Bool -> List Attribute
inputAttributes address toInputAction toKeydownAction value' defence =
  [ onInput' (forwardTo address toInputAction) -- TODO cannot input japanese
  , onKeyDown'' (forwardTo address toKeydownAction)
  , value value'
  ] ++ (if defence then [onMouseDown' (forwardTo address (always NoOp))] else [])

mainView : Address Action -> Model -> Html
mainView address model =
  let
    (windowWidth, windowHeight) = model.windowDimensions
    height = windowHeight - Styles.headerHeight
  in
    main' [ style (Styles.flex ++ [ ("height", toString height ++ "px")]) ]
      [ canvasContainerView address model
      , subView address model
      ]

subView : Address Action -> Model -> Html
subView address model =
  div
    [ style (Styles.subMenu)
    -- , mouseDownDefence address NoOp
    ]
    [ card <| penView address model
    , card <| propertyView address model
    , card <| floorView address model
    , card <| debugView address model
    ]

card : List Html -> Html
card children =
  div
    [ {-style Styles.card-}
    style [("margin-bottom", "20px"), ("padding", "20px")]
    ] children

penView : Address Action -> Model -> List Html
penView address model =
  let
    prototypes =
      Prototypes.prototypes model.prototypes
  in
    [ modeSelectionView address model
    , prototypePreviewView address prototypes (model.editMode == Stamp)
    ]

floorNameInputView : Address Action -> Model -> Html
floorNameInputView address model =
  let
    floorNameLabel = label [ style Styles.floorNameLabel ] [ text "Name" ]
    nameInput =
      input
      ([ Html.Attributes.id "floor-name-input"
      , type' "text"
      , style Styles.floorNameInput
      ] ++ (inputAttributes address InputFloorName (always NoOp) (UndoRedo.data model.floor).name False))
      []
  in
    div [] [ floorNameLabel, nameInput ]

floorRealSizeInputView : Address Action -> Model -> Html
floorRealSizeInputView address model =
  let
    floor = UndoRedo.data model.floor
    useReal = True--TODO
    widthInput =
      input
      ([ Html.Attributes.id "floor-real-width-input"
      , type' "text"
      , disabled (not useReal)
      , style Styles.realSizeInput
      ] ++ (inputAttributes address InputFloorRealWidth (always NoOp) (model.inputFloorRealWidth) False))
      []
    heightInput =
      input
      ([ Html.Attributes.id "floor-real-height-input"
      , type' "text"
      , disabled (not useReal)
      , style Styles.realSizeInput
      ] ++ (inputAttributes address InputFloorRealHeight (always NoOp) (model.inputFloorRealHeight) False))
      []
    widthLabel = label [ style Styles.widthHeightLabel ] [ text "Width(m)" ]
    heightLabel = label [ style Styles.widthHeightLabel ] [ text "Height(m)" ]
  in
    div [] [widthLabel, widthInput, heightLabel, heightInput ]


modeSelectionView : Address Action -> Model -> Html
modeSelectionView address model =
  let
    widthStyle = [("width", "80px")]
    selection =
      div
        [ style (Styles.selection (model.editMode == Select) ++ widthStyle)
        , onClick' (forwardTo address (always <| ChangeMode Select))
        ]
        [ Icons.selectMode (model.editMode == Select) ]
    pen =
      div
        [ style (Styles.selection (model.editMode == Pen) ++ widthStyle)
        , onClick' (forwardTo address (always <| ChangeMode Pen))
        ]
        [ Icons.penMode (model.editMode == Pen) ]
    stamp =
      div
        [ style (Styles.selection (model.editMode == Stamp) ++ widthStyle)
        , onClick' (forwardTo address (always <| ChangeMode Stamp))
        ]
        [ Icons.stampMode (model.editMode == Stamp) ]
  in
    div [ style (Styles.flex ++ [("margin-top", "10px")]) ] [selection, pen, stamp]

propertyView : Address Action -> Model -> List Html
propertyView address model =
    [ text "Properties"
    , colorPropertyView address model
    ]

debugView : Address Action -> Model -> List Html
debugView address model =
    [ text (toString <| List.map idOf <| model.copiedEquipments)
    , br [] []
    , text (toString model.keys.ctrl)
    , br [] []
    , text (toString model.editingEquipment)
    , br [] []
    ]

canvasContainerView : Address Action -> Model -> Html
canvasContainerView address model =
  div
    [ style (Styles.canvasContainer ++
      ( if model.editMode == Stamp then
          [] -- [("cursor", "none")]
        else
          []
      ))
    , onMouseMove' (forwardTo address MoveOnCanvas)
    , onMouseDown' (forwardTo address (MouseDownOnCanvas))
    , onMouseUp' (forwardTo address (MouseUpOnCanvas))
    , onMouseEnter' (forwardTo address (always EnterCanvas))
    , onMouseLeave' (forwardTo address (always LeaveCanvas))
    , onMouseWheel address MouseWheel
    ]
    [ canvasView address model
    ]

canvasView : Address Action -> Model -> Html
canvasView address model =
  let
    floor = UndoRedo.data model.floor
    disableTransition = transitionDisabled model

    isDragged equipment =
      (case model.draggingContext of
        MoveEquipment _ _ -> True
        _ -> False
      ) && List.member (idOf equipment) model.selectedEquipments

    nonDraggingEquipments =
      List.map
        (\equipment ->
          equipmentView
            address
            model
            Nothing
            (isSelected model equipment)
            (isDragged equipment)
            equipment
            model.keys.ctrl
            disableTransition)
        floor.equipments

    draggingEquipments =
      if (case model.draggingContext of
          MoveEquipment _ _ -> True
          _ -> False
        )
      then
        let
          equipments = List.filter isDragged floor.equipments
          (x, y) = model.pos
          moving =
            case model.draggingContext of
              MoveEquipment _ (startX, startY) -> Just ((startX, startY), (x, y))
              _ -> Nothing
        in
          List.map
            (\equipment ->
              equipmentView
                address
                model
                moving
                (isSelected model equipment)
                False
                equipment
                model.keys.ctrl
                disableTransition
            )
            equipments
      else []

    equipments =
      draggingEquipments ++ nonDraggingEquipments

    selectorRect =
      case (model.editMode, model.selectorRect) of
        (Select, Just rect) ->
          div [style (Styles.selectorRect (Scale.imageToScreenForRect model.scale rect) ++ Styles.transition disableTransition )] []
        _ -> text ""

    temporaryStamps' = temporaryStampsView model
    temporaryPen' =
      case model.draggingContext of
        PenFromScreenPos (x, y) ->
          temporaryPenView model (x, y)
        _ -> text ""

    (offsetX, offsetY) = model.offset

    rect =
      Scale.imageToScreenForRect
        model.scale
        (offsetX, offsetY, Floor.width floor, Floor.height floor)

    image =
      img
        [ style [("width", "100%"), ("height", "100%")]
        , src (Maybe.withDefault "" (Floor.src floor))
        ] []
  in
    div
      [ style (Styles.canvasView rect ++ Styles.transition disableTransition)
      ]
      ((image :: (nameInputView address model) :: (selectorRect :: equipments)) ++ [temporaryPen'] ++ temporaryStamps')

prototypePreviewView : Address Action -> List (Prototype, Bool) -> Bool -> Html
prototypePreviewView address prototypes stampMode =
  let
    width = 238 -- TODO
    height = 238 -- TODO
    each index (prototype, selected) =
      let
        (_, _, _, (w, h)) = prototype
        left = width // 2 - w // 2
        top = height // 2 - h // 2
      in
        temporaryStampView Scale.init False (prototype, (left + index * width, top))
    selectedIndex =
      Maybe.withDefault 0 <|
      List.head <|
      List.filterMap (\((prototype, selected), index) -> if selected then Just index else Nothing) <|
      zipWithIndex prototypes
    buttons =
      List.map (\label ->
        let
          position = (if label == "<" then "left" else "right", "3px")
        in
          div
            [ style (position :: Styles.prototypePreviewScroll)
            , onClick' (forwardTo address (always <| if label == "<" then PrototypesAction Prototypes.prev else PrototypesAction Prototypes.next))
            ]
            [ text label ]
        )
      ( (if selectedIndex > 0 then ["<"] else []) ++
        (if selectedIndex < List.length prototypes - 1 then [">"] else [])
      )

    inner =
      div
        [ style (Styles.prototypePreviewViewInner selectedIndex) ]
        (List.indexedMap each prototypes)
  in
    div
      [ style (Styles.prototypePreviewView stampMode) ]
      ( inner :: buttons )

temporaryStampView : Scale.Model -> Bool -> StampCandidate -> Html
temporaryStampView scale selected ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top)) =
    equipmentView'
      ("temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString deskWidth ++ "_" ++ toString deskHeight)
      (left, top, deskWidth, deskHeight)
      color
      name --name
      selected
      False -- alpha
      [] -- eventHandlers
      scale
      True -- disableTransition

temporaryPenView : Model -> (Int, Int) -> Html
temporaryPenView model from =
  case temporaryPen model from of
    Just (color, name, (left, top, width, height)) ->
      equipmentView'
        ("temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString width ++ "_" ++ toString height)
        (left, top, width, height)
        color
        name --name
        False -- selected
        False -- alpha
        [] -- eventHandlers
        model.scale
        True -- disableTransition
    Nothing ->
      text ""

temporaryStampsView : Model -> List Html
temporaryStampsView model =
  List.map
    (temporaryStampView model.scale False)
    (stampCandidates model)

colorPropertyView : Address Action -> Model -> Html
colorPropertyView address model =
  let
    match color =
      case colorProperty (selectedEquipments model) of
        Just c -> color == c
        Nothing -> False
    viewForEach color =
      li
        [ style (Styles.colorProperty color (match color))
        , onMouseDown' (forwardTo address (SelectColor color))
        ]
        []
  in
    ul [ style (Styles.ul ++ [("display", "flex")]) ]
      (List.map viewForEach model.colorPalette)

publishButtonView : Address Action -> Model -> Html
publishButtonView address model =
  button
    [ onClick' (forwardTo address (always Publish))
    , style Styles.publishButton ]
    [ text "Publish" ]

floorView : Address Action -> Model -> List Html
floorView address model =
    [ fileLoadButton (forwardTo address LoadFile) Styles.imageLoadButton "Load Image"
    , floorNameInputView address model
    , floorRealSizeInputView address model
    , publishButtonView address model
    ]

view : Address Action -> Model -> Html
view address model =
  div
    []
    [ headerView address model
    , mainView address model
    , contextMenuView address model
    ]

--
