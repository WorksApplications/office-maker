module View(view) where

import Html exposing (..)
import Html.Attributes exposing (..)
-- import Html.Lazy exposing (..)
import Maybe
import Signal exposing (Address, forwardTo)
import Styles
-- import Debug

import UndoRedo
import HtmlUtil exposing (..)
import Equipments exposing (..)
import Model exposing (..)

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
        [ contextMenuItemView address (SelectIsland id) "Select Island"
        , contextMenuItemView address (always NoOp) "Other"
        ]

contextMenuItemView : Address Action -> (MouseEvent -> Action) -> String -> Html
contextMenuItemView address action text' =
  div
    [ class "hovarable"
    , style Styles.contextMenuItem
    , onMouseDown' (forwardTo address action)
    ]
    [ text text' ]


equipmentView : Address Action -> Model -> Maybe ((Int, Int), (Int, Int)) -> Bool -> Bool -> Equipment -> Bool -> Html
equipmentView address model moving selected alpha equipment contextMenuDisabled =
  case equipment of
    Desk id (left, top, width, height) color name ->
      let
        moovingBool = moving /= Nothing
        (x, y) =
          case moving of
            Just ((startX, startY), (x, y)) ->
              let
                (dx, dy) = recoverPosition model.scaleDown ((x - startX), (y - startY))
              in
                fitToGrid model.gridSize model.scaleDown (left + dx, top + dy)
            _ -> (left, top)
      in
        equipmentView' address id (x, y, width, height) color name selected moovingBool alpha contextMenuDisabled model.scaleDown

equipmentView' : Address Action -> Id -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> Bool -> Bool -> Int -> Html
equipmentView' address id rect color name selected moving alpha contextMenuDisabled scaleDown =
  let
    contextMenu =
      if contextMenuDisabled then
        []
      else
        [ onContextMenu' (forwardTo address (ShowContextMenuOnEquipment id)) ]
  in
    div
      (contextMenu ++ [ key (id ++ toString moving)
      , style (Styles.desk (scaleDownRect scaleDown rect) color selected alpha ++ [("display", "table")])
      , onMouseDown' (forwardTo address (MouseDownOnEquipment id))
      , onDblClick' (forwardTo address (StartEditEquipment id))
      ])
      [ pre
        [ style (Styles.nameLabel scaleDown)
        ]
        [ text ({-toString (x, y) ++ "\n" ++ -}name)]]

nameInputView : Address Action -> Model -> Html
nameInputView address model =
  case model.editingEquipment of
    Just (id, name) ->
      case findEquipmentById (UndoRedo.data model.floor).equipments id of
        Just (Desk id rect color _) ->
          textarea
            [ Html.Attributes.id "name-input"
            , style (Styles.deskInput rect)
            , onInput' (forwardTo address (InputName id)) -- TODO cannot input japanese
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
    (windowWidth, windowHeight) = model.windowDimensions
    height = windowHeight - 33
  in
    main' [ style (Styles.flex ++ [ ("height", toString height ++ "px")]) ]
      [ div
        [ style (Styles.flexMain  ++ [("position", "relative"), ("overflow-x", "scroll")])
        , onMouseMove' (forwardTo address MoveOnCanvas)
        -- , onMouseEnter (forwardTo address (always EnterCanvas)) address
        -- , onMouseLeave (forwardTo address (always LeaveCanvas)) address
        , onMouseWheel address MouseWheel
        ]
        [ text (toString <| List.map idOf <| model.copiedEquipments)
        , br [] []
        , text (toString model.keys.ctrl)
        , br [] []
        , text (toString model.editingEquipment)
        , br [] []
        , canvasView address model
        , nameInputView address model
        ]
      , propertyView address model
      ]

propertyView : Address Action -> Model -> Html
propertyView address model =
  div
    [ style (Styles.subMenu) ]
    [ text "Color"
    , colorPropertyView address model]

canvasView : Address Action -> Model -> Html
canvasView address model =
  let
    isSelected' = isSelected model

    isDragged equipment =
      model.dragging /= Nothing && List.member (idOf equipment) model.selectedEquipments

    nonDraggingEquipments =
      List.map
        (\equipment -> equipmentView address model Nothing (isSelected' equipment) (isDragged equipment) equipment model.keys.ctrl)
        (UndoRedo.data model.floor).equipments

    draggingEquipments =
      if model.dragging /= Nothing
      then
        let
          equipments = List.filter isDragged (UndoRedo.data model.floor).equipments
          moving =
            case (model.dragging, model.pos) of
              (Just (_, (startX, startY)), Just (x, y)) -> Just ((startX, startY), (x, y))
              _ -> Nothing
        in
          List.map
            (\equipment -> equipmentView address model moving (isSelected' equipment) False equipment model.keys.ctrl)
            equipments
      else []

    equipments =
      draggingEquipments ++ nonDraggingEquipments

    selectorRect =
      case model.selectorRect of
        Just rect ->
          div [style (Styles.selectorRect (scaleDownRect model.scaleDown rect) )] []
        Nothing -> text ""
    rect =
      scaleDownRect
        model.scaleDown
        (20, 20, (UndoRedo.data model.floor).width, (UndoRedo.data model.floor).height)
  in
    div
      [ style (Styles.canvasView rect) ]
      (selectorRect :: equipments)


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
    [ onMouseUp' (forwardTo address (MouseUpBackground))
    , onMouseDown' (forwardTo address (MouseDownBackground))
    -- , onKeyPress' (forwardTo address (KeyPress))
    ]
    [ headerView address model
    , mainView address model
    , contextMenuView address model
    ]

--
