module Page.Map.CanvasView exposing (view, temporaryStampView)

import Dict exposing (..)
import Json.Decode as Decode exposing (Decoder)

import Mouse
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy as Lazy exposing (..)
import ContextMenu

import View.Styles as S
import View.ObjectView as ObjectView
import Util.HtmlUtil as HtmlUtil exposing (..)

import Model.Mode as Mode exposing (Mode(..))
import Model.Floor as Floor exposing (Floor)
import Model.Object as Object exposing (..)
import Model.Scale as Scale exposing (Scale)
import Model.ObjectsOperation as ObjectsOperation
import Model.Prototypes as Prototypes exposing (PositionedPrototype)

import Page.Map.Model as Model exposing (Model, DraggingContext(..))
import Page.Map.ContextMenuContext exposing (ContextMenuContext(ObjectContextMenu))
import Page.Map.Msg exposing (..)
import Page.Map.ObjectNameInput as ObjectNameInput
import Page.Map.ProfilePopup as ProfilePopup
import Page.Map.GridLayer as GridLayer

import Model.ClipboardData as ClipboardData


import CoreType exposing (..)


adjustImagePositionOfMovingObject : Int -> Scale -> Position -> Position -> Position -> Position
adjustImagePositionOfMovingObject gridSize scale start end from =
  let
    shift =
      Scale.screenToImageForPosition
        scale
        (Position (end.x - start.x) (end.y - start.y))
  in
    ObjectsOperation.fitPositionToGrid
      gridSize
      (Position (from.x + shift.x) (from.y + shift.y))


type alias ObjectViewOption =
  { mode: Mode
  , scale: Scale
  , selected: Bool
  , isGhost: Bool
  , object: Object
  , position : Position
  , size : Size
  , contextMenuDisabled: Bool
  }


objectView : ObjectViewOption -> Html Msg
objectView { mode, scale, selected, isGhost, object, position, size, contextMenuDisabled } =
  let
    id =
      Object.idOf object

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
        position
        size
        (backgroundColorOf object)
        (colorOf object)
        (nameOf object)
        (fontSizeOf object)
        (shapeOf object == Object.Ellipse)
        selected
        isGhost
        (Mode.isEditMode mode)
        scale
    else
      ObjectView.viewDesk
        eventOptions
        (Mode.isEditMode mode)
        position
        size
        (backgroundColorOf object)
        (nameOf object)
        (fontSizeOf object)
        selected
        isGhost
        scale
        personMatched


view : Model -> Html Msg
view model =
  case Model.getEditingFloor model of
    Just floor ->
      let
        isRangeSelectMode =
          Mode.isSelectMode model.mode && model.keys.ctrl
      in
        div
          [ style (canvasContainerStyle model.mode isRangeSelectMode)
          , on "mousedown" Mouse.position |> Attributes.map MouseDownOnCanvas
          , onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } (Mouse.position |> Decode.map MouseUpOnCanvas)
          , onClick ClickOnCanvas
          , onMouseWheel MouseWheel
          ]
          [ canvasView model floor
          , {- if Mode.isEditMode model.mode then text "" else -} profilePopupView model floor
          ]

    Nothing ->
      div
        [ style (canvasContainerStyle model.mode False)
        ] []


pasteHandler : Html Msg
pasteHandler =
  div
    [ id "paste-handler"
    , attribute "contenteditable" ""
    , style
        [ ("position", "absolute")
        , ("top", "0")
        , ("left", "0")
        , ("width", "100%")
        , ("height", "100%")
        ]
    , on "keydown" (HtmlUtil.decodeUndoRedo Undo Redo)
    , onWithOptions "paste" { preventDefault = True, stopPropagation = True } (ClipboardData.decode PasteFromClipboard)
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
                ProfilePopup.view ClosePopup model.transition model.scale model.offset object (Just person)
              )

          Nothing ->
            Just (ProfilePopup.view ClosePopup model.transition model.scale model.offset object Nothing)
        ))
      |> Maybe.withDefault (text "")


canvasView : Model -> Floor -> Html Msg
canvasView model floor =
  let
    deskInfoOf scale personInfo objectId =
      Floor.getObject objectId floor
        |> Maybe.map
          (\object ->
            let
              screenPos =
                Scale.imageToScreenForPosition scale (Object.positionOf object)

              screenSize =
                Scale.imageToScreenForSize scale (Object.sizeOf object)
            in
              ( screenPos
              , screenSize
              , relatedPerson object
                  |> Maybe.andThen (\personId -> Dict.get personId personInfo)
              , not (Object.isLabel object)
              )
          )

    nameInput =
      ObjectNameInput.view
        (deskInfoOf model.scale model.personInfo)
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
      Just ("canvas-image", Lazy.lazy canvasImage floor) ::
      (if isEditMode then Just ("grid-layer", gridLayer) else Nothing) ::
      (if isEditMode then Just ("paste-handler", pasteHandler) else Nothing) ::
      (if isEditMode then Just ("canvas-name-input", nameInput) else Nothing) ::
      (if isEditMode then Just ("canvas-selector-rect", Lazy.lazy3 selectorRectView model.mode model.scale model.selectorRect) else Nothing) :: []
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
    position =
      Scale.imageToScreenForPosition
        model.scale
        model.offset

    size =
      Scale.imageToScreenForSize
        model.scale
        (Size (Floor.width floor) (Floor.height floor))
  in
    -- if (Mode.isPrintMode model.mode) then
    --   S.canvasViewForPrint (model.windowSize.width, model.windowSize.height) rect
    -- else
      S.canvasView model.transition (Mode.isViewMode model.mode) position size


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
                  , position = Object.positionOf object
                  , size = Object.sizeOf object
                  , selected = True
                  , isGhost = True -- alpha
                  , object = object
                  , contextMenuDisabled = False --model.keys.ctrl
                  }
              )
            )
            (List.filter isSelected objectList)

        adjustPosition object leftTop =
          if isSelected object then
            adjustImagePositionOfMovingObject
              model.gridSize
              model.scale
              start
              model.mousePosition
              leftTop
          else
            leftTop

        normalView =
          List.map
            (\object ->
              ( Object.idOf object
              , lazy
                objectView
                  { mode = model.mode
                  , scale = model.scale
                  , position = adjustPosition object (Object.positionOf object)
                  , size = Object.sizeOf object
                  , selected = isSelected object
                  , isGhost = False
                  , object = object
                  , contextMenuDisabled = model.keys.ctrl
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
                , position = Object.positionOf object
                , size = Object.sizeOf object
                , selected = True
                , isGhost = True
                , object = object
                , contextMenuDisabled = model.keys.ctrl
                }
              )
            )
            (List.filter isResizing objectList)

        adjustRect object pos size =
          if isResizing object then
            Model.temporaryResizeRect model from pos size
              |> Maybe.withDefault (Position 0 0, Size 0 0)
          else
            (pos, size)

        normalView =
          List.map
            (\object ->
              ( Object.idOf object
              , lazy objectView
                { mode = model.mode
                , scale = model.scale
                , position = adjustRect object (Object.positionOf object) (Object.sizeOf object) |> Tuple.first -- TODO
                , size = adjustRect object (Object.positionOf object) (Object.sizeOf object) |> Tuple.second -- TODO
                , selected = isResizing object --TODO seems not selected?
                , isGhost = False
                , object = object
                , contextMenuDisabled = model.keys.ctrl
                }
              )
            )
            objectList
      in
        normalView ++ ghostsView

    _ ->
      List.map
        (\object ->
          ( Object.idOf object
          , lazy objectView
            { mode = model.mode
            , scale = model.scale
            , position = Object.positionOf object
            , size = Object.sizeOf object
            , selected = Mode.isEditMode model.mode && List.member (Object.idOf object) model.selectedObjects
            , isGhost = False
            , object = object
            , contextMenuDisabled = model.keys.ctrl
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
  Model.getPositionedPrototype model
    |> List.map (temporaryStampView model.scale False)


temporaryStampView : Scale -> Bool -> PositionedPrototype -> (String, Html msg)
temporaryStampView scale selected (prototype, pos) =
  -- TODO How about using prototype.id?
  ( "temporary_" ++ toString pos.x ++ "_" ++ toString pos.y ++ "_" ++ toString prototype.width ++ "_" ++ toString prototype.height
  , ObjectView.viewDesk
      ObjectView.noEvents
      False
      pos
      (Size prototype.width prototype.height)
      prototype.backgroundColor
      prototype.name --name
      Object.defaultFontSize
      selected
      False -- alpha
      scale
      False -- personMatched
  )


temporaryPenView : Model -> Html msg
temporaryPenView model =
  case model.draggingContext of
    PenFromScreenPos start ->
      case Model.temporaryPen model start of
        Just (color, name, pos, size) ->
          ObjectView.viewDesk
            ObjectView.noEvents
            False
            pos
            size
            color
            name --name
            Object.defaultFontSize
            False -- selected
            False -- alpha
            model.scale
            False -- personMatched

        _ -> text ""

    _ -> text ""


selectorRectView : Mode -> Scale -> Maybe (Position, Size) -> Html msg
selectorRectView mode scale selectorRect =
  case (Mode.isSelectMode mode, selectorRect) of
    (True, Just (pos, size)) ->
      div
        [ style
            ( S.selectorRect
                (Scale.imageToScreenForPosition scale pos)
                (Scale.imageToScreenForSize scale size)
            )
        ]
        []

    _ ->
      text ""

--


canvasContainerStyle : Mode -> Bool -> S.S
canvasContainerStyle mode rangeSelectMode =
  let
    crosshair =
      rangeSelectMode || Mode.isLabelMode mode
  in
    [ ("position", "relative")
    , ("background", if Mode.isPrintMode mode then "#ddd" else "#000")
    , ("flex", "1")
    , ("cursor", if crosshair then "crosshair" else "default")
    ]
