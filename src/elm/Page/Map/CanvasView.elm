module Page.Map.CanvasView exposing (view, temporaryStampView)

import Dict exposing (..)
import Maybe
import Json.Decode as Decode

import Mouse
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import ContextMenu

import Component.ObjectNameInput as ObjectNameInput
import View.Styles as S
import View.ObjectView as ObjectView
import View.ProfilePopup as ProfilePopup
import Page.Map.GridLayer as GridLayer

import Util.HtmlUtil exposing (..)

import Model.Mode as Mode exposing (Mode(..))
import Model.Floor as Floor exposing (Floor)
import Model.Object as Object exposing (..)
import Model.Scale as Scale exposing (Scale)
import Model.ObjectsOperation as ObjectsOperation
import Model.Prototypes as Prototypes exposing (PositionedPrototype)

import Page.Map.Model as Model exposing (Model, DraggingContext(..))
import Page.Map.ContextMenuContext exposing (ContextMenuContext(ObjectContextMenu))
import Page.Map.Msg exposing (..)


type alias Position =
  { x : Int
  , y : Int
  }


adjustImagePositionOfMovingObject : Int -> Scale -> Position -> Position -> Position -> Position
adjustImagePositionOfMovingObject gridSize scale start end from =
  let
    shift =
      Scale.screenToImageForPosition
        scale
        { x = end.x - start.x
        , y = end.y - start.y
        }
  in
    ObjectsOperation.fitPositionToGrid
      gridSize
      { x = from.x + shift.x
      , y = from.y + shift.y
      }


type alias ObjectViewOption =
  { mode: Mode
  , scale: Scale
  , selected: Bool
  , isGhost: Bool
  , object: Object
  , rect: (Int, Int, Int, Int)
  , contextMenuDisabled: Bool
  , disableTransition: Bool
  }


objectView : ObjectViewOption -> Html Msg
objectView {mode, scale, selected, isGhost, object, rect, contextMenuDisabled, disableTransition} =
  let
    id =
      Object.idOf object

    (x, y, width, height) =
      rect

    eventOptions =
      if Mode.isViewMode mode then
        let
          noEvents = ObjectView.noEvents
        in
          { noEvents |
            onMouseDown = Just (always <| ShowDetailForObject id)
          }
      else
        { onContextMenu =
            if contextMenuDisabled then
              Nothing
            else
              Just
                ( ContextMenu.open ContextMenuMsg (ObjectContextMenu id)
                    |> Attributes.map (BeforeContextMenuOnObject id)
                )
        , onMouseDown = Just (MouseDownOnObject id)
        , onMouseUp = Just (MouseUpOnObject id)
        , onClick = Just NoOp
        , onStartEditingName = Nothing -- Just (StartEditObject id)
        , onStartResize = Just (MouseDownOnResizeGrip id)
        }

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
        (Mode.isEditMode mode)
        scale
        disableTransition
    else
      ObjectView.viewDesk
        eventOptions
        (Mode.isEditMode mode)
        (x, y, width, height)
        (backgroundColorOf object)
        (nameOf object)
        (fontSizeOf object)
        selected
        isGhost
        scale
        disableTransition
        personMatched


transitionDisabled : Model -> Bool
transitionDisabled model =
  not model.scaling


view : Model -> Html Msg
view model =
  case Model.getEditingFloor model of
    Just floor ->
      let
        isRangeSelectMode =
          Mode.isSelectMode model.mode && model.keys.ctrl
      in
        div
          [ style (S.canvasContainer (Mode.isPrintMode model.mode) isRangeSelectMode)
          , on "mousedown" Mouse.position |> Attributes.map MouseDownOnCanvas
          , onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } (Mouse.position |> Decode.map MouseUpOnCanvas)
          , onClick ClickOnCanvas
          , onMouseWheel MouseWheel
          ]
          [ canvasView model floor
          , profilePopupView model floor
          ]

    Nothing ->
      div
        [ style (S.canvasContainer (Mode.isPrintMode model.mode) False)
        ] []


profilePopupView : Model -> Floor -> Html Msg
profilePopupView model floor =
  if Mode.isPrintMode model.mode then
    text ""
  else
    model.selectedResult
      |> Maybe.andThen (\objectId -> Floor.getObject objectId floor
      |> Maybe.andThen (\object ->
        case Object.relatedPerson object of
          Just personId ->
            Dict.get personId model.personInfo
              |> Maybe.map (\person ->
                ProfilePopup.view ClosePopup model.personPopupSize model.scale model.offset object (Just person)
              )

          Nothing ->
            Just (ProfilePopup.view ClosePopup model.personPopupSize model.scale model.offset object Nothing)
        ))
      |> Maybe.withDefault (text "")


canvasView : Model -> Floor -> Html Msg
canvasView model floor =
  let
    deskInfoOf scale personInfo objectId =
      Maybe.map
        (\object ->
          ( Scale.imageToScreenForRect scale (Object.rect object)
          , relatedPerson object
              |> Maybe.andThen (\personId -> Dict.get personId personInfo)
          )
        )
        (Floor.getObject objectId floor)

    nameInput =
      Html.map ObjectNameInputMsg <|
        ObjectNameInput.view
          (deskInfoOf model.scale model.personInfo)
          (transitionDisabled model)
          (Model.candidatesOf model)
          model.objectNameInput

    gridLayer =
      if Mode.isEditMode model.mode then
        GridLayer.view model floor
      else
        text ""

    isEditMode =
      Mode.isEditMode model.mode

    children1 =
      Just ("canvas-image", canvasImage floor) ::
      (if isEditMode then Just ("grid-layer", gridLayer) else Nothing) ::
      (if isEditMode then Just ("canvas-name-input", nameInput) else Nothing) ::
      (if isEditMode then Just ("canvas-selector-rect", selectorRectView model) else Nothing) :: []
      |> List.filterMap identity

    children2 =
      objectsView model floor

    children3 =
      if isEditMode then
        ("canvas-temporary-pen", temporaryPenView model) :: temporaryStampsView model
      else
        []
  in
    Keyed.node
      "div"
      [ style (canvasViewStyles model floor) ]
      ( children1 ++ children2 ++ children3)


canvasViewStyles : Model -> Floor -> List (String, String)
canvasViewStyles model floor =
  let
    rect =
      Scale.imageToScreenForRect
        model.scale
        (model.offset.x, model.offset.y, Floor.width floor, Floor.height floor)
  in
    -- if (Mode.isPrintMode model.mode) then
    --   S.canvasViewForPrint (model.windowSize.width, model.windowSize.height) rect
    -- else
      S.canvasView (Mode.isViewMode model.mode) (transitionDisabled model) rect


objectsView : Model -> Floor -> List (String, Html Msg)
objectsView model floor =
  case model.draggingContext of
    MoveObject _ start ->
      let
        objectList =
          Floor.objects floor

        isSelected object =
          List.member (Object.idOf object) model.selectedObjects

        ghostsView =
          List.map
            (\object ->
              ( Object.idOf object ++ "ghost"
              , lazy objectView
                  { mode = model.mode
                  , scale = model.scale
                  , rect = rect object
                  , selected = True
                  , isGhost = True -- alpha
                  , object = object
                  , contextMenuDisabled = False --model.keys.ctrl
                  , disableTransition = transitionDisabled model
                  }
              )
            )
            (List.filter isSelected objectList)

        adjustRect object (left, top, width, height) =
          if isSelected object then
            let
              { x, y } =
                adjustImagePositionOfMovingObject
                  model.gridSize
                  model.scale
                  start
                  model.mousePosition
                  { x = left, y = top }
            in
              (x, y, width, height)
          else
            (left, top, width, height)

        normalView =
          List.map
            (\object ->
              ( Object.idOf object
              , lazy
                objectView
                  { mode = model.mode
                  , scale = model.scale
                  , rect = adjustRect object (rect object)
                  , selected = isSelected object
                  , isGhost = False
                  , object = object
                  , contextMenuDisabled = model.keys.ctrl
                  , disableTransition = transitionDisabled model
                  }
              )
            )
            objectList
      in
        (ghostsView ++ normalView)

    ResizeFromScreenPos id from ->
      let
        objectList =
          Floor.objects floor

        isSelected object =
          List.member (Object.idOf object) model.selectedObjects

        isResizing object =
          Object.idOf object == id

        ghostsView =
          List.map
            (\object ->
              ( Object.idOf object ++ "ghost"
              , lazy objectView
                { mode = model.mode
                , scale = model.scale
                , rect = rect object
                , selected = True
                , isGhost = True
                , object = object
                , contextMenuDisabled = model.keys.ctrl
                , disableTransition = transitionDisabled model
                }
              )
            )
            (List.filter isResizing objectList)

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
              ( Object.idOf object
              , lazy objectView
                { mode = model.mode
                , scale = model.scale
                , rect = adjustRect object (rect object)
                , selected = isResizing object --TODO seems not selected?
                , isGhost = False
                , object = object
                , contextMenuDisabled = model.keys.ctrl
                , disableTransition = transitionDisabled model
                }
              )
            )
            objectList
      in
        (normalView ++ ghostsView)

    _ ->
      List.map
        (\object ->
          ( Object.idOf object
          , lazy objectView
            { mode = model.mode
            , scale = model.scale
            , rect = (rect object)
            , selected = Mode.isEditMode model.mode && List.member (Object.idOf object) model.selectedObjects
            , isGhost = False
            , object = object
            , contextMenuDisabled = model.keys.ctrl
            , disableTransition = transitionDisabled model
            }
          )
        )
        (Floor.objects floor)


canvasImage : Floor -> Html msg
canvasImage floor =
  img
    [ style S.canvasImage
    , src (Maybe.withDefault "" (Floor.src floor))
    ] []


temporaryStampsView : Model -> List (String, Html msg)
temporaryStampsView model =
  List.map
    (temporaryStampView model.scale False)
    (Model.getPositionedPrototype model)


temporaryStampView : Scale -> Bool -> PositionedPrototype -> (String, Html msg)
temporaryStampView scale selected (prototype, (left, top)) =
  -- TODO How about using prototype.id?
  ( "temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString prototype.width ++ "_" ++ toString prototype.height
  , ObjectView.viewDesk
      ObjectView.noEvents
      False
      (left, top, prototype.width, prototype.height)
      prototype.backgroundColor
      prototype.name --name
      Object.defaultFontSize
      selected
      False -- alpha
      scale
      True -- disableTransition
      False -- personMatched
  )


temporaryPenView : Model -> Html msg
temporaryPenView model =
  case model.draggingContext of
    PenFromScreenPos start ->
      case Model.temporaryPen model start of
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

        _ -> text ""

    _ -> text ""


selectorRectView : Model -> Html msg
selectorRectView model =
  case (Mode.isSelectMode model.mode, model.selectorRect) of
    (True, Just rect) ->
      div
        [ style (S.selectorRect (transitionDisabled model) (Scale.imageToScreenForRect model.scale rect) )
        ]
        []

    _ ->
      text ""

--
