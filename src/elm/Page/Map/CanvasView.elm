module Page.Map.CanvasView exposing (view, temporaryStampView)

import Dict exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Mouse
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy as Lazy exposing (..)
import Svg exposing (Svg)
import Svg.Attributes
import Svg.Keyed
import VirtualDom
import ContextMenu
import View.ObjectView as ObjectView
import View.CommonStyles as CommonStyles
import Util.StyleUtil exposing (px)
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
import Page.Map.KeyOperation as KeyOperation
import Model.ClipboardData as ClipboardData
import Native.ClipboardData
import CoreType exposing (..)


viewModeEventOptions : ObjectId -> ObjectView.EventOptions Msg
viewModeEventOptions id =
    let
        noEvents =
            ObjectView.noEvents
    in
        { noEvents
            | onMouseDown =
                Just <|
                    onWithOptions
                        "mousedown"
                        { stopPropagation = True, preventDefault = True }
                        (Decode.succeed <| ShowDetailForObject id)
        }


editModeEventOptions : ObjectId -> ObjectView.EventOptions Msg
editModeEventOptions id =
    { onContextMenu =
        Just
            (ContextMenu.open ContextMenuMsg (ObjectContextMenu id)
                |> Attributes.map (BeforeContextMenuOnObject id)
            )
    , onMouseDown =
        Just <|
            onWithOptions
                "mousedown"
                { stopPropagation = True, preventDefault = True }
                (Decode.map4 MouseDownOnObject
                    KeyOperation.decodeCtrlOrCommand
                    KeyOperation.decodeShift
                    (Decode.succeed id)
                    Mouse.position
                )
    , onMouseUp = Just (MouseUpOnObject id)
    , onClick = Just NoOp
    , onStartEditingName = Nothing -- Just (StartEditObject id)
    , onStartResize = Just (MouseDownOnResizeGrip id)
    }


printModeObjectView : Scale -> Object -> Html Msg
printModeObjectView scale object =
    objectViewHelp
        ObjectView.noEvents
        False
        -- isGhost
        False
        -- isEditMode
        False
        -- selected
        scale
        object


viewModeObjectView : Scale -> Object -> Html Msg
viewModeObjectView scale object =
    objectViewHelp
        (viewModeEventOptions (Object.idOf object))
        False
        -- isGhost
        False
        -- isEditMode
        False
        -- selected
        scale
        object


ghostObjectView : Scale -> Object -> Html Msg
ghostObjectView scale object =
    objectViewHelp
        ObjectView.noEvents
        True
        -- isGhost
        True
        -- isEditMode
        True
        -- selected
        scale
        object


nonGhostOjectView : Scale -> Bool -> Object -> Html Msg
nonGhostOjectView scale selected object =
    objectViewHelp
        (editModeEventOptions (Object.idOf object))
        True
        -- isGhost
        False
        -- isEditMode
        selected
        scale
        object


objectViewHelp : ObjectView.EventOptions Msg -> Bool -> Bool -> Bool -> Scale -> Object -> Html Msg
objectViewHelp eventOptions isEditMode isGhost selected scale object =
    if Object.isLabel object then
        ObjectView.viewLabel
            eventOptions
            (positionOf object)
            (sizeOf object)
            (backgroundColorOf object)
            (colorOf object)
            (nameOf object)
            (fontSizeOf object)
            (shapeOf object == Object.Ellipse)
            selected
            isGhost
            isEditMode
            scale
    else
        ObjectView.viewDesk
            eventOptions
            isEditMode
            (positionOf object)
            (sizeOf object)
            (backgroundColorOf object)
            (nameOf object)
            (fontSizeOf object)
            selected
            isGhost
            scale
            (Object.relatedPerson object /= Nothing)


view : Model -> Html Msg
view model =
    case Model.getEditingFloor model of
        Just floor ->
            let
                isRangeSelectMode =
                    Mode.isSelectMode model.mode && model.ctrl
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
                ]
                []


pasteHandler : Html Msg
pasteHandler =
    div
        [ id "paste-handler"
        , attribute "contenteditable" ""
        , maxlength 0
        , style pasteHandlerStyle
        , onWithOptions "keydown" { preventDefault = True, stopPropagation = True } KeyOperation.decodeOperation
        , onWithOptions "paste" { preventDefault = True, stopPropagation = True } (ClipboardData.decode PasteFromClipboard)
        ]
        []


pasteHandlerStyle : List ( String, String )
pasteHandlerStyle =
    [ ( "position", "absolute" )
    , ( "top", "0" )
    , ( "left", "0" )
    , ( "width", "100%" )
    , ( "height", "100%" )
    , ( "color", "transparent" )
    ]


profilePopupView : Model -> Floor -> Html Msg
profilePopupView model floor =
    if Mode.isPrintMode model.mode then
        text ""
    else
        model.selectedResult
            |> Maybe.andThen
                (\objectId ->
                    Floor.getObject objectId floor
                        |> Maybe.andThen
                            (\object ->
                                case Object.relatedPerson object of
                                    Just personId ->
                                        Dict.get personId model.personInfo
                                            |> Maybe.map
                                                (\person ->
                                                    ProfilePopup.view ClosePopup model.transition model.scale model.offset object (Just person)
                                                )

                                    Nothing ->
                                        Just (ProfilePopup.view ClosePopup model.transition model.scale model.offset object Nothing)
                            )
                )
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
            [ ( "canvas-image", Lazy.lazy2 canvasImage model floor )
            , ( "name-input"
              , if isEditMode then
                    nameInput
                else
                    text ""
              )
            ]

        position =
            Scale.imageToScreenForPosition
                model.scale
                model.offset

        size =
            Scale.screenToImageForSize
                model.scale
                (Size (Floor.width floor) (Floor.height floor))

        children2 =
            [ ( "paste-handler"
              , pasteHandler
                    |> Html.map
                        (\msg ->
                            case msg of
                                Copy ->
                                    execCopy (Model.selectedObjects model |> ClipboardData.fromObjects) Copy

                                Cut ->
                                    execCopy (Model.selectedObjects model |> ClipboardData.fromObjects) Cut

                                x ->
                                    x
                        )
              )
            , ( "svg-canvas"
              , Svg.Keyed.node "svg"
                    [ id "svg-canvas"
                    , VirtualDom.attributeNS "xmlns" "xlink" "http://www.w3.org/1999/xlink"
                    , style
                        [ ( "position", "absolute" )
                        , ( "display", "block" )
                        , ( "left", "0" )
                        , ( "top", "0" )
                        , ( "width", "100%" )
                        , ( "height", "100%" )
                        , ( "overflow", "visible" )
                        ]
                    , Svg.Attributes.width (toString <| Floor.width floor)
                    , Svg.Attributes.height (toString <| Floor.height floor)
                    , Svg.Attributes.viewBox (String.join " " <| List.map toString [ 0, 0, Floor.width floor, Floor.height floor ])
                    , onMouseDown FocusCanvas
                    ]
                    (( "canvas-selector-rect", Lazy.lazy3 selectorRectView model.mode model.scale model.selectorRect )
                        :: ( "grid-layer", gridLayer )
                        :: objectsView model floor
                        ++ children3
                    )
              )
            ]

        children3 =
            if isEditMode then
                ( "canvas-temporary-pen", temporaryPenView model ) :: temporaryStampsView model
            else
                []
    in
        Keyed.node
            "div"
            [ style (canvasViewStyles model floor)
            ]
            (children1 ++ children2 ++ children3)


execCopy : String -> msg -> msg
execCopy s msg =
    let
        _ =
            Native.ClipboardData.execCopy s
    in
        msg


canvasViewStyles : Model -> Floor -> List ( String, String )
canvasViewStyles model floor =
    let
        position =
            Scale.imageToScreenForPosition
                model.scale
                model.offset

        size2 =
            Scale.imageToScreenForSize
                model.scale
                (Size (Floor.width floor) (Floor.height floor))
    in
        [ ( "position", "absolute" )
        , ( "left", px position.x )
        , ( "top", px position.y )
        , ( "width", px <| size2.width )
        , ( "height", px <| size2.height )
        , ( "font-family", "default" )
        , ( "background-color", "black" )
        , ( "transition"
          , if model.transition then
                "top 0.3s ease, left 0.3s ease"
            else
                ""
          )
        ]
            ++ CommonStyles.noUserSelect
            ++ (if Mode.isViewMode model.mode then
                    [ ( "overflow", "hidden" ) ]
                else
                    []
               )


objectsView : Model -> Floor -> List ( String, Html Msg )
objectsView model floor =
    if Mode.isPrintMode model.mode then
        List.map
            (\object ->
                ( Object.idOf object
                , lazy2 printModeObjectView model.scale object
                )
            )
            (Floor.objects floor)
    else if Mode.isViewMode model.mode then
        List.map
            (\object ->
                ( Object.idOf object
                , lazy2 viewModeObjectView model.scale object
                )
            )
            (Floor.objects floor)
    else
        case model.draggingContext of
            MoveObject _ start ->
                objectsViewWhileMoving model floor start

            ResizeFromScreenPos id from ->
                objectsViewWhileResizing model floor id from

            _ ->
                Floor.objects floor
                    |> List.map
                        (\object ->
                            ( object, List.member (Object.idOf object) model.selectedObjects )
                        )
                    |> List.sortBy compareZIndex
                    |> List.map
                        (\( object, selected ) ->
                            ( Object.idOf object
                            , lazy3 nonGhostOjectView
                                model.scale
                                selected
                                object
                            )
                        )


compareZIndex : ( Object, Bool ) -> Int
compareZIndex ( object, selected ) =
    (if Object.isLabel object then
        1
     else
        0
    )
        + (if selected then
            2
           else
            0
          )


objectsViewWhileMoving : Model -> Floor -> Position -> List ( String, Html Msg )
objectsViewWhileMoving model floor start =
    let
        objectList =
            Floor.objects floor

        isSelected object =
            List.member (Object.idOf object) model.selectedObjects

        ghostsView =
            List.map
                (\object ->
                    ( Object.idOf object ++ "ghost"
                    , lazy2 ghostObjectView model.scale object
                    )
                )
                (List.filter isSelected objectList)

        adjustPosition object =
            if isSelected object then
                let
                    newPosition =
                        adjustImagePositionOfMovingObject
                            model.gridSize
                            model.scale
                            start
                            model.mousePosition
                            (Object.positionOf object)
                in
                    Object.changePosition newPosition object
            else
                object

        normalView =
            objectList
                |> List.map
                    (\object ->
                        ( object, isSelected object )
                    )
                |> List.sortBy compareZIndex
                |> List.map
                    (\( object, selected ) ->
                        ( Object.idOf object
                        , lazy3 nonGhostOjectView
                            model.scale
                            selected
                            (adjustPosition object)
                        )
                    )
    in
        (ghostsView ++ normalView)


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


objectsViewWhileResizing : Model -> Floor -> ObjectId -> Position -> List ( String, Html Msg )
objectsViewWhileResizing model floor id from =
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
                    , lazy2 ghostObjectView model.scale object
                    )
                )
                (List.filter isResizing objectList)

        adjustRect object =
            if isResizing object then
                Model.temporaryResizeRect model from (Object.positionOf object) (Object.sizeOf object)
                    |> Maybe.map (\( pos, size ) -> object |> Object.changePosition pos |> Object.changeSize size)
                    |> Maybe.withDefault object
                -- TODO don't allow 0 width/height objects
            else
                object

        normalView =
            objectList
                |> List.map
                    (\object ->
                        ( object, isSelected object )
                    )
                |> List.sortBy compareZIndex
                |> List.map
                    (\( object, selected ) ->
                        ( Object.idOf object
                        , lazy3 nonGhostOjectView
                            model.scale
                            (isResizing object)
                            --TODO seems not selected?
                            (adjustRect object)
                        )
                    )
    in
        normalView ++ ghostsView


canvasImage : Model -> Floor -> Html msg
canvasImage model floor =
    let
        size =
            Scale.imageToScreenForSize
                model.scale
                (Size (Floor.width floor) (Floor.height floor))
    in
        img
            [ style (canvasImageStyle floor.flipImage size)
            , src (Maybe.withDefault "" (Floor.src floor))
            ]
            []


canvasImageStyle : Bool -> Size -> List ( String, String )
canvasImageStyle flipImage size =
    [ ( "position", "absolute" )
    , ( "top", "0" )
    , ( "left", "0" )
    , ( "width", px <| size.width )
    , ( "height", px <| size.height )
    , ( "background-color", "#fff" )
    , ( "pointer-events", "none" )
    , ( "transform"
      , if flipImage then
            "scale(-1,-1)"
        else
            ""
      )
    ]


temporaryStampsView : Model -> List ( String, Html msg )
temporaryStampsView model =
    Model.getPositionedPrototype model
        |> List.map (temporaryStampView model.scale False)


temporaryStampView : Scale -> Bool -> PositionedPrototype -> ( String, Html msg )
temporaryStampView scale selected ( prototype, pos ) =
    -- TODO How about using prototype.id?
    ( "temporary_" ++ toString pos.x ++ "_" ++ toString pos.y ++ "_" ++ toString prototype.width ++ "_" ++ toString prototype.height
    , ObjectView.viewDesk
        ObjectView.noEvents
        False
        pos
        (Size prototype.width prototype.height)
        prototype.backgroundColor
        prototype.name
        --name
        Object.defaultFontSize
        selected
        False
        -- alpha
        scale
        False
      -- personMatched
    )


temporaryPenView : Model -> Html msg
temporaryPenView model =
    case model.draggingContext of
        PenFromScreenPos start ->
            case Model.temporaryPen model start of
                Just ( color, name, pos, size ) ->
                    ObjectView.viewDesk
                        ObjectView.noEvents
                        False
                        pos
                        size
                        color
                        name
                        --name
                        Object.defaultFontSize
                        False
                        -- selected
                        False
                        -- alpha
                        model.scale
                        False

                -- personMatched
                _ ->
                    text ""

        _ ->
            text ""


selectorRectView : Mode -> Scale -> Maybe ( Position, Size ) -> Html msg
selectorRectView mode scale selectorRect =
    case ( Mode.isSelectMode mode, selectorRect ) of
        ( True, Just ( pos, size ) ) ->
            Svg.rect
                [ Svg.Attributes.x (toString pos.x)
                , Svg.Attributes.y (toString pos.y)
                , Svg.Attributes.width (toString size.width)
                , Svg.Attributes.height (toString size.height)
                , Svg.Attributes.stroke (CommonStyles.selectColor)
                , Svg.Attributes.strokeWidth "3"
                , Svg.Attributes.fill "none"
                ]
                []

        _ ->
            text ""


canvasContainerStyle : Mode -> Bool -> List ( String, String )
canvasContainerStyle mode rangeSelectMode =
    let
        crosshair =
            rangeSelectMode || Mode.isLabelMode mode
    in
        [ ( "position", "relative" )
        , ( "background"
          , if Mode.isPrintMode mode then
                "#ddd"
            else
                "#000"
          )
        , ( "flex", "1" )
        , ( "cursor"
          , if crosshair then
                "crosshair"
            else
                "default"
          )
        ]
