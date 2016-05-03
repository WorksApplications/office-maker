module View.View exposing(view) -- where

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
-- import Html.Lazy exposing (..)
import Maybe
import View.Styles as Styles
import View.Icons as Icons
import Header
-- import Debug

import Util.UndoRedo as UndoRedo
import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model exposing (..)
import Model.Floor as Floor
import Model.Equipments as Equipments exposing (..)
import Model.Scale as Scale
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Model.Prototypes as Prototypes exposing (Prototype, StampCandidate)

contextMenuView : Model -> Html Action
contextMenuView model =
  case model.contextMenu of
    NoContextMenu ->
      text ""
    Equipment (x, y) id ->
      div
        [ style (Styles.contextMenu (x, y + 37) (fst model.windowDimensions, snd model.windowDimensions) 2) -- TODO
        ] -- TODO
        [ contextMenuItemView (SelectIsland id) "Select Island"
        , contextMenuItemView (RegisterPrototype id) "Register as stamp"
        , contextMenuItemView (Rotate id) "Rotate"
        ]

contextMenuItemView : Action -> String -> Html Action
contextMenuItemView action text' =
  div
    [ class "hovarable"
    , style Styles.contextMenuItem
    , onMouseDown' action
    ]
    [ text text' ]


equipmentView : Model -> Maybe ((Int, Int), (Int, Int)) -> Bool -> Bool -> Equipment -> Bool -> Bool -> Html Action
equipmentView model moving selected alpha equipment contextMenuDisabled disableTransition =
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
            [ onContextMenu' (ShowContextMenuOnEquipment id) ]
        eventHandlers =
          contextMenu ++
            [ onMouseDown' (MouseDownOnEquipment id)
            , onDblClick' (StartEditEquipment id)
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

equipmentView' : String -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> List (Html.Attribute msg) -> Scale.Model -> Bool -> Html msg
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
      ( eventHandlers ++ [ {- key key', -} style styles ] )
      [ equipmentLabelView scale disableTransition name
      ]

equipmentLabelView : Scale.Model -> Bool -> String -> Html msg
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

nameInputView : Model -> Html Action
nameInputView model =
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
              ] ++ (inputAttributes (InputName id) KeydownOnNameInput name True))
              [text name]
        Nothing -> text ""
    Nothing ->
      text ""

inputAttributes : (String -> Action) -> (Int -> Action) -> String -> Bool -> List (Attribute Action)
inputAttributes toInputAction toKeydownAction value' defence =
  [ onInput' toInputAction -- TODO cannot input japanese
  , onKeyDown'' toKeydownAction
  , value value'
  ] ++ (if defence then [onMouseDown' NoOp] else [])

mainView : Model -> Html Action
mainView model =
  let
    (windowWidth, windowHeight) = model.windowDimensions
    height = windowHeight - Styles.headerHeight
  in
    main' [ style (Styles.flex ++ [ ("height", toString height ++ "px")]) ]
      [ canvasContainerView model
      , subView model
      ]

subView : Model -> Html Action
subView model =
  div
    [ style (Styles.subMenu)
    -- , mouseDownDefence address NoOp
    ]
    [ card <| penView model
    , card <| propertyView model
    , card <| floorView model
    , card <| debugView model
    ]

card : List (Html msg) -> Html msg
card children =
  div
    [ {-style Styles.card-}
    style [("margin-bottom", "20px"), ("padding", "20px")]
    ] children

penView : Model -> List (Html Action)
penView model =
  let
    prototypes =
      Prototypes.prototypes model.prototypes
  in
    [ modeSelectionView model
    , prototypePreviewView prototypes (model.editMode == Stamp)
    ]

floorNameInputView : Model -> Html Action
floorNameInputView model =
  let
    floorNameLabel = label [ style Styles.floorNameLabel ] [ text "Name" ]
    nameInput =
      input
      ([ Html.Attributes.id "floor-name-input"
      , type' "text"
      , style Styles.floorNameInput
      ] ++ (inputAttributes InputFloorName (always NoOp) (UndoRedo.data model.floor).name False))
      []
  in
    div [] [ floorNameLabel, nameInput ]

floorRealSizeInputView : Model -> Html Action
floorRealSizeInputView model =
  let
    floor = UndoRedo.data model.floor
    useReal = True--TODO
    widthInput =
      input
      ([ Html.Attributes.id "floor-real-width-input"
      , type' "text"
      , disabled (not useReal)
      , style Styles.realSizeInput
      ] ++ (inputAttributes InputFloorRealWidth (always NoOp) (model.inputFloorRealWidth) False))
      []
    heightInput =
      input
      ([ Html.Attributes.id "floor-real-height-input"
      , type' "text"
      , disabled (not useReal)
      , style Styles.realSizeInput
      ] ++ (inputAttributes InputFloorRealHeight (always NoOp) (model.inputFloorRealHeight) False))
      []
    widthLabel = label [ style Styles.widthHeightLabel ] [ text "Width(m)" ]
    heightLabel = label [ style Styles.widthHeightLabel ] [ text "Height(m)" ]
  in
    div [] [widthLabel, widthInput, heightLabel, heightInput ]


modeSelectionView : Model -> Html Action
modeSelectionView model =
  let
    widthStyle = [("width", "80px")]
    selection =
      div
        [ style (Styles.selection (model.editMode == Select) ++ widthStyle)
        , onClick' (ChangeMode Select)
        ]
        [ Icons.selectMode (model.editMode == Select) ]
    pen =
      div
        [ style (Styles.selection (model.editMode == Pen) ++ widthStyle)
        , onClick' (ChangeMode Pen)
        ]
        [ Icons.penMode (model.editMode == Pen) ]
    stamp =
      div
        [ style (Styles.selection (model.editMode == Stamp) ++ widthStyle)
        , onClick' (ChangeMode Stamp)
        ]
        [ Icons.stampMode (model.editMode == Stamp) ]
  in
    div [ style (Styles.flex ++ [("margin-top", "10px")]) ] [selection, pen, stamp]

propertyView : Model -> List (Html Action)
propertyView model =
    [ text "Properties"
    , colorPropertyView model
    ]

debugView : Model -> List (Html Action)
debugView model =
    [ text (toString <| List.map idOf <| model.copiedEquipments)
    , br [] []
    , text (toString model.keys.ctrl)
    , br [] []
    , text (toString model.editingEquipment)
    , br [] []
    ]

canvasContainerView : Model -> Html Action
canvasContainerView model =
  div
    [ style (Styles.canvasContainer ++
      ( if model.editMode == Stamp then
          [] -- [("cursor", "none")]
        else
          []
      ))
    , onMouseMove' MoveOnCanvas
    , onMouseDown' MouseDownOnCanvas
    , onMouseUp' MouseUpOnCanvas
    , onMouseEnter' EnterCanvas
    , onMouseLeave' LeaveCanvas
    , onMouseWheel MouseWheel
    ]
    [ canvasView model
    ]

canvasView : Model -> Html Action
canvasView model =
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
      ((image :: (nameInputView model) :: (selectorRect :: equipments)) ++ [temporaryPen'] ++ temporaryStamps')

prototypePreviewView : List (Prototype, Bool) -> Bool -> Html Action
prototypePreviewView prototypes stampMode =
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
            , onClick' (if label == "<" then PrototypesAction Prototypes.prev else PrototypesAction Prototypes.next)
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

temporaryStampView : Scale.Model -> Bool -> StampCandidate -> Html msg
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

temporaryPenView : Model -> (Int, Int) -> Html msg
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

temporaryStampsView : Model -> List (Html msg)
temporaryStampsView model =
  List.map
    (temporaryStampView model.scale False)
    (stampCandidates model)

colorPropertyView : Model -> Html Action
colorPropertyView model =
  let
    match color =
      case colorProperty (selectedEquipments model) of
        Just c -> color == c
        Nothing -> False
    viewForEach color =
      li
        [ style (Styles.colorProperty color (match color))
        , onMouseDown' (SelectColor color)
        ]
        []
  in
    ul [ style (Styles.ul ++ [("display", "flex")]) ]
      (List.map viewForEach model.colorPalette)

publishButtonView : Model -> Html Action
publishButtonView model =
  button
    [ onClick' Publish
    , style Styles.publishButton ]
    [ text "Publish" ]

floorView : Model -> List (Html Action)
floorView model =
    [ fileLoadButton Styles.imageLoadButton "Load Image" |> Html.App.map LoadFile
    , floorNameInputView model
    , floorRealSizeInputView model
    , publishButtonView model
    ]

view : Model -> Html Action
view model =
  div
    []
    [ Header.view (Just model.user) |> Html.App.map HeaderAction
    , mainView model
    , contextMenuView model
    ]

--
