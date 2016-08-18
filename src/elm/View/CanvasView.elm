module View.CanvasView exposing (view, temporaryStampView)

import Dict exposing (..)
import Maybe

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed

import ObjectNameInput
import View.Styles as S
import View.ObjectView as ObjectView
import View.ProfilePopup as ProfilePopup

import Util.HtmlUtil exposing (..)

import Model exposing (..)
import Model.Floor as Floor
import Model.Object as Object exposing (..)
import Model.Scale as Scale
import Model.ObjectsOperation as ObjectsOperation exposing (..)
import Model.Prototypes as Prototypes exposing (StampCandidate)
import Model.EditingFloor as EditingFloor

import Json.Decode as Decode


adjustImagePositionOfMovingObject : Int -> Scale.Model -> (Int, Int) -> (Int, Int) -> (Int, Int) -> (Int, Int)
adjustImagePositionOfMovingObject gridSize scale (startX, startY) (x, y) (left, top) =
  let
    (dx, dy) =
      Scale.screenToImageForPosition scale ((x - startX), (y - startY))
  in
    fitPositionToGrid gridSize (left + dx, top + dy)


objectView : Model -> ((Int, Int, Int, Int) -> (Int, Int, Int, Int)) -> Bool -> Bool -> Object -> Bool -> Bool -> Html Msg
objectView model adjustRect selected isGhost object contextMenuDisabled disableTransition =
  let
    id =
      idOf object

    (x, y, width, height) =
      adjustRect (rect object)

    eventOptions =
      case model.editMode of
        Viewing _ ->
          let
            noEvents = ObjectView.noEvents
          in
            { noEvents |
              onMouseDown = Just (always (ShowDetailForObject id))
            }
        _ ->
          { onContextMenu =
              if contextMenuDisabled then
                Nothing
              else
                Just (ShowContextMenuOnObject id)
          , onMouseDown = Just (MouseDownOnObject id)
          , onMouseUp = Just (MouseUpOnObject id)
          , onStartEditingName = Nothing -- Just (StartEditObject id)
          , onStartResize = Just (MouseDownOnResizeGrip id)
          }

    floor =
      (EditingFloor.present model.floor)

    personMatched =
      Object.relatedPerson object /= Nothing
  in
    if Object.isLabel object then
      ObjectView.viewLabel
        eventOptions
        (x, y, width, height)
        (backgroundColorOf object)
        (colorOf object)
        (nameOf object)
        (fontSizeOf object)
        (shapeOf object == Object.Ellipse)
        selected
        isGhost
        (model.editMode /= Viewing True && model.editMode /= Viewing False) -- rectVisible
        model.scale
        disableTransition
    else
      ObjectView.viewDesk
        eventOptions
        (model.editMode /= Viewing True && model.editMode /= Viewing False)
        (x, y, width, height)
        (backgroundColorOf object)
        (nameOf object)
        (fontSizeOf object)
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
  case Model.currentFloorForView model of
    Just floor ->
      let
        _ = Debug.log "floorVersion" floor.version
        popup' =
          Maybe.withDefault (text "") <|
          model.selectedResult `Maybe.andThen` \id ->
          findObjectById floor.objects id `Maybe.andThen` \e ->
            case Object.relatedPerson e of
              Just personId ->
                Dict.get personId model.personInfo `Maybe.andThen` \person ->
                Just (ProfilePopup.view ClosePopup model.personPopupSize model.scale model.offset e (Just person))
              Nothing ->
                Just (ProfilePopup.view ClosePopup model.personPopupSize model.scale model.offset e Nothing)

        inner =
          if (EditingFloor.present model.floor).id == "" then
            []
          else
            [ canvasView model floor, popup']
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

    Nothing ->
      text ""


canvasView : Model -> Floor -> Html Msg
canvasView model floor =
  let
    (isViewing, isPrintMode) =
      case model.editMode of
        Viewing print -> (True, print)
        _ -> (False, False)

    objects =
      objectsView model floor

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
            ( Scale.imageToScreenForRect model.scale (Object.rect e)
            , maybePersonId `Maybe.andThen` (\id -> Dict.get id model.personInfo)
            )
        )
        (findObjectById floor.objects id)

    nameInput =
      App.map ObjectNameInputMsg <|
        ObjectNameInput.view
          (deskInfoOf model)
          (transitionDisabled model)
          (candidatesOf model)
          model.objectNameInput

    children1 =
      ("canvas-image", image) ::
      ("canvas-name-input", nameInput) ::
      ("canvas-selector-rect", selectorRect) ::
      objects

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


objectsView : Model -> Floor -> List (String, Html Msg)
objectsView model floor =
  case model.draggingContext of
    MoveObject _ from ->
      let
        isSelected object =
          List.member (idOf object) model.selectedObjects

        ghostsView =
          List.map
            (\object ->
              ( idOf object ++ "ghost"
              , objectView
                  model
                  identity
                  True
                  True -- alpha
                  object
                  False --model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            (List.filter isSelected floor.objects)

        adjustRect object (left, top, width, height) =
          if isSelected object then
            let
              (x, y) =
                adjustImagePositionOfMovingObject
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
            (\object ->
              ( idOf object
              , objectView
                  model
                  (adjustRect object)
                  (isSelected object)
                  False -- alpha
                  object
                  model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            floor.objects
      in
        (ghostsView ++ normalView)

    ResizeFromScreenPos id from ->
      let
        isSelected object =
          List.member (idOf object) model.selectedObjects

        isResizing object =
          idOf object == id

        ghostsView =
          List.map
            (\object ->
              ( idOf object ++ "ghost"
              , objectView
                  model
                  identity
                  True -- isSelected
                  True -- alpha
                  object
                  model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            (List.filter isResizing floor.objects)


        adjustRect object (left, top, width, height) =
          if isResizing object then
            case Model.temporaryResizeRect model from (left, top, width, height) of
              Just rect -> rect
              _ -> (0,0,0,0)
          else
            (left, top, width, height)

        normalView =
          List.map
            (\object ->
              ( idOf object
              , objectView
                  model
                  (adjustRect object)
                  (isResizing object) -- isSelected TODO seems not selected?
                  False -- alpha
                  object
                  model.keys.ctrl
                  (transitionDisabled model)
              )
            )
            floor.objects
      in
        (normalView ++ ghostsView)

    _ ->
      List.map
        (\object ->
          ( idOf object
          , objectView
              model
              identity
              (isSelected model object)
              False -- alpha
              object
              model.keys.ctrl
              (transitionDisabled model)
          )
        )
        floor.objects


canvasImage : Floor -> Html msg
canvasImage floor =
  img
    [ style S.canvasImage
    , src (Maybe.withDefault "" (Floor.src floor))
    ] []


temporaryStampView : Scale.Model -> Bool -> StampCandidate -> (String, Html msg)
temporaryStampView scale selected ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top)) =
  ( "temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString deskWidth ++ "_" ++ toString deskHeight
  , ObjectView.viewDesk
      ObjectView.noEvents
      False
      (left, top, deskWidth, deskHeight)
      color
      name --name
      Object.defaultFontSize
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
      ObjectView.viewDesk
        ObjectView.noEvents
        False
        (left, top, width, height)
        color
        name --name
        Object.defaultFontSize
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
