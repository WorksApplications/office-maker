module Page.Map.Model exposing (..)

import Date exposing (Date)
import Maybe
import Dict exposing (Dict)
import Time exposing (Time)
import Mouse exposing (Position)
import ContextMenu exposing (ContextMenu)
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
import Component.ObjectNameInput as ObjectNameInput exposing (ObjectNameInput)
import Component.Header as Header
import Component.FloorDeleter as FloorDeleter exposing (FloorDeleter)

import Page.Map.ContextMenuContext exposing (ContextMenuContext)
import Page.Map.Emoji as Emoji exposing (Emoji)


type alias ObjectId = String
type alias FloorId = String

type alias Size =
  { width : Int
  , height : Int
  }


type alias Model =
  { apiConfig : API.Config
  , title : String
  , seed : Seed
  , visitDate : Date
  , user : User
  , mousePosition : Position
  , draggingContext : DraggingContext
  , selectedObjects : List ObjectId
  , copiedObjects : List Object
  , objectNameInput : ObjectNameInput
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , keys : ShortCut.Model
  , mode : Mode
  , colorPalette : ColorPalette
  , contextMenu : ContextMenu ContextMenuContext
  , floor : Maybe EditingFloor
  , floorsInfo : Dict FloorId FloorInfo
  , windowSize : Size
  , scale : Scale
  , offset : Position
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
  , header : Header.Model
  , saveFloorDebounce : Debounce SaveRequest
  , floorDeleter : FloorDeleter
  , emojiList : List Emoji
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


init
   : API.Config
  -> String
  -> Size
  -> (Int, Int)
  -> Time
  -> Bool
  -> String
  -> Scale
  -> Position
  -> Language
  -> ContextMenu ContextMenuContext
  -> Model
init apiConfig title initialSize randomSeed visitDate isEditMode query scale offset lang contextMenu =
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
    , mousePosition = { x = 0, y = 0 }
    , draggingContext = NoDragging
    , selectedObjects = []
    , copiedObjects = []
    , objectNameInput = ObjectNameInput.init
    , gridSize = gridSize
    , selectorRect = Nothing
    , keys = ShortCut.init
    , mode = Mode.init False
    , colorPalette = ColorPalette.empty
    , contextMenu = contextMenu
    , floorsInfo = Dict.empty
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
    , header = Header.init
    , saveFloorDebounce = Debounce.init
    , floorDeleter = FloorDeleter.init
    , emojiList = []
    }


headerHeight : Int
headerHeight = 37


sideMenuWidth : Int
sideMenuWidth = 320


canvasPosition : Model -> Position
canvasPosition model =
  let
    pos =
      model.mousePosition
  in
    { pos | y = pos.y - headerHeight }


isMouseInCanvas : Model -> Bool
isMouseInCanvas model =
  model.mousePosition.x > 0 &&
  model.mousePosition.x < model.windowSize.width - sideMenuWidth &&
  model.mousePosition.y > headerHeight &&
  model.mousePosition.y < model.windowSize.height


updateSelectorRect : Position -> Model -> Model
updateSelectorRect canvasPosition model =
  { model |
    selectorRect =
      case model.selectorRect of
        Just (x, y, _, _) ->
          let
            leftTop =
              screenToImageWithOffset
                model.scale
                canvasPosition
                model.offset

            width =
              leftTop.x - x

            height =
              leftTop.y - y
          in
            Just (x, y, width, height)

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


startEdit : Object -> Model -> Model
startEdit e model =
  { model |
    objectNameInput =
      ObjectNameInput.start (idOf e, nameOf e) model.objectNameInput
  }


adjustOffset : Model -> Model
adjustOffset model =
  let
    shiftedOffset =
      model.selectedResult
        |> Maybe.andThen (\id -> model.floor
        |> Maybe.andThen (\efloor -> Floor.getObject id (EditingFloor.present efloor)
        |> Maybe.andThen (\obj -> relatedPerson obj
        |> Maybe.map (\personId ->
            let
              containerWidth =
                model.windowSize.width - sideMenuWidth

              containerHeight =
                model.windowSize.height - headerHeight
            in
              ProfilePopupLogic.adjustOffset
                (containerWidth, containerHeight)
                model.personPopupSize
                model.scale
                model.offset
                obj
          ))))
        |> Maybe.withDefault model.offset
  in
    { model
      | offset = shiftedOffset
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
    |> Maybe.map EditingFloor.present
    |> Maybe.andThen (\floor -> List.head (selectedObjects model)
    |> Maybe.andThen (\primarySelected ->
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
    |> Maybe.map EditingFloor.present
    |> Maybe.map (\floor ->
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


screenToImageWithOffset : Scale -> Position -> Position -> Position
screenToImageWithOffset scale screenPosition offset =
  { x = Scale.screenToImage scale screenPosition.x - offset.x
  , y = Scale.screenToImage scale screenPosition.y - offset.y
  }


getPositionedPrototype : Model -> List PositionedPrototype
getPositionedPrototype model =
  let
    prototype =
      Prototypes.selectedPrototype model.prototypes

    xy2 =
      screenToImageWithOffset model.scale (canvasPosition model) model.offset
  in
    case (Mode.isStampMode model.mode, model.draggingContext) of
      (_, MoveFromSearchResult prototype _) ->
        let
          fitted =
            ObjectsOperation.fitPositionToGrid
              model.gridSize
              { x = xy2.x - prototype.width // 2
              , y = xy2.y - prototype.height // 2
              }
        in
          [ (prototype, (fitted.x, fitted.y)) ]

      (_, MoveExistingObjectFromSearchResult floorId _ prototype _) ->
        let
          fitted =
            ObjectsOperation.fitPositionToGrid
              model.gridSize
              { x = xy2.x - prototype.width // 2
              , y = xy2.y - prototype.height // 2
              }
        in
          [ (prototype, (fitted.x, fitted.y)) ]

      (True, StampFromScreenPos start) ->
        let
          xy1 =
            screenToImageWithOffset model.scale start model.offset
        in
          Prototypes.positionedPrototypesOnDragging model.gridSize prototype xy1 xy2

      (True, _) ->
        let
          fitted =
            ObjectsOperation.fitPositionToGrid
              model.gridSize
              { x = xy2.x - prototype.width // 2
              , y = xy2.y - prototype.height // 2
              }
        in
          [ (prototype, (fitted.x, fitted.y)) ]

      _ -> []


temporaryPen : Model -> Position -> Maybe (String, String, (Int, Int, Int, Int))
temporaryPen model from =
  Maybe.map
    (\rect -> ("#fff", "", rect)) -- TODO color
    (temporaryPenRect model from)


temporaryPenRect : Model -> Position -> Maybe (Int, Int, Int, Int)
temporaryPenRect model from =
  let
    leftTop =
      ObjectsOperation.fitPositionToGrid model.gridSize <|
        screenToImageWithOffset model.scale from model.offset

    rightBottom =
      ObjectsOperation.fitPositionToGrid model.gridSize <|
        screenToImageWithOffset model.scale (canvasPosition model) model.offset
  in
    validateRect (leftTop.x, leftTop.y, rightBottom.x, rightBottom.y)


temporaryResizeRect : Model -> Position -> (Int, Int, Int, Int) -> Maybe (Int, Int, Int, Int)
temporaryResizeRect model fromScreen (objLeft, objTop, objWidth, objHeight) =
  let
    toScreen =
      canvasPosition model

    dx =
      toScreen.x - fromScreen.x

    dy =
      toScreen.y - fromScreen.y

    rightBottom =
      ObjectsOperation.fitPositionToGrid model.gridSize <|
        { x = objLeft + objWidth + Scale.screenToImage model.scale dx
        , y = objTop + objHeight + Scale.screenToImage model.scale dy
        }
  in
    validateRect (objLeft, objTop, rightBottom.x, rightBottom.y)


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
