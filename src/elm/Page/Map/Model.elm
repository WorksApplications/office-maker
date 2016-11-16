module Page.Map.Model exposing (..)

import Date exposing (Date)
import Maybe
import Dict exposing (Dict)
import Time exposing (Time)
import Debounce exposing (Debounce)

import Util.ShortCut as ShortCut
import Util.IdGenerator as IdGenerator exposing (Seed)
import Util.DictUtil as DictUtil

import Model.Direction exposing (..)
import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.ObjectsOperation as ObjectsOperation
import Model.Scale as Scale exposing (Scale)
import Model.Prototype as Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (..)
import Model.Floor as Floor exposing (Floor)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.I18n as I18n exposing (Language)
import Model.SearchResult as SearchResult exposing (SearchResult, SearchResultsForOnePost)
import Model.ProfilePopupLogic as ProfilePopupLogic
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import Model.EditingFloor as EditingFloor exposing (EditingFloor)
import Model.Mode as Mode exposing (Mode(..), EditingMode(..), Tab(..))
import Model.SaveRequest as SaveRequest exposing (SaveRequest(..))

import API.API as API
import API.Cache as Cache exposing (Cache, UserState)

import Component.FloorProperty as FloorProperty exposing (FloorProperty)
import Component.ObjectNameInput as ObjectNameInput exposing (ObjectNameInput)
import Component.Header as Header


type alias ObjectId = String
type alias FloorId = String


type alias Model =
  { apiConfig : API.Config
  , title : String
  , seed : Seed
  , visitDate : Date
  , user : User
  , pos : (Int, Int)
  , draggingContext : DraggingContext
  , selectedObjects : List ObjectId
  , copiedObjects : List Object
  , objectNameInput : ObjectNameInput
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , keys : ShortCut.Model
  , mode : Mode
  , colorPalette : ColorPalette
  , contextMenu : ContextMenu
  , floor : Maybe EditingFloor
  , floorsInfo : List FloorInfo
  , windowSize : (Int, Int)
  , scale : Scale
  , offset : (Int, Int)
  , scaling : Bool
  , prototypes : Prototypes
  , error : GlobalError
  , floorProperty : FloorProperty
  , searchQuery : String
  , searchResult : Maybe (List SearchResult)
  , selectedResult : Maybe ObjectId
  , personInfo : Dict String Person
  , diff : Maybe (Floor, Maybe Floor)
  , candidates : List Id
  , clickEmulator : List (ObjectId, Bool, Time)
  , searchCandidateDebounce : Debounce (Id, String)
  , personPopupSize : (Int, Int)
  , lang : Language
  , cache : Cache
  , headerState : Header.State
  , saveFloorDebounce : Debounce SaveRequest
  }


type ContextMenu
  = NoContextMenu
  | Object (Int, Int) Id
  | FloorInfo (Int, Int) Id


type DraggingContext
  = NoDragging
  | MoveObject Id (Int, Int)
  | Selector
  | ShiftOffset
  | PenFromScreenPos (Int, Int)
  | StampFromScreenPos (Int, Int)
  | ResizeFromScreenPos Id (Int, Int)
  | MoveFromSearchResult Prototype String
  | MoveExistingObjectFromSearchResult FloorId Time Prototype ObjectId


init : API.Config -> String -> (Int, Int) -> (Int, Int) -> Time -> Bool -> String -> Scale -> (Int, Int) -> Language -> Model
init apiConfig title initialSize randomSeed visitDate isEditMode query scale offset lang =
  let
    initialFloor =
      Floor.empty

    gridSize = 8  -- 2^N
  in
    { apiConfig = apiConfig
    , title = title
    , seed = IdGenerator.init randomSeed
    , visitDate = Date.fromTime visitDate
    , user = User.guest
    , pos = (0, 0)
    , draggingContext = NoDragging
    , selectedObjects = []
    , copiedObjects = []
    , objectNameInput = ObjectNameInput.init
    , gridSize = gridSize
    , selectorRect = Nothing
    , keys = ShortCut.init
    , mode = if isEditMode then Editing EditTab Select else Viewing False
    , colorPalette = ColorPalette.empty
    , contextMenu = NoContextMenu
    , floorsInfo = []
    , floor = Nothing
    , windowSize = initialSize
    , scale = scale
    , offset = offset
    , scaling = False
    , prototypes = Prototypes.init []
    , error = NoError
    , floorProperty = FloorProperty.init initialFloor.name 0 0 0
    , selectedResult = Nothing
    , personInfo = Dict.empty
    , diff = Nothing
    , candidates = []
    , searchQuery = query
    , searchResult = Nothing
    , clickEmulator = []
    , searchCandidateDebounce = Debounce.init
    , personPopupSize = (300, 160)
    , lang = lang
    , cache = Cache.cache
    , headerState = Header.init
    , saveFloorDebounce = Debounce.init
    }


updateSelectorRect : (Int, Int) -> Model -> Model
updateSelectorRect (canvasX, canvasY) model =
  { model |
    selectorRect =
      case model.selectorRect of
        Just (x, y, _, _) ->
          let
            (left, top) =
              screenToImageWithOffset model.scale (canvasX, canvasY) model.offset

            (w, h) =
              (left - x, top - y)
          in
            Just (x, y, w, h)

        _ ->
          model.selectorRect
  }


syncSelectedByRect : Model -> Model
syncSelectedByRect model =
  { model |
    selectedObjects =
      case (model.selectorRect, model.floor) of
        (Just (left, top, width, height), Just efloor) ->
          let
            floor =
              EditingFloor.present efloor

            objects =
              ObjectsOperation.withinRect
                (toFloat left, toFloat top)
                (toFloat (left + width), toFloat (top + height))
                (Floor.objects floor)
          in
            List.map Object.idOf objects

        _ ->
          model.selectedObjects
  }


updateOffsetByScreenPos : (Int, Int) -> Model -> Model
updateOffsetByScreenPos (x, y) model =
  { model |
    offset =
      let
        (prevX, prevY) =
          model.pos

        (offsetX, offsetY) =
          model.offset

        (dx, dy) =
          ((x - prevX), (y - prevY))
      in
        ( offsetX + Scale.screenToImage model.scale dx
        , offsetY + Scale.screenToImage model.scale dy
        )
  }


startEdit : Object -> Model -> Model
startEdit e model =
  { model |
    objectNameInput =
      ObjectNameInput.start (idOf e, nameOf e) model.objectNameInput
  }


adjustOffset : Model -> Model
adjustOffset model =
  let
    maybeShiftedOffset =
      model.selectedResult `Maybe.andThen` \id ->
      model.floor `Maybe.andThen` \efloor ->
      Floor.getObject id (EditingFloor.present efloor) `Maybe.andThen` \obj ->
      relatedPerson obj `Maybe.andThen` \personId ->
        Just <|
          let
            (windowWidth, windowHeight) =
              model.windowSize
            containerWidth = windowWidth - 320 --TODO
            containerHeight = windowHeight - 37 --TODO
          in
            ProfilePopupLogic.adjustOffset
              (containerWidth, containerHeight)
              model.personPopupSize
              model.scale
              model.offset
              obj
  in
    { model |
      offset = Maybe.withDefault model.offset maybeShiftedOffset
    }


nextObjectToInput : Object -> List Object -> Maybe Object
nextObjectToInput object allObjects =
  let
    island =
      ObjectsOperation.island
        [object]
        (List.filter (\o -> (Object.idOf o) /= (Object.idOf object)) allObjects)
  in
    case ObjectsOperation.nearest Down object island of
      Just o ->
        if Object.idOf object == Object.idOf o then
          Nothing
        else
          Just o

      _ ->
        Nothing


candidatesOf : Model -> List Person
candidatesOf model =
  List.filterMap (\personId -> Dict.get personId model.personInfo) model.candidates


shiftSelectionToward : Direction -> Model -> Model
shiftSelectionToward direction model =
  model.floor
    |> (Maybe.map) EditingFloor.present
    |> (flip Maybe.andThen) (\floor -> List.head (selectedObjects model)
    |> (flip Maybe.andThen) (\primarySelected ->
      ObjectsOperation.nearest direction primarySelected (Floor.objects floor)
    |> Maybe.map (\object ->
      { model |
        selectedObjects =
          List.map Object.idOf [object]
      }
      )))
    |> Maybe.withDefault model


expandOrShrinkToward : Direction -> Model -> Model
expandOrShrinkToward direction model =
  model.floor
    |> (Maybe.map) EditingFloor.present
    |> (Maybe.map) (\floor ->
      case selectedObjects model of
        primarySelected :: _ ->
          { model |
            selectedObjects =
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


screenToImageWithOffset : Scale -> (Int, Int) -> (Int, Int) -> (Int, Int)
screenToImageWithOffset scale (screenX, screenY) (offsetX, offsetY) =
    ( Scale.screenToImage scale screenX - offsetX
    , Scale.screenToImage scale screenY - offsetY
    )


getPositionedPrototype : Model -> List PositionedPrototype
getPositionedPrototype model =
  let
    prototype =
      selectedPrototype model.prototypes

    (offsetX, offsetY) = model.offset

    (x2, y2) =
      model.pos

    (x2', y2') =
      screenToImageWithOffset model.scale (x2, y2) (offsetX, offsetY)
  in
    case (Mode.isStampMode model.mode, model.draggingContext) of
      (_, MoveFromSearchResult prototype _) ->
        let
          (left, top) =
            ObjectsOperation.fitPositionToGrid model.gridSize (x2' - prototype.width // 2, y2' - prototype.height // 2)
        in
          [ (prototype, (left, top)) ]

      (_, MoveExistingObjectFromSearchResult floorId _ prototype _) ->
        let
          (left, top) =
            ObjectsOperation.fitPositionToGrid model.gridSize (x2' - prototype.width // 2, y2' - prototype.height // 2)
        in
          [ (prototype, (left, top)) ]

      (True, StampFromScreenPos (x1, y1)) ->
        let
          (x1', y1') =
            screenToImageWithOffset model.scale (x1, y1) (offsetX, offsetY)
        in
          positionedPrototypesOnDragging model.gridSize prototype (x1', y1') (x2', y2')

      (True, _) ->
        let
          (left, top) =
            ObjectsOperation.fitPositionToGrid model.gridSize (x2' - prototype.width // 2, y2' - prototype.height // 2)
        in
          [ (prototype, (left, top)) ]

      _ -> []


temporaryPen : Model -> (Int, Int) -> Maybe (String, String, (Int, Int, Int, Int))
temporaryPen model from =
  Maybe.map
    (\rect -> ("#fff", "", rect)) -- TODO color
    (temporaryPenRect model from)


temporaryPenRect : Model -> (Int, Int) -> Maybe (Int, Int, Int, Int)
temporaryPenRect model from =
  let
    (left, top) =
      ObjectsOperation.fitPositionToGrid model.gridSize <|
        screenToImageWithOffset model.scale from model.offset

    (right, bottom) =
      ObjectsOperation.fitPositionToGrid model.gridSize <|
        screenToImageWithOffset model.scale model.pos model.offset
  in
    validateRect (left, top, right, bottom)


temporaryResizeRect : Model -> (Int, Int) -> (Int, Int, Int, Int) -> Maybe (Int, Int, Int, Int)
temporaryResizeRect model (fromScreenX, fromScreenY) (objLeft, objTop, objWidth, objHeight) =
  let
    (toScreenX, toScreenY) =
      model.pos

    (dx, dy) =
      (toScreenX - fromScreenX, toScreenY - fromScreenY)

    (right, bottom) =
      ObjectsOperation.fitPositionToGrid model.gridSize <|
        ( objLeft + objWidth + Scale.screenToImage model.scale dx
        , objTop + objHeight + Scale.screenToImage model.scale dy
        )
  in
    validateRect (objLeft, objTop, right, bottom)


validateRect : (Int, Int, Int, Int) -> Maybe (Int, Int, Int, Int)
validateRect (left, top, right, bottom) =
  let
    width = right - left
    height = bottom - top
  in
    if width > 0 && height > 0 then
      Just (left, top, width, height)
    else
      Nothing


registerPeople : List Person -> Model -> Model
registerPeople people model =
  { model |
    personInfo =
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



--
