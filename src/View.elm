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
import Scale
import EquipmentsOperation exposing (..)

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
    screenRect = Scale.imageToScreenForRect scale rect
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
              [ Html.Attributes.id "name-input"
              , style styles
              , onInput' (forwardTo address (InputName id)) -- TODO cannot input japanese
              , onKeyDown'' (forwardTo address (KeydownOnNameInput))
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
    , mouseDownDefence address NoOp
    ]
    [ card <| penView address model
    , card <| propertyView address model
    , card <| debugView address model
    ]

card : List Html -> Html
card children =
  div
    [ {-style Styles.card-}
    style [("margin-bottom", "20px"), ("padding", "10px")]
    ] children

penView : Address Action -> Model -> List Html
penView address model =
  let
    widthStyle = [("width", "80px")]
    selection =
      div
        [ style (Styles.selection (model.editMode == Select) ++ widthStyle)
        , onClick' (forwardTo address (always <| ChangeMode Select))
        ]
        [ text "Select" ]
    pen =
      div
        [ style (Styles.selection (model.editMode == Pen) ++ widthStyle)
        , onClick' (forwardTo address (always <| ChangeMode Pen))
        ]
        [ text "Pen" ]
    stamp =
      div
        [ style (Styles.selection (
            case model.editMode of
              Stamp _ -> True
              _ -> False
            ) ++ widthStyle)
        , onClick' (forwardTo address (always <| ChangeMode <| Stamp model.selectedPrototype))
        ]
        [ text "Stamp" ]
  in
    [ text "PenView"
    , div [ style Styles.flex ] [selection, pen, stamp]
    , fileLoadButton (forwardTo address LoadFile)
    ]

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
    [ style (Styles.canvasContainer ++ (case model.editMode of
        Stamp _ ->
          []
          -- [("cursor", "none")]
        _ -> []
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
          moving =
            case (model.draggingContext, model.pos) of
              (MoveEquipment _ (startX, startY), Just (x, y)) -> Just ((startX, startY), (x, y))
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

    (offsetX, offsetY) = model.offset

    rect =
      Scale.imageToScreenForRect
        model.scale
        (offsetX, offsetY, floor.width, floor.height)

    image =
      img
        [ style [("width", "100%"), ("height", "100%")]
        , src (Maybe.withDefault "" floor.dataURL)
        ] []
  in
    div
      [ style (Styles.canvasView rect ++ Styles.transition disableTransition)
      ]
      ((image :: (nameInputView address model) :: (selectorRect :: equipments)) ++ temporaryStamps')

stampIndices : Bool -> (Int, Int) -> (Int, Int) -> (Int, Int) -> (List Int, List Int)
stampIndices horizontal (deskWidth, deskHeight) (x1', y1') (x2', y2') =
  let
    (amountX, amountY) =
      if horizontal then
        let
          amountX = (abs (x2' - x1') + deskWidth // 2) // deskWidth
          amountY = if abs (y2' - y1') > (deskHeight // 2) then 1 else 0
        in
         (amountX, amountY)
      else
        let
          amountX = if abs (x2' - x1') > (deskWidth // 2) then 1 else 0
          amountY = (abs (y2' - y1') + deskHeight // 2) // deskHeight
        in
          (amountX, amountY)
  in
    ( List.map (\i -> if x2' > x1' then i else -i) [0..amountX]
    , List.map (\i -> if y2' > y1' then i else -i) [0..amountY] )

temporaryStampView : Scale.Model -> String -> (Int, Int) -> (Int, Int) -> Html
temporaryStampView scale color (deskWidth, deskHeight) (left, top) =
  equipmentView'
      ("temporary_" ++ toString left ++ "_" ++ toString top)
      (left, top, deskWidth, deskHeight)
      color
      "" --name
      False -- selected
      False -- alpha
      [] -- eventHandlers
      scale
      True -- disableTransition

generateAllCandidatePosition : (Int, Int) -> (Int, Int) -> (List Int, List Int) -> List (Int, Int)
generateAllCandidatePosition (deskWidth, deskHeight) (centerLeft, centerTop) (indicesX, indicesY) =
  let
    lefts =
      List.map (\index -> centerLeft + deskWidth * index) indicesX
    tops =
      List.map (\index -> centerTop + deskHeight * index) indicesY
  in
    List.concatMap (\left -> List.map (\top -> (left, top)) tops) lefts

temporaryStampsView : Model -> List Html
temporaryStampsView model =
  case model.editMode of
    Stamp (color, deskSize) ->
      let
        (offsetX, offsetY) = model.offset
        (x2, y2) =
          -- Debug.log "x2y2" <|
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
              flip (w, h) = (h, w)
              horizontal = abs (x2 - x1) > abs (y2 - y1)
              (deskWidth, deskHeight) = if horizontal then flip deskSize else deskSize
              (indicesX, indicesY) =
                stampIndices horizontal (deskWidth, deskHeight) (x1', y1') (x2', y2')
              (centerLeft, centerTop) =
                -- fitToGrid model.gridSize (x1' - deskWidth // 2, y1' - deskHeight // 2)
                fitToGrid model.gridSize (x1' - fst deskSize // 2, y1' - snd deskSize // 2)
              all =
                generateAllCandidatePosition
                  (deskWidth, deskHeight)
                  (centerLeft, centerTop)
                  (indicesX, indicesY)

            in
              List.map (\(left, top) ->
                temporaryStampView model.scale color (deskWidth, deskHeight) (left, top)
              ) all
          _ ->
            let
              (deskWidth, deskHeight) = deskSize
              (left, top) =
                fitToGrid model.gridSize (x2' - deskWidth // 2, y2' - deskHeight // 2) --TODO
              _ = Debug.log "XXX" <|
                ((x2', y2'), (left, top))
            in
              [ temporaryStampView model.scale color (deskWidth, deskHeight) (left, top)
              ]
    _ -> []

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
        , onMouseDown' (forwardTo address (SelectColor color))
        ]
        []
  in
    ul [ style (Styles.ul ++ [("display", "flex")]) ]
      (List.map viewForEach model.colorPalette)

view : Address Action -> Model -> Html
view address model =
  div
    []
    [ headerView address model
    , mainView address model
    , contextMenuView address model
    ]

--
