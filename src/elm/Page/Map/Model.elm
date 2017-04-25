module Page.Map.Model exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Time exposing (Time)
import ContextMenu exposing (ContextMenu)
import Debounce exposing (Debounce)
import Util.IdGenerator as IdGenerator exposing (Seed)
import Util.DictUtil as DictUtil
import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (Object)
import Model.ObjectsOperation as ObjectsOperation
import Model.Scale as Scale exposing (Scale)
import Model.Prototype as Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (Prototypes, PositionedPrototype)
import Model.Floor as Floor exposing (Floor)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.I18n as I18n exposing (Language)
import Model.SearchResult as SearchResult exposing (SearchResult, SearchResultsForOnePost)
import Model.ProfilePopupLogic as ProfilePopupLogic
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import Model.EditingFloor as EditingFloor exposing (EditingFloor)
import Model.Mode as Mode exposing (Mode(..), EditingMode(..))
import Model.SaveRequest as SaveRequest exposing (SaveRequest(..))
import API.API as API
import API.Cache as Cache exposing (Cache, UserState)
import Component.FloorProperty as FloorProperty exposing (FloorProperty)
import Component.Header as Header
import Component.FloorDeleter as FloorDeleter exposing (FloorDeleter)
import Page.Map.ObjectNameInput as ObjectNameInput exposing (ObjectNameInput)
import Page.Map.ContextMenuContext exposing (ContextMenuContext)
import Page.Map.URL as URL exposing (URL)
import Page.Map.ClipboardOptionsView as ClipboardOptionsView
import CoreType exposing (..)


type alias Model =
    { apiConfig : API.Config
    , title : String
    , seed : Seed
    , visitDate : Date
    , user : User
    , mousePosition : Position
    , draggingContext : DraggingContext
    , selectedObjects : List ObjectId
    , objectNameInput : ObjectNameInput
    , gridSize : Int
    , selectorRect : Maybe ( Position, Size )
    , ctrl : Bool
    , mapFocused : Bool
    , mode : Mode
    , colorPalette : ColorPalette
    , contextMenu : ContextMenu ContextMenuContext
    , floor : Maybe EditingFloor
    , floorsInfo : Dict FloorId FloorInfo
    , windowSize : Size
    , scale : Scale
    , offset : Position
    , prototypes : Prototypes
    , clipboardOptionsForm : ClipboardOptionsView.Form
    , cellSizePerDesk : Size
    , error : GlobalError
    , floorProperty : FloorProperty
    , searchQuery : String
    , searchResult : Maybe (List SearchResult)
    , selectedResult : Maybe ObjectId
    , personInfo : Dict String Person
    , diff : Maybe ( Floor, Maybe Floor )
    , candidates : List PersonId
    , clickEmulator : List ( ObjectId, Bool, Time )
    , searchCandidateDebounce : Debounce ( Id, String )
    , lang : Language
    , cache : Cache
    , header : Header.Model
    , saveFloorDebounce : Debounce SaveRequest
    , floorDeleter : FloorDeleter
    , transition : Bool
    }


type DraggingContext
    = NoDragging
    | MoveObject Id Position
    | Selector
    | ShiftOffset Position
    | PenFromScreenPos Position
    | StampFromScreenPos Position
    | ResizeFromScreenPos Id Position
    | MoveFromSearchResult Prototype String
    | MoveExistingObjectFromSearchResult FloorId Time Prototype ObjectId


init :
    API.Config
    -> String
    -> Size
    -> ( Int, Int )
    -> Time
    -> Bool
    -> String
    -> Maybe String
    -> Scale
    -> Position
    -> Language
    -> ContextMenu ContextMenuContext
    -> Model
init apiConfig title initialSize randomSeed visitDate isEditMode query objectId scale offset lang contextMenu =
    let
        initialFloor =
            Floor.empty

        gridSize =
            8

        -- 2^N
    in
        { apiConfig = apiConfig
        , title = title
        , seed = IdGenerator.init randomSeed
        , visitDate = Date.fromTime visitDate
        , user = User.guest
        , mousePosition = (Position 0 0)
        , draggingContext = NoDragging
        , selectedObjects = []
        , objectNameInput = ObjectNameInput.init
        , gridSize = gridSize
        , selectorRect = Nothing
        , ctrl = False
        , mapFocused = False
        , mode = Mode.init False
        , colorPalette = ColorPalette.empty
        , contextMenu = contextMenu
        , floorsInfo = Dict.empty
        , floor = Nothing
        , windowSize = initialSize
        , scale = scale
        , offset = offset
        , prototypes = Prototypes.init []
        , clipboardOptionsForm = ClipboardOptionsView.init
        , cellSizePerDesk = Size 1 1
        , error = NoError
        , floorProperty = FloorProperty.init initialFloor.name 0 0 0
        , selectedResult = objectId
        , personInfo = Dict.empty
        , diff = Nothing
        , candidates = []
        , searchQuery = query
        , searchResult = Nothing
        , clickEmulator = []
        , searchCandidateDebounce = Debounce.init
        , lang = lang
        , cache = Cache.cache
        , header = Header.init
        , saveFloorDebounce = Debounce.init
        , floorDeleter = FloorDeleter.init
        , transition = False
        }


headerHeight : Int
headerHeight =
    37


sideMenuWidth : Int
sideMenuWidth =
    320


canvasPosition : Model -> Position
canvasPosition model =
    let
        pos =
            model.mousePosition
    in
        { pos | y = pos.y - headerHeight }


isMouseInCanvas : Model -> Bool
isMouseInCanvas model =
    model.mousePosition.x
        > 0
        && model.mousePosition.x
        < model.windowSize.width
        - sideMenuWidth
        && model.mousePosition.y
        > headerHeight
        && model.mousePosition.y
        < model.windowSize.height


updateSelectorRect : Position -> Model -> Model
updateSelectorRect canvasPosition model =
    { model
        | selectorRect =
            case model.selectorRect of
                Just ( pos, size ) ->
                    let
                        leftTop =
                            screenToImageWithOffset
                                model.scale
                                canvasPosition
                                model.offset

                        size =
                            Size (leftTop.x - pos.x) (leftTop.y - pos.y)
                    in
                        Just ( pos, size )

                _ ->
                    model.selectorRect
    }


syncSelectedByRect : Model -> Model
syncSelectedByRect model =
    { model
        | selectedObjects =
            case ( model.selectorRect, model.floor ) of
                ( Just ( pos, size ), Just efloor ) ->
                    let
                        floor =
                            EditingFloor.present efloor

                        objects =
                            ObjectsOperation.withinRect
                                ( toFloat pos.x, toFloat pos.y )
                                ( toFloat (pos.x + size.width), toFloat (pos.y + size.height) )
                                (Floor.objects floor)
                    in
                        List.map Object.idOf objects

                _ ->
                    model.selectedObjects
    }


startEdit : Object -> Model -> Model
startEdit e model =
    { model
        | objectNameInput =
            ObjectNameInput.start ( Object.idOf e, Object.nameOf e ) model.objectNameInput
    }


adjustOffset : Bool -> Model -> Model
adjustOffset toCenter model =
    model.selectedResult
        |> Maybe.andThen
            (\id ->
                model.floor
                    |> Maybe.andThen
                        (\efloor ->
                            Floor.getObject id (EditingFloor.present efloor)
                                |> Maybe.map
                                    (\obj ->
                                        if toCenter then
                                            let
                                                objectSize =
                                                    Object.sizeOf obj

                                                objectPosition =
                                                    Object.positionOf obj

                                                objectCenter =
                                                    Position (objectPosition.x + objectSize.width // 2) (objectPosition.y + objectSize.height // 2)
                                                        |> Scale.imageToScreenForPosition model.scale

                                                windowCenter =
                                                    Position (model.windowSize.width // 2) (model.windowSize.height // 2)
                                            in
                                                Position (windowCenter.x - objectCenter.x) (windowCenter.y - objectCenter.y)
                                                    |> Scale.screenToImageForPosition model.scale
                                        else
                                            let
                                                containerSize =
                                                    Size
                                                        (model.windowSize.width)
                                                        (model.windowSize.height - headerHeight - 30)
                                            in
                                                ProfilePopupLogic.adjustOffset
                                                    containerSize
                                                    ProfilePopupLogic.personPopupSize
                                                    model.scale
                                                    model.offset
                                                    obj
                                    )
                        )
            )
        |> Maybe.withDefault model.offset
        |> (\shiftedOffset -> { model | offset = shiftedOffset })


nextObjectToInput : Object -> List Object -> Maybe Object
nextObjectToInput object allObjects =
    let
        island =
            ObjectsOperation.island
                [ object ]
                (List.filter (\o -> Object.idOf o /= Object.idOf object) allObjects)
    in
        ObjectsOperation.nearest Down object island
            |> Maybe.andThen
                (\o ->
                    if Object.idOf object == Object.idOf o then
                        Nothing
                    else
                        Just o
                )


candidatesOf : Model -> List Person
candidatesOf model =
    model.candidates
        |> List.filterMap (\personId -> Dict.get personId model.personInfo)


shiftSelectionToward : Direction -> Model -> Model
shiftSelectionToward direction model =
    model.floor
        |> Maybe.map EditingFloor.present
        |> Maybe.andThen
            (\floor ->
                List.head (selectedObjects model)
                    |> Maybe.andThen
                        (\primarySelected ->
                            ObjectsOperation.nearest direction primarySelected (Floor.objects floor)
                                |> Maybe.map
                                    (\object ->
                                        { model
                                            | selectedObjects =
                                                List.map Object.idOf [ object ]
                                        }
                                    )
                        )
            )
        |> Maybe.withDefault model


expandOrShrinkToward : Direction -> Model -> Model
expandOrShrinkToward direction model =
    model.floor
        |> Maybe.map EditingFloor.present
        |> Maybe.map
            (\floor ->
                case selectedObjects model of
                    primarySelected :: _ ->
                        { model
                            | selectedObjects =
                                List.map Object.idOf <|
                                    ObjectsOperation.expandOrShrinkToward
                                        direction
                                        primarySelected
                                        (Floor.getObjects model.selectedObjects floor)
                                        (Floor.objects floor)
                        }

                    _ ->
                        model
            )
        |> Maybe.withDefault model


primarySelectedObject : Model -> Maybe Object
primarySelectedObject model =
    List.head (selectedObjects model)


selectedObjects : Model -> List Object
selectedObjects model =
    model.floor
        |> Maybe.map EditingFloor.present
        |> Maybe.map (Floor.getObjects model.selectedObjects)
        |> Maybe.withDefault []


screenToImageWithOffset : Scale -> Position -> Position -> Position
screenToImageWithOffset scale screenPosition offset =
    Position
        (Scale.screenToImage scale screenPosition.x - offset.x)
        (Scale.screenToImage scale screenPosition.y - offset.y)


getPositionedPrototype : Model -> List PositionedPrototype
getPositionedPrototype model =
    let
        prototype =
            Prototypes.selectedPrototype model.prototypes

        xy2 =
            screenToImageWithOffset model.scale (canvasPosition model) model.offset
    in
        case ( Mode.isStampMode model.mode, model.draggingContext ) of
            ( _, MoveFromSearchResult prototype _ ) ->
                let
                    fitted =
                        ObjectsOperation.fitPositionToGrid
                            model.gridSize
                            (Position (xy2.x - prototype.width // 2) (xy2.y - prototype.height // 2))
                in
                    [ ( prototype, fitted ) ]

            ( _, MoveExistingObjectFromSearchResult floorId _ prototype _ ) ->
                let
                    fitted =
                        ObjectsOperation.fitPositionToGrid
                            model.gridSize
                            (Position (xy2.x - prototype.width // 2) (xy2.y - prototype.height // 2))
                in
                    [ ( prototype, fitted ) ]

            ( True, StampFromScreenPos start ) ->
                let
                    xy1 =
                        screenToImageWithOffset model.scale start model.offset
                in
                    Prototypes.positionedPrototypesOnDragging model.gridSize prototype xy1 xy2

            ( True, _ ) ->
                let
                    fitted =
                        ObjectsOperation.fitPositionToGrid
                            model.gridSize
                            (Position (xy2.x - prototype.width // 2) (xy2.y - prototype.height // 2))
                in
                    [ ( prototype, fitted ) ]

            _ ->
                []


temporaryPen : Model -> Position -> Maybe ( String, String, Position, Size )
temporaryPen model from =
    temporaryPenRect model from
        |> Maybe.map (\( pos, size ) -> ( "#fff", "", pos, size ))



-- TODO color


temporaryPenRect : Model -> Position -> Maybe ( Position, Size )
temporaryPenRect model from =
    let
        leftTop =
            ObjectsOperation.fitPositionToGrid model.gridSize <|
                screenToImageWithOffset model.scale from model.offset

        rightBottom =
            ObjectsOperation.fitPositionToGrid model.gridSize <|
                screenToImageWithOffset model.scale (canvasPosition model) model.offset
    in
        validateRect leftTop rightBottom


temporaryResizeRect : Model -> Position -> Position -> Size -> Maybe ( Position, Size )
temporaryResizeRect model fromScreen objPos objSize =
    let
        toScreen =
            canvasPosition model

        dx =
            toScreen.x - fromScreen.x

        dy =
            toScreen.y - fromScreen.y

        rightBottom =
            ObjectsOperation.fitPositionToGrid model.gridSize <|
                (Position
                    (objPos.x + objSize.width + Scale.screenToImage model.scale dx)
                    (objPos.y + objSize.height + Scale.screenToImage model.scale dy)
                )
    in
        validateRect objPos rightBottom


validateRect : Position -> Position -> Maybe ( Position, Size )
validateRect leftTop rightBottom =
    let
        width =
            rightBottom.x - leftTop.x

        height =
            rightBottom.y - leftTop.y
    in
        if width > 0 && height > 0 then
            Just ( leftTop, Size width height )
        else
            Nothing


cachePeople : List Person -> Model -> Model
cachePeople people model =
    { model
        | personInfo =
            DictUtil.addAll (.id) people model.personInfo
    }


getEditingFloorOrDummy : Model -> Floor
getEditingFloorOrDummy model =
    getEditingFloor model
        |> Maybe.withDefault Floor.empty


getEditingFloor : Model -> Maybe Floor
getEditingFloor model =
    model.floor
        |> Maybe.map EditingFloor.present


toUrl : Model -> URL
toUrl model =
    { floorId = Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor
    , query =
        if String.length model.searchQuery == 0 then
            Nothing
        else
            Just model.searchQuery
    , objectId =
        model.selectedResult
    , editMode =
        Mode.isEditMode model.mode
    }


encodeToUrl : Model -> String
encodeToUrl =
    (URL.stringify ".") << toUrl



--
