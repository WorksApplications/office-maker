module Model.Model exposing (..)

import Date exposing (Date)
import Maybe
import Dict exposing (Dict)
import Time exposing (Time)

import Util.ShortCut as ShortCut
import Util.IdGenerator as IdGenerator exposing (Seed)
import Util.DictUtil as DictUtil

import Model.Direction exposing (..)
import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.ObjectsOperation as ObjectsOperation exposing (..)
import Model.Scale as Scale exposing (Scale)
import Model.Prototypes as Prototypes exposing (..)
import Model.Floor as Floor exposing (Floor)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.I18n as I18n exposing (Language)
import Model.SearchResult as SearchResult exposing (SearchResult)
import Model.ProfilePopupLogic as ProfilePopupLogic
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import Model.EditingFloor as EditingFloor exposing (EditingFloor)
import Model.EditMode as EditMode exposing (EditMode(..))

import API.API as API
import API.Cache as Cache exposing (Cache, UserState)

import Component.FloorProperty as FloorProperty exposing (FloorProperty)
import Component.ObjectNameInput as ObjectNameInput exposing (ObjectNameInput)
import Component.Header as Header


type alias Model =
  { apiConfig : API.Config
  , title : String
  , seed : Seed
  , visitDate : Date
  , user : User
  , pos : (Int, Int)
  , draggingContext : DraggingContext
  , selectedObjects : List Id
  , copiedObjects : List Object
  , objectNameInput : ObjectNameInput
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , keys : ShortCut.Model
  , editMode : EditMode
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
  , selectedResult : Maybe Id
  , personInfo : Dict String Person
  , diff : Maybe (Floor, Maybe Floor)
  , candidates : List Id
  , tab : Tab
  , clickEmulator : List (Id, Bool, Time)
  , candidateRequest : Dict Id (Maybe String)
  , personPopupSize : (Int, Int)
  , lang : Language
  , cache : Cache
  , headerState : Header.State
  }


type ContextMenu =
    NoContextMenu
  | Object (Int, Int) Id
  | FloorInfo (Int, Int) Id


type DraggingContext =
    NoDragging
  | MoveObject Id (Int, Int)
  | Selector
  | ShiftOffset
  | PenFromScreenPos (Int, Int)
  | StampFromScreenPos (Int, Int)
  | ResizeFromScreenPos Id (Int, Int)


type Tab =
  SearchTab | EditTab


gridSize : Int
gridSize = 8 -- 2^N


init : API.Config -> String -> (Int, Int) -> (Int, Int) -> Time -> Bool -> String -> Scale -> (Int, Int) -> Language -> Model
init apiConfig title initialSize randomSeed visitDate editMode query scale offset lang =
  let
    initialFloor =
      Floor.empty
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
    , editMode = if editMode then Select else Viewing False
    , colorPalette = ColorPalette.init []
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
    , tab = if editMode then EditTab else SearchTab
    , clickEmulator = []
    , candidateRequest = Dict.empty
    , personPopupSize = (300, 160)
    , lang = lang
    , cache = Cache.cache
    , headerState = Header.init
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
      case model.selectorRect of
        Just (left, top, width, height) ->
          let
            floor =
              getEditingFloorOrDummy model

            objects =
              withinRect
                (toFloat left, toFloat top)
                (toFloat (left + width), toFloat (top + height))
                floor.objects
          in
            List.map idOf objects

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
      findObjectById (getEditingFloorOrDummy model).objects id `Maybe.andThen` \obj ->
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
    island' =
      island
        [object]
        (List.filter (\e -> (idOf e) /= (idOf object)) allObjects)
  in
    case ObjectsOperation.nearest Down object island' of
      Just e ->
        if idOf object == idOf e then
          Nothing
        else
          Just e
      _ ->
        Nothing


candidatesOf : Model -> List Person
candidatesOf model =
  List.filterMap (\personId -> Dict.get personId model.personInfo) model.candidates


shiftSelectionToward : Direction -> Model -> Model
shiftSelectionToward direction model =
  let
    floor = getEditingFloorOrDummy model

    selected = selectedObjects model
  in
    case selected of
      primary :: tail ->
        let
          toBeSelected =
            if model.keys.shift then
              List.map idOf <|
                expandOrShrink direction primary selected floor.objects
            else
              case nearest direction primary floor.objects of
                Just e ->
                  let
                    newObjects = [e]
                  in
                    List.map idOf newObjects

                _ ->
                  model.selectedObjects
        in
          { model |
            selectedObjects = toBeSelected
          }
      _ -> model


-- TODO bad naming
isSelected : Model -> Object -> Bool
isSelected model object =
  EditMode.isEditMode model.editMode && List.member (idOf object) model.selectedObjects


primarySelectedObject : Model -> Maybe Object
primarySelectedObject model =
  case model.selectedObjects of
    head :: _ ->
      findObjectById (Floor.objects <| (getEditingFloorOrDummy model)) head
    _ -> Nothing


selectedObjects : Model -> List Object
selectedObjects model =
  List.filterMap (\id ->
    findObjectById (getEditingFloorOrDummy model).objects id
  ) model.selectedObjects


screenToImageWithOffset : Scale -> (Int, Int) -> (Int, Int) -> (Int, Int)
screenToImageWithOffset scale (screenX, screenY) (offsetX, offsetY) =
    ( Scale.screenToImage scale screenX - offsetX
    , Scale.screenToImage scale screenY - offsetY
    )


stampCandidates : Model -> List StampCandidate
stampCandidates model =
  case model.editMode of
    Stamp ->
      let
        prototype =
          selectedPrototype model.prototypes

        (offsetX, offsetY) = model.offset

        (x2, y2) =
          model.pos

        (x2', y2') =
          screenToImageWithOffset model.scale (x2, y2) (offsetX, offsetY)
      in
        case model.draggingContext of
          StampFromScreenPos (x1, y1) ->
            let
              (x1', y1') =
                screenToImageWithOffset model.scale (x1, y1) (offsetX, offsetY)
            in
              stampCandidatesOnDragging model.gridSize prototype (x1', y1') (x2', y2')

          _ ->
            let
              (deskWidth, deskHeight) = prototype.size

              (left, top) =
                fitPositionToGrid model.gridSize (x2' - deskWidth // 2, y2' - deskHeight // 2)
            in
              [ (prototype, (left, top))
              ]
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
      fitPositionToGrid model.gridSize <|
        screenToImageWithOffset model.scale from model.offset

    (right, bottom) =
      fitPositionToGrid model.gridSize <|
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
      fitPositionToGrid model.gridSize <|
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
