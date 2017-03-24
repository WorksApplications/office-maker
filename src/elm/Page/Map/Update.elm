port module Page.Map.Update exposing (..)

import Maybe
import Task exposing (Task, andThen, onError)
import Window

import Process
import Keyboard
import Dict exposing (Dict)
import Navigation exposing (Location)
import Time exposing (Time, second)
import Dom
import Mouse
import Debounce exposing (Debounce)
import ContextMenu

import Util.ShortCut as ShortCut
import Util.IdGenerator as IdGenerator exposing (Seed)
import Util.DictUtil as DictUtil
import Util.File as File exposing (..)
import Util.HttpUtil as HttpUtil

import Model.Direction as Direction exposing (..)
import Model.Mode as Mode exposing (Mode(..), EditingMode(..))
import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.ObjectsOperation as ObjectsOperation
import Model.Scale as Scale
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (Prototypes, PositionedPrototype)
import Model.Floor as Floor exposing (Floor)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.ObjectsChange as ObjectsChange exposing (ObjectsChange)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.I18n as I18n exposing (Language(..))
import Model.SaveRequest as SaveRequest exposing (SaveRequest(..), ReducedSaveRequest)
import Model.EditingFloor as EditingFloor exposing (EditingFloor)
import Model.ClipboardData as ClipboardData
import Model.SearchResult as SearchResult

import API.API as API
import API.Page as Page
import API.Cache as Cache exposing (Cache, UserState)

import Component.FloorProperty as FloorProperty
import Component.Header as Header
import Component.ImageLoader as ImageLoader
import Component.FloorDeleter as FloorDeleter

import Page.Map.Model as Model exposing (Model, DraggingContext(..))
import Page.Map.Msg exposing (Msg(..))
import Page.Map.URL as URL exposing (URL)
import Page.Map.LinkCopy as LinkCopy
import Page.Map.ObjectNameInput as ObjectNameInput

import CoreType exposing (..)


type alias Id = String


port removeToken : {} -> Cmd msg

port setSelectionStart : {} -> Cmd msg

port tokenRemoved : ({} -> msg) -> Sub msg

port undo : ({} -> msg) -> Sub msg

port redo : ({} -> msg) -> Sub msg

port clipboard : (String -> msg) -> Sub msg


type alias ObjectId = String
type alias PersonId = String


type alias Flags =
  { apiRoot : String
  , accountServiceRoot : String
  , authToken : String
  , title : String
  , initialSize : Size
  , randomSeed : (Int, Int)
  , visitDate : Float
  , lang : String
  }


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Window.resizes WindowSize
    , Keyboard.downs (KeyCodeMsg True)
    , Keyboard.ups (KeyCodeMsg False)
    , tokenRemoved (always TokenRemoved)
    , undo (always Undo)
    , redo (always Redo)
    , clipboard PasteFromClipboard
    , if model.draggingContext == NoDragging then
        Sub.none
      else
        Mouse.moves MouseMove
    , Mouse.downs MouseMove
    , Mouse.ups (always MouseUp)
    , Sub.map ContextMenuMsg (ContextMenu.subscriptions model.contextMenu)
    , Sub.map HeaderMsg (Header.subscriptions)
    , ObjectNameInput.subscriptions ObjectNameInputMsg
    ]


parseURL : Location -> Msg
parseURL location =
  URL.parse location |> UrlUpdate


init : Flags -> Location -> (Model, Cmd Msg)
init flags location =
  let
    urlResult =
      URL.parse location

    apiConfig =
      { apiRoot = flags.apiRoot
      , accountServiceRoot = flags.accountServiceRoot
      , token = flags.authToken
      } -- TODO

    userState =
      Cache.defaultUserState (if flags.lang == "ja" then JA else EN)

    (contextMenu, contextMenuMsg) = ContextMenu.init

    toModel url =
      Model.init
        apiConfig
        flags.title
        flags.initialSize
        flags.randomSeed
        flags.visitDate
        url.editMode
        (Maybe.withDefault "" url.query)
        url.objectId
        userState.scale
        userState.offset
        userState.lang
        contextMenu
  in
    case urlResult of
      Ok url ->
        (toModel url)
        ! [ initCmd apiConfig url.editMode userState url.floorId
          ]

      Err _ ->
        let
          url =
            URL.init

          model =
            toModel url
        in
          model !
            [ initCmd apiConfig url.editMode userState url.floorId
            , Navigation.modifyUrl (URL.stringify "/" url)
            , Cmd.map ContextMenuMsg contextMenuMsg
            ]


initCmd : API.Config -> Bool -> UserState -> Maybe String -> Cmd Msg
initCmd apiConfig needsEditMode defaultUserState selectedFloor =
  Cache.getWithDefault Cache.cache defaultUserState
    |> Task.andThen (\userState -> API.getAuth apiConfig
    |> Task.map (\user -> (userState, user)))
    |> performAPI (\(userState, user) -> Initialized selectedFloor needsEditMode userState user)


debug : Bool
debug = False -- || True


debugMsg : Msg -> Msg
debugMsg msg =
  if debug then
    case msg of
      MouseMove _ -> msg
      _ -> Debug.log "msg" msg
  else
    msg


performAPI : (a -> Msg) -> Task.Task API.Error a -> Cmd Msg
performAPI tagger task =
  task
    |> Task.map tagger
    |> Task.onError (\e -> Task.succeed (Error (APIError e)))
    |> Task.perform identity


saveFloorDebounceConfig : Debounce.Config Msg
saveFloorDebounceConfig =
  { strategy = Debounce.later (1 * second)
  , transform = SaveFloorDebounceMsg
  }


searchCandidateDebounceConfig : Debounce.Config Msg
searchCandidateDebounceConfig =
  { strategy = Debounce.soon (0.4 * second)
  , transform = SearchCandidateDebounceMsg
  }


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case debugMsg msg of
    NoOp ->
      model ! []

    UrlUpdate result ->
      case result of
        Ok newURL ->
          model ! []

        Err _ ->
          model ! [ Navigation.modifyUrl (URL.stringify "/" URL.init) ]

    MouseMove position ->
      let
        model_ =
          { model | mousePosition = position }

        canvasPosition =
          Model.canvasPosition model_

        newModel_ =
          case model.draggingContext of
            Selector ->
              Model.syncSelectedByRect <| Model.updateSelectorRect canvasPosition model_

            ShiftOffset prev ->
              let
                dx =
                  model.mousePosition.x - prev.x

                dy =
                  model.mousePosition.y - prev.y

                newOffset =
                  Position
                    ( model.offset.x + Scale.screenToImage model.scale dx )
                    ( model.offset.y + Scale.screenToImage model.scale dy )
              in
                { model_
                  | offset = newOffset
                  , draggingContext =
                      ShiftOffset model.mousePosition
                }

            _ ->
              model_
      in
        newModel_ ! []

    MouseUp ->
      let
        newModel =
          if Model.isMouseInCanvas model then
            model
          else
            { model | draggingContext = NoDragging }
      in
        newModel ! []

    Initialized selectedFloor needsEditMode userState user ->
      let
        needSearch =
          String.trim model.searchQuery /= ""

        mode =
          ( if not (User.isGuest user) then
              Mode.init needsEditMode
            else
              model.mode
          )
            |> (if needSearch then Mode.showSearchResult else identity)

        requestPrivateFloors =
          Mode.isEditMode mode

        searchCmd =
          if needSearch then
            search
              model.apiConfig
              requestPrivateFloors
              model.personInfo
              model.searchQuery
          else
            Cmd.none

        focusObjectCmd =
          if Mode.isEditMode mode then
            Cmd.none
          else
            model.selectedResult
              |> Maybe.map (\objectId ->
                API.getObject model.apiConfig objectId
                  |> performAPI (\maybeObject ->
                    maybeObject
                      |> Maybe.map (\object ->
                        SelectSearchResult objectId (Object.floorIdOf object) (Object.relatedPerson object)
                      )
                      |> Maybe.withDefault NoOp
                  )
              )
              |> Maybe.withDefault Cmd.none

        loadFloorCmd =
          selectedFloor
            |> Maybe.map (\floorId -> loadFloor model.apiConfig requestPrivateFloors floorId)
            |> Maybe.map (performAPI FloorLoaded)
            |> Maybe.withDefault Cmd.none

        loadSettingsCmd =
          if User.isGuest user then
            Cmd.none
          else
            Cmd.batch
              [ performAPI ColorsLoaded (API.getColors model.apiConfig)
              , performAPI PrototypesLoaded (API.getPrototypes model.apiConfig)
              ]
      in
        { model |
          user = user
        , scale = userState.scale
        , offset = userState.offset
        , lang = userState.lang
        , mode = mode
        }
        ! [ focusObjectCmd
          , searchCmd
          , performAPI FloorsInfoLoaded (API.getFloorsInfo model.apiConfig)
          , loadFloorCmd
          , loadSettingsCmd
          ]

    ColorsLoaded colorPalette ->
      { model | colorPalette = colorPalette } ! []

    PrototypesLoaded prototypeList ->
      { model | prototypes = Prototypes.init prototypeList } ! []

    FloorsInfoLoaded floors ->
      { model
        | floorsInfo =
            floors
              |> List.map (\floor -> (FloorInfo.idOf floor, floor))
              |> Dict.fromList
      } ! []

    FloorLoaded floor ->
      updateOnFloorLoaded floor model

    ImageSaved url width height ->
      case model.floor of
        Nothing ->
          model ! []

        Just floor ->
          let
            (newFloor, rawFloor) =
              EditingFloor.updateFloor
                (Floor.setImage url width height)
                floor

            saveCmd =
              requestSaveFloorCmd rawFloor
          in
            { model | floor = Just newFloor } ! [ saveCmd ]

    RequestSave request ->
      let
        (saveFloorDebounce, cmd) =
          Debounce.push
            saveFloorDebounceConfig
            request
            model.saveFloorDebounce
      in
        { model |
          saveFloorDebounce = saveFloorDebounce
        } ! [cmd]

    SaveFloorDebounceMsg msg ->
      let
        save head tail =
          batchSave
            model.apiConfig
            (SaveRequest.reduceRequest (head :: tail))

        (saveFloorDebounce, cmd) =
          Debounce.update
            saveFloorDebounceConfig
            (Debounce.takeAll save)
            msg
            model.saveFloorDebounce
      in
        { model |
          saveFloorDebounce = saveFloorDebounce
        } ! [cmd]

    ObjectsSaved change ->
      { model |
        floor = Maybe.map (EditingFloor.syncObjects change) model.floor
      }  ! []

    FloorSaved floorBase ->
      { model
      | floorsInfo = FloorInfo.mergeFloor floorBase model.floorsInfo
      } ! []

    FloorPublished floor ->
      { model |
        floor = Maybe.map (\_ -> EditingFloor.init floor) model.floor
      , error = Success ("Successfully published " ++ floor.name)
      } !
        [ performAPI FloorsInfoLoaded (API.getFloorsInfo model.apiConfig)
        , Process.sleep 3000.0
            |> Task.perform (\_ -> Error NoError)
        ]

    MouseDownOnObject lastTouchedId mousePosition ->
      let
        model0 =
          { model | mousePosition = mousePosition }

        canvasPosition =
          Model.canvasPosition model0

        (model_, cmd) =
          if ObjectNameInput.isEditing model0.objectNameInput then
            let
              (objectNameInput, ev) =
                ObjectNameInput.forceFinish model0.objectNameInput
            in
              case ev of
                Just (id, name) ->
                  updateOnFinishNameInput False id name { model0 | objectNameInput = objectNameInput }

                Nothing ->
                  { model0 | objectNameInput = objectNameInput } ! []
          else
            model0 ! []

        -- TODO
        help model =
          { model
          | selectedObjects =
              if model.keys.ctrl then
                if List.member lastTouchedId model.selectedObjects
                then List.filter ((/=) lastTouchedId) model.selectedObjects
                else lastTouchedId :: model.selectedObjects
              else if model.keys.shift then
                let
                  floor =
                    (Model.getEditingFloorOrDummy model)

                  objectsExcept target =
                    List.filter (\e -> idOf e /= idOf target) (Floor.objects floor)
                in
                  case (Floor.getObject lastTouchedId floor, Model.primarySelectedObject model) of
                    (Just object, Just primary) ->
                      List.map Object.idOf <|
                        primary :: ObjectsOperation.withinRange (primary, object) (objectsExcept primary) --keep primary

                    _ -> [lastTouchedId]
              else
                if List.member lastTouchedId model.selectedObjects
                then model.selectedObjects
                else [lastTouchedId]
          , draggingContext = MoveObject lastTouchedId model.mousePosition
          , selectorRect = Nothing
          }
      in
        help model_ ! [ cmd, emulateClick lastTouchedId True ]

    MouseUpOnObject lastTouchedId pos ->
      let
        (newModel, cmd) =
          updateOnMouseUp pos model
      in
        newModel ! [ cmd, emulateClick lastTouchedId False ]

    ClickOnCanvas ->
      model ! []
      -- { model
      --   | selectedObjects = []
      --   -- , selectedResult = Nothing
      -- } ! []

    MouseUpOnCanvas pos ->
      let
        (newModel, cmd1) =
          updateOnMouseUp pos model

        cmd2 =
          Task.perform (always NoOp) (putUserState newModel)
      in
        newModel ! [ cmd1, cmd2 ]

    MouseDownOnCanvas mousePosition ->
      let
        model0 =
          { model | mousePosition = mousePosition }

        canvasPosition =
          Model.canvasPosition model0

        selectorRect =
          if Mode.isSelectMode model0.mode then
            let
              fitted =
                ObjectsOperation.fitPositionToGrid model0.gridSize <|
                  Model.screenToImageWithOffset model0.scale canvasPosition model0.offset
            in
              Just (fitted, Size model0.gridSize model0.gridSize)
          else
            model0.selectorRect

        draggingContext =
          case Mode.currentEditMode model0.mode of
            Just Mode.Label ->
              NoDragging

            Just Stamp ->
              StampFromScreenPos canvasPosition

            Just Pen ->
              PenFromScreenPos canvasPosition

            Just Select ->
              if model0.keys.ctrl then
                Selector
              else
                ShiftOffset model0.mousePosition

            Nothing ->
              ShiftOffset model0.mousePosition

        (model_, cmd) =
          case ObjectNameInput.forceFinish model0.objectNameInput of
            (objectNameInput, Just (id, name)) ->
              updateOnFinishNameInput False id name { model0 | objectNameInput = objectNameInput }

            (objectNameInput, _) ->
              { model0 | objectNameInput = objectNameInput } ! []

        (model__, cmd2) =
          if Mode.isLabelMode model.mode then
            updateOnPuttingLabel model_
          else
            (model_, Cmd.none)

        newModel =
          { model__
            | selectorRect = selectorRect
            --  selectedObjects = []
            , draggingContext = draggingContext
          }
      in
        newModel ! [ cmd, cmd2 ]

    MouseDownOnResizeGrip id mousePosition ->
      let
        model0 =
          { model | mousePosition = mousePosition }

        (model_, cmd) =
          case ObjectNameInput.forceFinish model0.objectNameInput of
            (objectNameInput, Just (id, name)) ->
              updateOnFinishNameInput False id name { model0 | objectNameInput = objectNameInput }

            (objectNameInput, _) ->
              { model0 | objectNameInput = objectNameInput } ! []

        newModel =
          { model_ |
            selectedObjects = []
          , draggingContext = ResizeFromScreenPos id (Model.canvasPosition model_)
          }
      in
        newModel ! [ cmd ]

    StartEditObject objectId ->
      model.floor
        |> Maybe.andThen (\efloor ->
          Floor.getObject objectId (EditingFloor.present efloor)
            |> Maybe.map (\object ->
              let
                newModel =
                  Model.startEdit object
                    { model |
                      selectedResult = Nothing
                    }
              in
                newModel !
                  [ requestCandidate (idOf object) (nameOf object)
                  , focusCmd
                  ]
            )
        )
        |> Maybe.withDefault (model ! [])

    SelectBackgroundColor color ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.changeObjectBackgroundColor model.selectedObjects color)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    SelectColor color ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.changeObjectColor model.selectedObjects color)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    SelectShape shape ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.changeObjectShape model.selectedObjects shape)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    SelectFontSize fontSize ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.changeObjectFontSize model.selectedObjects fontSize)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    ObjectNameInputMsg message ->
      let
        (objectNameInput, event) =
          ObjectNameInput.update message model.objectNameInput

        model_ =
          { model |
            objectNameInput = objectNameInput
          }
      in
        case event of
          ObjectNameInput.OnInput id name ->
            model_.floor
              |> Maybe.andThen (EditingFloor.present >> Floor.getObject id)
              |> Maybe.andThen (\object ->
                if Object.isLabel object then
                  Nothing
                else
                  Just <| requestCandidate id name
              )
              |> Maybe.withDefault Cmd.none
              |> (,) model_

          ObjectNameInput.OnFinish objectId name candidateId ->
            case candidateId of
              Just personId ->
                updateOnSelectCandidate objectId personId model_

              Nothing ->
                updateOnFinishNameInput True objectId name model_

          ObjectNameInput.OnSelectCandidate objectId personId ->
            updateOnSelectCandidate objectId personId model_

          ObjectNameInput.OnUnsetPerson objectId ->
            case model_.floor of
              Nothing ->
                model_ ! []

              Just editingFloor ->
                let
                  (newFloor, objectsChange) =
                    EditingFloor.updateObjects
                      (Floor.unsetPerson objectId)
                      editingFloor

                  saveCmd =
                    requestSaveObjectsCmd objectsChange
                in
                  { model_ |
                    floor = Just newFloor
                  } ! [ saveCmd ]

          ObjectNameInput.None ->
            model_ ! []

    RequestCandidate objectId name ->
      let
        (searchCandidateDebounce, cmd) =
          Debounce.push
            searchCandidateDebounceConfig
            (objectId, name)
            model.searchCandidateDebounce
      in
        { model |
          searchCandidateDebounce = searchCandidateDebounce
        } ! [ cmd ]

    SearchCandidateDebounceMsg msg ->
      let
        search (objectId, name) =
          if (String.trim >> String.length) name < 2 then
            Cmd.none
          else
            performAPI
              (GotCandidateSelection objectId)
              (API.personCandidate model.apiConfig name)

        (searchCandidateDebounce, cmd) =
          Debounce.update
            searchCandidateDebounceConfig
            (Debounce.takeLast search)
            msg
            model.searchCandidateDebounce
      in
        { model |
          searchCandidateDebounce = searchCandidateDebounce
        } ! [ cmd ]

    GotCandidateSelection objectId people ->
      { model |
        personInfo =
          DictUtil.addAll (.id) people model.personInfo
      , candidates = List.map .id people
      } ! []

    GotMatchingList pairs ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            matchedPairs =
              List.filterMap (\(objectId, people) ->
                case people of
                  -- determined
                  [person] ->
                    Just (objectId, person.id)

                  _ ->
                    Nothing
                ) pairs

            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.setPeople matchedPairs)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange

            allPeople =
              List.concatMap Tuple.second pairs

            personInfo =
              DictUtil.addAll (.id) allPeople model.personInfo
          in
            { model |
              floor = Just newFloor
            , personInfo = personInfo
            } ! [ saveCmd ]

    BeforeContextMenuOnObject objectId contextmenuMsg ->
      let
        selectedObjects =
          if List.member objectId model.selectedObjects then
            model.selectedObjects
          else
            [objectId]

        loadPersonCmd =
          model.floor
            |> Maybe.andThen (\eFloor -> Floor.getObject objectId (EditingFloor.present eFloor)
            |> Maybe.andThen (\obj -> Object.relatedPerson obj
            |> Maybe.map (\personId -> getAndCachePersonIfNotCached personId model)
            ))
            |> Maybe.withDefault Cmd.none
      in
        { model |
          selectedObjects = selectedObjects
        } !
          [ loadPersonCmd
          , Task.perform identity <| Task.succeed contextmenuMsg
          ]

    ContextMenuMsg msg ->
      let
        (contextMenu, cmd) =
          ContextMenu.update msg model.contextMenu
      in
        { model | contextMenu = contextMenu } ! [ Cmd.map ContextMenuMsg cmd ]

    GoToFloor maybeNextFloor ->
      let
        loadCmd =
          maybeNextFloor
            |> Maybe.andThen
              (\(floorId, requestLastEdit) ->
                let
                  load =
                    performAPI FloorLoaded (loadFloor model.apiConfig requestLastEdit floorId)
                in
                  case model.floor of
                    Just efloor ->
                      if (EditingFloor.present efloor).id == floorId then
                        Nothing
                      else
                        Just load

                    Nothing ->
                      Just load
              )
            |> Maybe.withDefault Cmd.none
      in
        model !
          [ loadCmd
          , Navigation.modifyUrl (Model.encodeToUrl model)
          ]

    SelectSamePost postName ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            floor =
              EditingFloor.present editingFloor

            cmd =
              performAPI
                GotSamePostPeople
                ( API.getPeopleByFloorAndPost
                    model.apiConfig
                    floor.id
                    floor.version
                    postName
                )
          in
            model ! [ cmd ]

    SearchByPost postName ->
      submitSearch
        { model
        | searchQuery = "\"" ++ postName ++ "\""
        , mode = Mode.showSearchResult model.mode
        }

    GotSamePostPeople people ->
      model
        |> Model.getEditingFloorOrDummy
        |> Floor.objects
        |> List.filterMap (\obj -> Object.relatedPerson obj
        |> Maybe.andThen (\personId ->
          if List.member personId (List.map .id people) then
            Just (idOf obj)
          else
            Nothing
        ))
        |> (\newSelectedObjects ->
          { model | selectedObjects = newSelectedObjects }
        )
        |> Model.cachePeople people
        |> flip (,) Cmd.none

    SelectIsland id ->
      model.floor
        |> Maybe.map EditingFloor.present
        |> Maybe.andThen (\floor -> Floor.getObject id floor
        |> Maybe.map (\object ->
          let
            island =
              ObjectsOperation.island
                [object]
                (List.filter (\e -> (Object.idOf e) /= id) (Floor.objects floor))
          in
            { model |
              selectedObjects = List.map Object.idOf island
            }
        ))
        |> Maybe.map (flip (,) Cmd.none)
        |> Maybe.withDefault (model, Cmd.none)

    SelectSameColor objectId ->
      model.floor
        |> Maybe.map EditingFloor.present
        |> Maybe.andThen (\floor -> Floor.getObject objectId floor
        |> Maybe.map (\object ->
          let
            backgroundColor =
              Object.backgroundColorOf object

            target =
              List.filter
                (\e -> (backgroundColorOf e) == backgroundColor)
                (Floor.objects floor)
          in
            { model |
              selectedObjects = List.map Object.idOf target
            } ! []
        ))
        |> Maybe.withDefault (model, Cmd.none)

    KeyCodeMsg isDown keyCode ->
      let
        (keys, event) =
          ShortCut.update isDown keyCode model.keys

        model_ =
          { model | keys = keys }
      in
        updateByKeyEvent event model_

    MouseWheel value mousePosition ->
      let
        model0 =
          { model | mousePosition = mousePosition }

        canvasPosition =
          Model.canvasPosition model0

        newScale =
          if value < 0 then
            Scale.update Scale.ScaleUp model0.scale
          else
            Scale.update Scale.ScaleDown model0.scale

        ratio =
          Scale.ratio model0.scale newScale

        newOffset =
          let
            x = Scale.screenToImage model0.scale canvasPosition.x
            y = Scale.screenToImage model0.scale canvasPosition.y
          in
            { x = floor (toFloat (x - floor (ratio * (toFloat (x - model0.offset.x)))) / ratio)
            , y = floor (toFloat (y - floor (ratio * (toFloat (y - model0.offset.y)))) / ratio)
            }

        newModel =
          { model0 |
            scale = newScale
          , offset = newOffset
          }

        saveUserStateCmd =
          putUserState newModel
            |> Task.perform (always NoOp)
      in
        newModel ! [ saveUserStateCmd ]

    WindowSize size ->
      { model | windowSize = size } ! []

    ChangeMode editingMode ->
      { model | mode = Mode.changeEditingMode editingMode model.mode } ! []

    PrototypesMsg msg ->
      let
        newModel =
          { model |
            prototypes = Prototypes.update msg model.prototypes
          , mode = Mode.toStampMode model.mode -- TODO if event == select
          }
      in
        newModel ! []

    RegisterPrototype objectId ->
      let
        object =
          model.floor
            |> Maybe.andThen (\floor -> Floor.getObject objectId (EditingFloor.present floor))
      in
        case object of
          Just o ->
            let
              { width, height } = Object.sizeOf o

              (newId, seed) = IdGenerator.new model.seed

              newPrototypes =
                Prototypes.register
                  { id = newId
                  , color = colorOf o
                  , backgroundColor = backgroundColorOf o
                  , name = nameOf o
                  , width = width
                  , height = height
                  , fontSize = fontSizeOf o
                  , shape = shapeOf o
                  , personId = Nothing
                  }
                  model.prototypes
            in
              { model |
                seed = seed
              , prototypes = newPrototypes
              } ! [ (savePrototypesCmd model.apiConfig) newPrototypes.data ]

          Nothing ->
            model ! []

    FloorPropertyMsg message ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (floorProperty, event) =
              FloorProperty.update message model.floorProperty

            (newFloor, saveCmd) =
              updateFloorByFloorPropertyEvent model.apiConfig event editingFloor

            newModel =
              { model |
                floor = Just newFloor
              , floorProperty = floorProperty
              }
          in
            newModel ! [ saveCmd ]

    Rotate id ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.rotateObject id)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    FirstNameOnly ids ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.toFirstNameOnly ids)
                editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    RemoveSpaces ids ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects (Floor.removeSpaces ids) editingFloor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]

    HeaderMsg msg ->
      { model | header = Header.update msg model.header } ! []

    SignIn ->
      model ! [ Navigation.load Page.login ]

    SignOut ->
      model ! [ removeToken {} ]

    ToggleEditing ->
      let
        newModel =
          { model |
            mode =
              Mode.toggleEditing model.mode
          }

        withPrivate =
          Mode.isEditMode newModel.mode && not (User.isGuest newModel.user)

        loadFloorCmd =
          case model.floor of
            Just floor ->
              let
                floorId =
                  (EditingFloor.present floor).id
              in
                performAPI FloorLoaded (loadFloor model.apiConfig withPrivate floorId)

            Nothing ->
              Cmd.none
      in
        newModel !
          [ loadFloorCmd
          , Navigation.modifyUrl (Model.encodeToUrl newModel)
          ]

    TogglePrintView ->
      { model |
        mode = Mode.togglePrintView model.mode
      } ! []

    SelectLang lang ->
      let
        newModel =
          { model | lang = lang }
      in
        newModel ! [ Task.perform (always NoOp) (putUserState newModel) ]

    UpdateSearchQuery searchQuery ->
      { model |
        searchQuery = searchQuery
      } ! []

    SubmitSearch ->
      submitSearch { model | mode = Mode.showSearchResult model.mode }

    GotSearchResult results people ->
      let
        selectedResult =
          case results of
            SearchResult.Object object floorId :: [] ->
              Just (Object.idOf object)

            _ ->
              Nothing

        searchResult =
          Just results
      in
        ( { model |
            searchResult = searchResult
          , selectedResult = selectedResult
          } |> Model.cachePeople people
        ) ! []

    SelectSearchResult objectId floorId maybePersonId ->
      let
        requestPrivateFloors =
          Mode.isEditMode model.mode && not (User.isGuest model.user)

        goToFloor =
          GoToFloor (Just (floorId, requestPrivateFloors))

        regesterPersonCmd =
          maybePersonId
            |> Maybe.map (regesterPersonIfNotCached model.apiConfig model.personInfo)
            |> Maybe.withDefault Cmd.none
      in
        ( Model.adjustOffset
            { model
                | selectedResult = Just objectId
            }
        , regesterPersonCmd
        )
          |> andThen (update goToFloor)

    StartDraggingFromMissingPerson personId personName ->
      let
        prototype =
          Prototypes.selectedPrototype model.prototypes
      in
        { model |
          draggingContext =
            MoveFromSearchResult
              { prototype
                | name = personName
                , personId = Just personId
              }
              personId
        } ! []

    StartDraggingFromExistingObject objectId name personId floorId updateAt ->
      let
        prototype =
          Prototypes.selectedPrototype model.prototypes
      in
        { model |
          draggingContext =
            MoveExistingObjectFromSearchResult
              floorId
              updateAt
              { prototype
                | name = name
                , personId = personId
              }
              objectId
        } ! []

    CachePeople people ->
      Model.cachePeople people model ! []

    UpdatePersonCandidate objectId personIds ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          case personIds of
            head :: [] ->
              let
                (newFloor, objectsChange) =
                  EditingFloor.updateObjects
                    (Floor.setPerson objectId head)
                    editingFloor

                saveCmd =
                  requestSaveObjectsCmd objectsChange
              in
                { model |
                  floor = Just newFloor
                } ! [ saveCmd ]

            _ ->
              model ! []

    PreparePublish ->
      model.floor
        |> Maybe.map (\efloor ->
          API.getDiffSource model.apiConfig (EditingFloor.present efloor).id
            |> performAPI GotDiffSource
          )
        |> Maybe.map ((,) model)
        |> Maybe.withDefault (model, Cmd.none)

    GotDiffSource diffSource ->
      { model | diff = Just diffSource } ! []

    CloseDiff ->
      { model | diff = Nothing } ! []

    ConfirmDiff ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            cmd =
              requestPublishFloorCmd (EditingFloor.present editingFloor).id
          in
            { model |
              diff = Nothing
            } ! [ cmd ]

    HideSearchResult ->
      { model | mode = Mode.hideSearchResult model.mode } ! []

    ClosePopup ->
      { model | selectedResult = Nothing } ! []

    ShowDetailForObject objectId ->
      case model.floor of
        Nothing ->
          model ! []

        Just floor ->
          let
            cmd =
              Floor.getObject objectId (EditingFloor.present floor)
                |> Maybe.andThen Object.relatedPerson
                |> Maybe.map (regesterPerson model.apiConfig)
                |> Maybe.withDefault Cmd.none
          in
            ({ model |
              selectedResult = Just objectId
            } |> Model.adjustOffset
            ) ! [ cmd ]

    CreateNewFloor ->
      let
        (newFloorId, newSeed) =
          IdGenerator.new model.seed

        lastFloorOrder =
          model.floorsInfo
            |> FloorInfo.toEditingList
            |> List.reverse
            |> List.head
            |> Maybe.map .ord
            |> Maybe.withDefault 0

        newFloor =
          Floor.initWithOrder newFloorId lastFloorOrder

        cmd =
          API.saveFloor model.apiConfig newFloor
            |> Task.andThen (\_ -> API.getFloorsInfo model.apiConfig)
            |> performAPI FloorsInfoLoaded

        newModel =
          { model
            | seed = newSeed
            , floor = Just (EditingFloor.init newFloor)
          }
      in
        newModel !
          [ cmd
          , Navigation.modifyUrl (Model.encodeToUrl newModel)
          ]

    CopyFloor floorId withEmptyObjects ->
      case model.floor of
        Nothing ->
          model ! []

        Just editingFloor ->
          let
            floor =
              EditingFloor.present editingFloor

            (newFloorId, newSeed) =
              IdGenerator.new model.seed

            newFloor =
              Floor.copy withEmptyObjects newFloorId floor

            saveCmd =
              API.saveFloor model.apiConfig newFloor
                |> Task.andThen (\_ ->
                  if withEmptyObjects then
                    API.saveObjects model.apiConfig (ObjectsChange.added (Floor.objects newFloor))
                  else
                    Task.succeed ObjectsChange.empty
                )
                |> Task.andThen (\_ -> API.getFloorsInfo model.apiConfig)
                |> performAPI FloorsInfoLoaded


            newModel =
              { model |
                seed = newSeed
              , floor = Just (EditingFloor.init newFloor)
              }

          in
            newModel !
              [ saveCmd
              , Navigation.modifyUrl (Model.encodeToUrl newModel)
              ]

    EmulateClick id down time ->
      let
        (clickEmulator, event) =
          case (id, down, time) :: model.clickEmulator of
            (id4, False, time4) :: (id3, True, time3) :: (id2, False, time2) :: (id1, True, time1) :: _ ->
              if List.all ((==) id1) [id2, id3, id4] && (time4 - time1 < 400) then
                ([], "dblclick")
              else
                (List.take 4 <| (id, down, time) :: model.clickEmulator, "")
            _ ->
              (List.take 4 <| (id, down, time) :: model.clickEmulator, "")
      in
        { model | clickEmulator = clickEmulator }
        ! ( if event == "dblclick" then
              [ Task.perform identity (Task.succeed (StartEditObject id)) ]
            else
              []
            )

    TokenRemoved ->
      { model
          | user = User.guest
          , mode = Mode.init False
      } ! []

    Undo ->
      case model.floor of
        Nothing ->
          model ! []

        Just floor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.undo floor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model | floor = Just newFloor } ! [ saveCmd ]

    Redo ->
      case model.floor of
        Nothing ->
          model ! []

        Just floor ->
          let
            (newFloor, objectsChange) =
              EditingFloor.redo floor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model | floor = Just newFloor } ! [ saveCmd ]

    Focused ->
      model ! [ setSelectionStart {} ]

    PasteFromClipboard s ->
      case (model.floor, model.selectorRect) of
        (Just floor, Just (pos, _)) ->
          let
            prototype =
              Prototypes.selectedPrototype model.prototypes

            candidates =
              ClipboardData.toObjectCandidates prototype pos s

            ((newModel, cmd), newObjects) =
              updateOnFinishStamp_ candidates model floor

            task =
              List.foldl
                (\object prevTask ->
                  prevTask
                    |> Task.andThen (\list ->
                      API.personCandidate model.apiConfig (Object.nameOf object)
                        |> Task.map (\people ->
                          (Object.idOf object, people) :: list
                        )
                    )
                    -- TODO too many requests
                ) (Task.succeed []) newObjects

            autoMatchingCmd =
              Process.sleep 1000
                |> Task.andThen (\_ -> task)
                |> performAPI GotMatchingList
          in
            { newModel |
              selectedObjects = List.map (Object.idOf) newObjects
            } ! [ cmd, autoMatchingCmd ]

        _ ->
          model ! []

    SyncFloor ->
      case model.floor of
        Just editingFloor ->
          let
            requestPrivateFloors =
              Mode.isEditMode model.mode && not (User.isGuest model.user)

            floorId =
              (EditingFloor.present editingFloor).id

            loadFloorCmd =
              loadFloor model.apiConfig requestPrivateFloors floorId
                |> performAPI FloorLoaded
          in
            model !
              [ loadFloorCmd ]

        _ ->
          model ! []


    ImageLoaderMsg msg ->
      model !
        [ ImageLoader.update
            { onFileWithDataURL = GotFileWithDataURL
            , onFileLoadFailed = Error << FileError
            }
            msg
        ]

    GotFileWithDataURL file dataURL ->
      let
        (id, newSeed) =
          IdGenerator.new model.seed

        url = id

        (width, height) =
          File.getSizeOfImage dataURL

        saveImageCmd =
          API.saveEditingImage model.apiConfig url file
            |> performAPI (always <| ImageSaved url width height)
      in
        { model | seed = newSeed }
          ! [ saveImageCmd ]

    FloorDeleterMsg msg ->
      let
        (floorDeleter, cmd) =
          FloorDeleter.update
            FloorDeleterMsg
            { onDeleteFloor = \floor ->
                API.deleteEditingFloor model.apiConfig floor.id
                  |> performAPI (\_ -> FloorDeleted floor)
            }
            msg
            model.floorDeleter
      in
        { model | floorDeleter = floorDeleter } ! [ cmd ]

    FloorDeleted floor ->
      let
        newModel =
          { model |
            floor = Nothing
          , error = Success ("Successfully deleted " ++ floor.name)
          }
      in
        newModel !
          [ API.getFloorsInfo model.apiConfig
              |> performAPI FloorsInfoLoaded
          , Process.sleep 3000.0
              |> Task.perform (\_ -> Error NoError)
          , Navigation.modifyUrl (Model.encodeToUrl newModel)
          ]

    InsertEmoji text ->
      model !
        [ ObjectNameInput.insertText ObjectNameInputMsg text model.objectNameInput
        ]

    LinkCopyMsg msg ->
      model ! [ LinkCopy.copy msg ]

    ChangeToObjectUrl objectId ->
      model ! [ Navigation.modifyUrl ("?object=" ++ objectId) ]

    Error e ->
      { model | error = e } ! []


andThen : (Model -> (Model, Cmd Msg)) -> (Model, Cmd Msg) -> (Model, Cmd Msg)
andThen update (model, cmd) =
  let
    (newModel, newCmd) =
      update model
  in
    newModel ! [ cmd, newCmd ]


submitSearch : Model -> (Model, Cmd Msg)
submitSearch model =
  let
    withPrivate =
      not (User.isGuest model.user)

    searchCmd =
      if String.trim model.searchQuery == "" then
        Cmd.none
      else
        search model.apiConfig withPrivate model.personInfo model.searchQuery
  in
    model !
      [ searchCmd
      , Navigation.modifyUrl (Model.encodeToUrl model)
      ]


search : API.Config -> Bool -> Dict PersonId Person -> String -> Cmd Msg
search apiConfig withPrivate personInfo query =
  API.search apiConfig withPrivate query
    |> performAPI (\(results, people) -> GotSearchResult results people)


updateOnMouseUp : Position -> Model -> (Model, Cmd Msg)
updateOnMouseUp pos model =
  let
    (model_, cmd) =
      case model.draggingContext of
        MoveObject id start ->
          updateByMoveObjectEnd id start model.mousePosition model

        Selector ->
          { model | selectorRect = Nothing } ! []

        StampFromScreenPos _ ->
          updateOnFinishStamp model

        PenFromScreenPos pos ->
          updateOnFinishPen pos model

        ResizeFromScreenPos id pos ->
          updateOnFinishResize id pos model

        MoveFromSearchResult prototype personId ->
          updateOnFinishStamp model

        MoveExistingObjectFromSearchResult oldFloorId updateAt _ objectId ->
          case model.floor of
            Just editingFloor ->
              let
                (newSeed, newFloor, newObjects_, _) =
                  updateOnFinishStampWithoutEffects
                    (Just objectId)
                    (Model.getPositionedPrototype model)
                    model
                    editingFloor

                -- currently, only one desk is made
                newObjects =
                  List.map (Object.setUpdateAt updateAt) newObjects_

                objectsChange =
                  ObjectsChange.modified
                    (List.map (\object -> (Object.idOf object, object)) newObjects)

                saveCmd =
                  requestSaveObjectsCmd objectsChange

                searchResult =
                  model.searchResult
                    |> Maybe.map (SearchResult.mergeObjectInfo (EditingFloor.present newFloor).id (Floor.objects <| EditingFloor.present newFloor))
                    |> Maybe.map (SearchResult.moveObject oldFloorId newObjects)

                cachePersonCmd =
                  newObjects
                    |> List.filterMap Object.relatedPerson
                    |> List.head
                    |> Maybe.map (\personId -> getAndCachePersonIfNotCached personId model)
                    |> Maybe.withDefault Cmd.none
              in
                { model
                  | seed = newSeed
                  , floor = Just newFloor
                  , searchResult = searchResult
                } ! [ saveCmd, cachePersonCmd ]

            _ ->
              model ! []

        ShiftOffset from ->
          { model
            | selectedResult =
              if from == pos then
                Nothing
              else
                model.selectedResult
          } ! []

        _ ->
          model ! []

    newModel =
      { model_ |
        draggingContext = NoDragging
      }
  in
    newModel ! [ cmd ]


updateOnSelectCandidate : ObjectId -> PersonId -> Model -> (Model, Cmd Msg)
updateOnSelectCandidate objectId personId model =
  case (model.floor, Dict.get personId model.personInfo) of
    (Just floor, Just person) ->
      let
        (newFloor, objectsChange) =
          EditingFloor.updateObjects
            (Floor.setPerson objectId personId)
            floor
      in
        updateOnFinishNameInput True objectId person.name
          { model |
            floor = Just newFloor
          }

    _ ->
      model ! []


requestCandidate : Id -> String -> Cmd Msg
requestCandidate id name =
  Task.perform identity <| Task.succeed (RequestCandidate id name)


emulateClick : String -> Bool -> Cmd Msg
emulateClick id down =
  Time.now
    |> Task.perform (\time -> EmulateClick id down time)


updateOnFinishStamp : Model -> (Model, Cmd Msg)
updateOnFinishStamp model =
  case model.floor of
    Just floor ->
      Tuple.first <| updateOnFinishStamp_ (Model.getPositionedPrototype model) model floor

    Nothing ->
      model ! []


updateOnFinishStamp_ : List PositionedPrototype -> Model -> EditingFloor -> ((Model, Cmd Msg), List Object)
updateOnFinishStamp_ prototypes model floor =
  let
    (newSeed, newFloor, newObjects, objectsChange) =
      updateOnFinishStampWithoutEffects Nothing prototypes model floor

    searchResult =
      model.searchResult
        |> Maybe.map (SearchResult.mergeObjectInfo (EditingFloor.present newFloor).id (Floor.objects <| EditingFloor.present newFloor))

    saveCmd =
      requestSaveObjectsCmd objectsChange
  in
    ( ( { model
          | seed = newSeed
          , floor = Just newFloor
          , searchResult = searchResult
          , mode = Mode.toSelectMode model.mode
        }
        , saveCmd
      )
    , newObjects
    )

-- TODO Need a hard refactor around here

updateOnFinishStampWithoutEffects : Maybe String -> List PositionedPrototype -> Model -> EditingFloor -> (Seed, EditingFloor, List Object, ObjectsChange)
updateOnFinishStampWithoutEffects maybeObjectId prototypes model floor =
  let
    (candidatesWithNewIds, newSeed) =
      IdGenerator.zipWithNewIds model.seed prototypes

    newObjects =
      List.map
        (\((prototype, pos), newId) ->
            Object.initDesk
              (Maybe.withDefault newId maybeObjectId)
              (EditingFloor.present floor).id
              Nothing
              pos
              (Size prototype.width prototype.height)
              prototype.backgroundColor
              prototype.name
              prototype.fontSize
              Nothing
              prototype.personId
        )
        candidatesWithNewIds

    (newFloor, objectsChange) =
      EditingFloor.updateObjects (Floor.addObjects newObjects) floor
  in
    (newSeed, newFloor, newObjects, objectsChange)


updateOnFinishPen : Position -> Model -> (Model, Cmd Msg)
updateOnFinishPen from model =
  case (model.floor, Model.temporaryPen model from) of
    (Just floor, Just (color, name, pos, size)) ->
      let
        (newId, newSeed) =
          IdGenerator.new model.seed

        newObject =
          Object.initDesk
            newId
            (EditingFloor.present floor).id
            Nothing
            pos
            size
            color
            name
            Object.defaultFontSize
            Nothing
            Nothing

        (newFloor, objectsChange) =
          EditingFloor.updateObjects
            (Floor.addObjects [ newObject ])
            floor

        saveCmd =
          requestSaveObjectsCmd objectsChange
      in
        { model |
          seed = newSeed
        , floor = Just newFloor
        } ! [ saveCmd ]

    _ ->
      model ! []


updateOnFinishResize : ObjectId -> Position -> Model -> (Model, Cmd Msg)
updateOnFinishResize objectId fromScreen model =
  model.floor
    |> Maybe.andThen (\editingFloor -> Floor.getObject objectId (EditingFloor.present editingFloor)
    |> Maybe.andThen (\o -> Model.temporaryResizeRect model fromScreen (Object.positionOf o) (Object.sizeOf o)
    |> Maybe.map (\(_, size) ->
        let
          (newFloor, objectsChange) =
            EditingFloor.updateObjects (Floor.resizeObject objectId size) editingFloor

          saveCmd =
            requestSaveObjectsCmd objectsChange
        in
          { model | floor = Just newFloor } ! [ saveCmd ]
      )))
    |> Maybe.withDefault (model ! [])


updateOnPuttingLabel : Model -> (Model, Cmd Msg)
updateOnPuttingLabel model =
  case model.floor of
    Just floor ->
      let
        canvasPosition =
          Model.canvasPosition model

        fitted =
          ObjectsOperation.fitPositionToGrid model.gridSize <|
            Model.screenToImageWithOffset
              model.scale
              canvasPosition
              model.offset

        size =
          ObjectsOperation.fitSizeToGrid model.gridSize (Size 100 100) -- TODO configure?

        bgColor = "transparent" -- TODO configure?

        color = "#000"

        name = ""

        fontSize = 40 -- TODO

        (newId, newSeed) =
          IdGenerator.new model.seed

        newObject =
          Object.initLabel
            newId
            (EditingFloor.present floor).id
            Nothing
            fitted
            size
            bgColor
            name
            fontSize
            Nothing
            (Object.LabelFields color False "" Object.Rectangle)

        (newFloor, objectsChange) =
          EditingFloor.updateObjects
            (Floor.addObjects [ newObject ])
            floor

        saveCmd =
          requestSaveObjectsCmd objectsChange

        model_ =
          { model |
            seed = newSeed
          , mode = Mode.toSelectMode model.mode
          , floor = Just newFloor
          }
      in
        case Floor.getObject newId (EditingFloor.present newFloor) of
          Just e ->
            let
              newModel =
                Model.startEdit e model_
            in
              newModel ! [ saveCmd, focusCmd ]

          Nothing ->
            model_ ! [ saveCmd ]

    _ ->
      model ! []


updateOnFloorLoaded : Maybe Floor -> Model -> (Model, Cmd Msg)
updateOnFloorLoaded maybeFloor model =
  case maybeFloor of
    Just floor ->
      let
        (realWidth, realHeight) =
          Floor.realSize floor

        newModel =
          Model.adjustOffset
            { model |
              floorsInfo = FloorInfo.mergeFloor (Floor.baseOf floor) model.floorsInfo
            , floor = Just (EditingFloor.init floor)
            , floorProperty = FloorProperty.init floor.name realWidth realHeight floor.ord
            }

        cmd =
          case (User.isGuest model.user, floor.update) of
            (False, Just { by }) ->
              getAndCachePersonIfNotCached by model

            _ ->
              Cmd.none
      in
        newModel ! [ cmd, Navigation.modifyUrl (Model.encodeToUrl newModel) ]

    Nothing ->
      let
        newModel =
          { model | floor = Nothing }
      in
        newModel ! [ Navigation.modifyUrl (Model.encodeToUrl newModel) ]


getAndCachePersonIfNotCached : PersonId -> Model -> Cmd Msg
getAndCachePersonIfNotCached personId model =
  case Dict.get personId model.personInfo of
    Just _ ->
      Cmd.none

    Nothing ->
      performAPI
        (\person -> CachePeople [person])
        (API.getPersonByUser model.apiConfig personId)


focusCmd : Cmd Msg
focusCmd =
  Task.attempt
    (Result.map (always Focused) >> Result.withDefault NoOp)
    (Dom.focus "name-input")


updateFloorByFloorPropertyEvent : API.Config -> Maybe FloorProperty.Event -> EditingFloor -> (EditingFloor, Cmd Msg)
updateFloorByFloorPropertyEvent apiConfig event efloor =
  event
    |> Maybe.map (\e ->
      let
        f =
          case e of
            FloorProperty.OnNameChange name ->
              Floor.changeName name

            FloorProperty.OnOrdChange ord ->
              Floor.changeOrd ord

            FloorProperty.OnRealSizeChange size ->
              Floor.changeRealSize size

        (newFloor, rawFloor) =
          EditingFloor.updateFloor f efloor

        saveCmd =
          requestSaveFloorCmd rawFloor
      in
        (newFloor, saveCmd)
    )
    |> Maybe.withDefault (efloor, Cmd.none)


regesterPersonOfObject : API.Config -> Object -> Cmd Msg
regesterPersonOfObject apiConfig e =
  case Object.relatedPerson e of
    Just personId ->
      regesterPerson apiConfig personId

    Nothing ->
      Cmd.none


regesterPerson : API.Config -> PersonId -> Cmd Msg
regesterPerson apiConfig personId =
  API.getPerson apiConfig personId
    |> performAPI (\person -> CachePeople [person])


regesterPersonIfNotCached : API.Config -> Dict PersonId Person -> PersonId -> Cmd Msg
regesterPersonIfNotCached apiConfig personInfo personId =
  if Dict.member personId personInfo then
    Cmd.none
  else
    regesterPerson apiConfig personId


updateOnFinishNameInput : Bool -> ObjectId -> String -> Model -> (Model, Cmd Msg)
updateOnFinishNameInput continueEditing objectId name model =
  case model.floor of
    Nothing ->
      model ! []

    Just efloor ->
      let
        floor =
          EditingFloor.present efloor

        (objectNameInput, requestCandidateCmd) =
          Floor.getObject objectId floor
            |> Maybe.andThen (\object ->
              if continueEditing && not (Object.isLabel object) then
                Just object
              else
                Nothing
            )
            |> Maybe.map (\object ->
              case nextObjectToInput object (Floor.objects floor) of
                Just e ->
                  ( ObjectNameInput.start (idOf e, nameOf e) model.objectNameInput
                  , requestCandidate (idOf e) (nameOf e)
                  )

                Nothing ->
                  ( model.objectNameInput
                  , requestCandidate objectId name
                  )
            )
            |> Maybe.withDefault (model.objectNameInput, Cmd.none)

        cachePersonCmd =
          Floor.getObject objectId floor
            |> Maybe.map (cachePersonIfAPersonIsNotRelatedTo model.apiConfig)
            |> Maybe.withDefault Cmd.none

        selectedObjects =
          objectNameInput.editingObject
            |> Maybe.map (\(id, _) -> [id])
            |> Maybe.withDefault []

        (newFloor, objectsChange) =
          Floor.getObject objectId floor
            |> Maybe.map (\object ->
              if Object.isLabel object && String.trim name == "" then
                EditingFloor.updateObjects
                  (Floor.removeObjects [objectId])
                  efloor
              else
                EditingFloor.updateObjects
                  (Floor.changeObjectName [objectId] name)
                  efloor
            )
            |> Maybe.withDefault (efloor, ObjectsChange.empty)

        saveCmd =
          requestSaveObjectsCmd objectsChange

        newModel =
          { model |
            floor = Just newFloor
          , objectNameInput = objectNameInput
          , candidates = []
          , selectedObjects = selectedObjects
          }
      in
        newModel ! [ requestCandidateCmd, cachePersonCmd, saveCmd, focusCmd ]


cachePersonIfAPersonIsNotRelatedTo : API.Config -> Object -> Cmd Msg
cachePersonIfAPersonIsNotRelatedTo apiConfig object =
  Object.relatedPerson object
    |> Maybe.map (\personId ->
      API.personCandidate apiConfig (nameOf object)
        |> performAPI CachePeople
      )
    |> Maybe.withDefault Cmd.none


nextObjectToInput : Object -> List Object -> Maybe Object
nextObjectToInput object allObjects =
  let
    island =
      ObjectsOperation.island
        [object]
        (List.filter (\e -> (Object.idOf e) /= (idOf object)) allObjects)
  in
    case ObjectsOperation.nearest Down object island of
      Just e ->
        if Object.idOf object == idOf e then
          Nothing
        else
          Just e

      _ ->
        Nothing


savePrototypesCmd : API.Config -> List Prototype -> Cmd Msg
savePrototypesCmd apiConfig prototypes =
  API.savePrototypes apiConfig prototypes
    |> performAPI (always NoOp)


requestSaveObjectsCmd : ObjectsChange -> Cmd Msg
requestSaveObjectsCmd objectsChange =
  requestCmd (SaveObjects objectsChange)


requestSaveFloorCmd : Floor -> Cmd Msg
requestSaveFloorCmd floor =
  requestCmd (SaveFloor floor)


requestPublishFloorCmd : String -> Cmd Msg
requestPublishFloorCmd id =
  requestCmd (PublishFloor id)


requestCmd : SaveRequest -> Cmd Msg
requestCmd req =
  Task.succeed req
    |> Task.perform RequestSave


batchSave : API.Config -> ReducedSaveRequest -> Cmd Msg
batchSave apiConfig request =
  let
    publishFloorCmd =
      request.publish
        |> Maybe.map (API.publishFloor apiConfig)
        |> Maybe.map (performAPI FloorPublished)
        |> Maybe.withDefault Cmd.none

    saveFloorCmd =
      request.floor
        |> Maybe.map (API.saveFloor apiConfig)
        |> Maybe.map (performAPI FloorSaved)
        |> Maybe.withDefault Cmd.none

    saveObjectsCmd =
      API.saveObjects apiConfig request.objects
        |> performAPI ObjectsSaved
  in
    Cmd.batch [ publishFloorCmd, saveFloorCmd, saveObjectsCmd ]


updateByKeyEvent : ShortCut.Event -> Model -> (Model, Cmd Msg)
updateByKeyEvent event model =
  -- Patterns are separated because of the worst-case performance of pattern match.
  -- https://github.com/elm-lang/elm-compiler/issues/1362
  -- This will be fixed when Elm 0.19 is out.
  if model.keys.ctrl then
    updateByKeyEventWithCtrl event model
  else if model.keys.shift then
    updateByKeyEventWithShift event model
  else
    updateByKeyEventWithNoControlKeys event model


updateByKeyEventWithCtrl : ShortCut.Event -> Model -> (Model, Cmd Msg)
updateByKeyEventWithCtrl event model =
  case (model.floor, event) of
    (Just floor, ShortCut.A) ->
      { model |
        selectedObjects =
          List.map idOf <| Floor.objects (EditingFloor.present floor)
      } ! []

    (Just floor, ShortCut.C) ->
      { model |
        copiedObjects = Model.selectedObjects model
      } ! []

    (Just floor, ShortCut.V) ->
      case model.selectorRect of
        Just (base, _) ->
          let
            (copiedIdsWithNewIds, newSeed) =
              IdGenerator.zipWithNewIds model.seed model.copiedObjects

            (newFloor, objectsChange) =
              EditingFloor.updateObjects (Floor.paste copiedIdsWithNewIds base) floor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            , seed = newSeed
            , selectedObjects =
              case List.map Tuple.second copiedIdsWithNewIds of
                [] -> model.selectedObjects -- for pasting from spreadsheet
                x -> x
            , selectorRect = Nothing
            } ! [ saveCmd ]

        Nothing ->
          model ! []

    (Just floor, ShortCut.X) ->
      let
        (newFloor, objectsChange) =
          EditingFloor.updateObjects (Floor.removeObjects model.selectedObjects) floor

        saveCmd =
          requestSaveObjectsCmd objectsChange
      in
        { model |
          floor = Just newFloor
        , copiedObjects = Model.selectedObjects model
        , selectedObjects = []
        } ! [ saveCmd ]

    _ ->
      model ! []


updateByKeyEventWithShift : ShortCut.Event -> Model -> (Model, Cmd Msg)
updateByKeyEventWithShift event model =
  case (model.floor, event) of
    (Just floor, ShortCut.UpArrow) ->
      Model.expandOrShrinkToward Up model ! []

    (Just floor, ShortCut.DownArrow) ->
      Model.expandOrShrinkToward Down model ! []

    (Just floor, ShortCut.LeftArrow) ->
      Model.expandOrShrinkToward Left model ! []

    (Just floor, ShortCut.RightArrow) ->
      Model.expandOrShrinkToward Right model ! []

    _ ->
      model ! []


updateByKeyEventWithNoControlKeys : ShortCut.Event -> Model -> (Model, Cmd Msg)
updateByKeyEventWithNoControlKeys event model =
  case (model.floor, event) of
    (Just floor, ShortCut.UpArrow) ->
      moveSelecedObjectsToward Up model floor

    (Just floor, ShortCut.DownArrow) ->
      moveSelecedObjectsToward Down model floor

    (Just floor, ShortCut.LeftArrow) ->
      moveSelecedObjectsToward Left model floor

    (Just floor, ShortCut.RightArrow) ->
      moveSelecedObjectsToward Right model floor

    (Just floor, ShortCut.Del) ->
      let
        (newFloor, objectsChange) =
          EditingFloor.updateObjects (Floor.removeObjects model.selectedObjects) floor

        saveCmd =
          requestSaveObjectsCmd objectsChange
      in
        { model |
          floor = Just newFloor
        } ! [ saveCmd ]

    (Just floor, ShortCut.Other 9) ->
      Model.shiftSelectionToward Right model ! []

    _ ->
      model ! []


moveSelecedObjectsToward : Direction -> Model -> EditingFloor -> (Model, Cmd Msg)
moveSelecedObjectsToward direction model editingFloor =
  let
    shift =
      Direction.shiftTowards direction model.gridSize

    (newFloor, objectsChange) =
      EditingFloor.updateObjects
        (Floor.move model.selectedObjects model.gridSize shift)
        editingFloor

    saveCmd =
      requestSaveObjectsCmd objectsChange
  in
    { model |
      floor = Just newFloor
    } ! [ saveCmd ]


updateByMoveObjectEnd : ObjectId -> Position -> Position -> Model -> (Model, Cmd Msg)
updateByMoveObjectEnd objectId start end model =
  case model.floor of
    Nothing ->
      model ! []

    Just floor ->
      let
        shift =
          Scale.screenToImageForPosition
            model.scale
            { x = end.x - start.x
            , y = end.y - start.y
            }
      in
        if (shift.x, shift.y) /= (0, 0) then
          let
            (newFloor, objectsChange) =
              EditingFloor.updateObjects
                (Floor.move model.selectedObjects model.gridSize (shift.x, shift.y))
                floor

            saveCmd =
              requestSaveObjectsCmd objectsChange
          in
            { model |
              floor = Just newFloor
            } ! [ saveCmd ]
        -- comment out for contextmenu
        -- else if not model.keys.ctrl && not model.keys.shift then
        --   { model |
        --     selectedObjects = [objectId]
        --   } ! []
        else
          model ! []


putUserState : Model -> Task x ()
putUserState model =
  Cache.put
    model.cache
    { scale = model.scale
    , offset = model.offset
    , lang = model.lang
    }


loadFloor : API.Config -> Bool -> String -> Task API.Error (Maybe Floor)
loadFloor apiConfig forEdit floorId =
  HttpUtil.recover404 <|
    if forEdit then
      API.getEditingFloor apiConfig floorId
    else
      API.getFloor apiConfig floorId
