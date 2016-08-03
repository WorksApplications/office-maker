module View.CanvasView exposing (view, temporaryStampView)

import Dict exposing (..)
import Maybe

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed

import EquipmentNameInput
import View.Styles as S
import View.EquipmentView as EquipmentView
import View.ProfilePopup as ProfilePopup

import Util.HtmlUtil exposing (..)

import Model exposing (..)
import Model.Floor as Floor
import Model.Equipment as Equipment exposing (..)
import Model.Scale as Scale
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Model.Prototypes as Prototypes exposing (Prototype, StampCandidate)
import Model.EditingFloor as EditingFloor

import Json.Decode as Decode


adjustImagePositionOfMovingEquipment : Int -> Scale.Model -> (Int, Int) -> (Int, Int) -> (Int, Int) -> (Int, Int)
adjustImagePositionOfMovingEquipment gridSize scale (startX, startY) (x, y) (left, top) =
  let
    (dx, dy) =
      Scale.screenToImageForPosition scale ((x - startX), (y - startY))
  in
    fitPositionToGrid gridSize (left + dx, top + dy)


equipmentView : Model -> ((Int, Int, Int, Int) -> (Int, Int, Int, Int)) -> Bool -> Bool -> Equipment -> Bool -> Bool -> Html Msg
equipmentView model adjustRect selected isGhost equipment contextMenuDisabled disableTransition =
  let
    id =
      idOf equipment

    (x, y, width, height) =
      adjustRect (rect equipment)

    eventOptions =
      case model.editMode of
        Viewing _ ->
          let
            noEvents = EquipmentView.noEvents
          in
            { noEvents |
              onMouseDown = Just (always (ShowDetailForEquipment id))
            }
        _ ->
          { onContextMenu =
              if contextMenuDisabled then
                Nothing
              else
                Just (ShowContextMenuOnEquipment id)
          , onMouseDown = Just (MouseDownOnEquipment id)
          , onMouseUp = Just (MouseUpOnEquipment id)
          , onStartEditingName = Nothing -- Just (StartEditEquipment id)
          , onStartResize = Just (MouseDownOnResizeGrip id)
          }

    floor =
      (EditingFloor.present model.floor)

    personMatched =
      Equipment.relatedPerson equipment /= Nothing
  in
    if Equipment.isLabel equipment then
      EquipmentView.viewLabel
        eventOptions
        (x, y, width, height)
        (backgroundColorOf equipment)
        (colorOf equipment)
        (nameOf equipment)
        (fontSizeOf equipment)
        (shapeOf equipment == Equipment.Ellipse)
        selected
        isGhost
        (model.editMode /= Viewing True && model.editMode /= Viewing False) -- rectVisible
        model.scale
        disableTransition
    else
      EquipmentView.viewDesk
        eventOptions
        (model.editMode /= Viewing True && model.editMode /= Viewing False)
        (x, y, width, height)
        (backgroundColorOf equipment)
        (nameOf equipment)
        (fontSizeOf equipment)
        selected
        isGhost
        model.scale
        disableTransition
        personMatched


transitionDisabled : Model -> Bool
transitionDisabled model =
  not model.scaling


view : Model -> Html Msg
view model =
  let
    floor =
      (EditingFloor.present model.floor)

    popup' =
      Maybe.withDefault (text "") <|
      model.selectedResult `Maybe.andThen` \id ->
      findEquipmentById floor.equipments id `Maybe.andThen` \e ->
        case Equipment.relatedPerson e of
          Just personId ->
            Dict.get personId model.personInfo `Maybe.andThen` \person ->
            Just (ProfilePopup.view ClosePopup model.personPopupSize model.scale model.offset e (Just person))
          Nothing ->
            Just (ProfilePopup.view ClosePopup model.personPopupSize model.scale model.offset e Nothing)

    inner =
      case (model.editMode, (EditingFloor.present model.floor).id) of
        (Viewing _, Nothing) ->
          [] -- don't show draft on Viewing mode
        _ ->
          [ canvasView model, popup']
  in
    div
      [ style (S.canvasContainer (model.editMode == Viewing True) ++
        ( if model.editMode == Stamp then
            [] -- [("cursor", "none")]
          else
            []
        ))
      , onMouseMove' MoveOnCanvas
      , onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.map MouseDownOnCanvas decodeClientXY)
      , onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } (Decode.succeed MouseUpOnCanvas)
      , onMouseEnter' EnterCanvas
      , onMouseLeave' LeaveCanvas
      , onMouseWheel MouseWheel
      ]
      inner


canvasView : Model -> Html Msg
canvasView model =
  let
    floor =
      (EditingFloor.present model.floor)

    (isViewing, isPrintMode) =
      case model.editMode of
        Viewing print -> (True, print)
        _ -> (False, False)

    equipments =
      equipmentsView model

    selectorRect =
      case (model.editMode, model.selectorRect) of
        (Select, Just rect) ->
          div [style (S.selectorRect (transitionDisabled model) (Scale.imageToScreenForRect model.scale rect) )] []
        _ -> text ""

    temporaryStamps' =
      temporaryStampsView model

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
      canvasImage floor

    deskInfoOf model id =
      Maybe.map
        (\e ->
          let
            id = idOf e
            maybePersonId = relatedPerson e
          in
            ( Scale.imageToScreenForRect model.scale (Equipment.rect e)
            , maybePersonId `Maybe.andThen` (\id -> Dict.get id model.personInfo)
            )
        )
        (findEquipmentById (EditingFloor.present model.floor).equipments id)

    nameInput =
      App.map EquipmentNameInputMsg <|
        EquipmentNameInput.view
          (deskInfoOf model)
          (transitionDisabled model)
          (candidatesOf model)
          model.equipmentNameInput

    children1 =
      ("canvas-image", image) ::
      ("canvas-name-input", nameInput) ::
      ("canvas-selector-rect", selectorRect) ::
      equipments

    children2 =
      ("canvas-temporary-pen", temporaryPen') ::
      temporaryStamps'

    styles =
      if isPrintMode then
        S.canvasViewForPrint model.windowSize rect
      else
        S.canvasView isViewing (transitionDisabled model) rect

  in
    Keyed.node
      "div"
      [ style styles ]
      ( children1 ++ children2 )


equipmentsView : Model -> List (String, Html Msg)
equipmentsView model =
  case model.draggingContext of
    MoveEquipment _ from ->
      let
        isSelected equipment =
          List.member (idOf equipment) model.selectedEquipments

        ghostsView =
          List.map
            (\equipment ->
              ( idOf equipment ++ "ghost"
              , equipmentView
                  model
                  identity
                  True
                  True -- alpha
                  equipment
                  False --model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            (List.filter isSelected ((EditingFloor.present model.floor).equipments))

        adjustRect equipment (left, top, width, height) =
          if isSelected equipment then
            let
              (x, y) =
                adjustImagePositionOfMovingEquipment
                  model.gridSize
                  model.scale
                  from
                  model.pos
                  (left, top)
            in
              (x, y, width, height)
          else
            (left, top, width, height)

        normalView =
          List.map
            (\equipment ->
              ( idOf equipment
              , equipmentView
                  model
                  (adjustRect equipment)
                  (isSelected equipment)
                  False -- alpha
                  equipment
                  model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            ((EditingFloor.present model.floor).equipments)
      in
        (ghostsView ++ normalView)

    ResizeFromScreenPos id from ->
      let
        isSelected equipment =
          List.member (idOf equipment) model.selectedEquipments

        isResizing equipment =
          idOf equipment == id

        ghostsView =
          List.map
            (\equipment ->
              ( idOf equipment ++ "ghost"
              , equipmentView
                  model
                  identity
                  True -- isSelected
                  True -- alpha
                  equipment
                  model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            (List.filter isResizing ((EditingFloor.present model.floor).equipments))


        adjustRect equipment (left, top, width, height) =
          if isResizing equipment then
            case Model.temporaryResizeRect model from (left, top, width, height) of
              Just rect -> rect
              _ -> (0,0,0,0)
          else
            (left, top, width, height)

        normalView =
          List.map
            (\equipment ->
              ( idOf equipment
              , equipmentView
                  model
                  (adjustRect equipment)
                  (isResizing equipment) -- isSelected TODO seems not selected?
                  False -- alpha
                  equipment
                  model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            ((EditingFloor.present model.floor).equipments)
      in
        (normalView ++ ghostsView)

    _ ->
      List.map
        (\equipment ->
          ( idOf equipment
          , equipmentView
              model
              identity
              (isSelected model equipment)
              False -- alpha
              equipment
              model.keys.ctrl
              (transitionDisabled model)
          )
        )
        ((EditingFloor.present model.floor).equipments)


canvasImage : Floor -> Html msg
canvasImage floor =
  img
    [ style S.canvasImage
    , src (Maybe.withDefault "" (Floor.src floor))
    ] []


temporaryStampView : Scale.Model -> Bool -> StampCandidate -> (String, Html msg)
temporaryStampView scale selected ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top)) =
  ( "temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString deskWidth ++ "_" ++ toString deskHeight
  , EquipmentView.viewDesk
      EquipmentView.noEvents
      False
      (left, top, deskWidth, deskHeight)
      color
      name --name
      Equipment.defaultFontSize
      selected
      False -- alpha
      scale
      True -- disableTransition
      False -- personMatched
  )


temporaryPenView : Model -> (Int, Int) -> Html msg
temporaryPenView model from =
  case temporaryPen model from of
    Just (color, name, (left, top, width, height)) ->
      EquipmentView.viewDesk
        EquipmentView.noEvents
        False
        (left, top, width, height)
        color
        name --name
        Equipment.defaultFontSize
        False -- selected
        False -- alpha
        model.scale
        True -- disableTransition
        False -- personMatched
    Nothing ->
      text ""


temporaryStampsView : Model -> List (String, Html msg)
temporaryStampsView model =
  List.map
    (temporaryStampView model.scale False)
    (stampCandidates model)

--
