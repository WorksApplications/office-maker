module Model exposing (..)

import Date exposing (Date)
import Maybe
import Task exposing (Task, andThen, onError)
import Debug
import Window
import String
import Process
import Keyboard
import Dict exposing (Dict)
import Navigation
import Time exposing (Time)
import Http
import Dom

import Util.ShortCut as ShortCut
import Util.IdGenerator as IdGenerator exposing (Seed)
import Util.DictUtil exposing (..)

import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.ObjectsOperation as ObjectsOperation exposing (..)
import Model.Scale as Scale
import Model.API as API
import Model.Prototypes as Prototypes exposing (..)
import Model.Floor as Floor exposing (Model, setObjects, setLocalFile, objects, addObjects)
import Model.FloorDiff as FloorDiff exposing (ObjectsChange)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.URL as URL

import Model.ProfilePopupLogic as ProfilePopupLogic
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import Model.EditingFloor as EditingFloor exposing (EditingFloor)

import FloorProperty
import SearchBox
import Header exposing (..)
import ObjectNameInput

type alias Floor = Floor.Model

type alias Commit = Floor.Msg

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
  , objectNameInput : ObjectNameInput.Model
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , keys : ShortCut.Model
  , editMode : EditMode
  , colorPalette : ColorPalette
  , contextMenu : ContextMenu
  , floor : EditingFloor
  , floorsInfo : List FloorInfo
  , windowSize : (Int, Int)
  , scale : Scale.Model
  , offset : (Int, Int)
  , scaling : Bool
  , prototypes : Prototypes.Model
  , error : GlobalError
  , url : URL.Model
  , floorProperty : FloorProperty.Model
  , searchBox : SearchBox.Model
  , selectedResult : Maybe Id
  , personInfo : Dict String Person
  , diff : Maybe (Floor, Maybe Floor)
  , candidates : List Id
  , tab : Tab
  , clickEmulator : List (Id, Bool, Time)
  , candidateRequest : CandidateRequestState
  , personPopupSize : (Int, Int)
  }


type ContextMenu =
    NoContextMenu
  | Object (Int, Int) Id
  | FloorInfo (Int, Int) Id


type EditMode =
    Viewing Bool
  | Select
  | Pen
  | Stamp
  | LabelMode


type DraggingContext =
    None
  | MoveObject Id (Int, Int)
  | Selector
  | ShiftOffsetPrevScreenPos
  | PenFromScreenPos (Int, Int)
  | StampFromScreenPos (Int, Int)
  | ResizeFromScreenPos Id (Int, Int)


type Tab =
  SearchTab | EditTab


type CandidateRequestState
  = Waiting (Maybe (Id, String))
  | NotWaiting


subscriptions : (({} -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions tokenRemoved model =
  Sub.batch
    [ Window.resizes (\e -> WindowSize (e.width, e.height))
    , Keyboard.downs (KeyCodeMsg True)
    , Keyboard.ups (KeyCodeMsg False)
    , tokenRemoved (always TokenRemoved)
    ]


gridSize : Int
gridSize = 8 -- 2^N


init : String -> String -> String -> String -> (Int, Int) -> (Int, Int) -> Float -> (Result String URL.Model) -> (Model, Cmd Msg)
init apiRoot accountServiceRoot authToken title randomSeed initialSize visitDate urlResult =
  let
    apiConfig = { apiRoot = apiRoot, accountServiceRoot = accountServiceRoot, token = authToken } -- TODO

    initialFloor =
      Floor.init ""

    toModel url searchBox =
      { apiConfig = apiConfig
      , title = title
      , seed = IdGenerator.init randomSeed
      , visitDate = Date.fromTime visitDate
      , user = User.guest
      , pos = (0, 0)
      , draggingContext = None
      , selectedObjects = []
      , copiedObjects = []
      , objectNameInput = ObjectNameInput.init
      , gridSize = gridSize
      , selectorRect = Nothing
      , keys = ShortCut.init
      , editMode = if url.editMode then Select else Viewing False
      , colorPalette = ColorPalette.init []
      , contextMenu = NoContextMenu
      , floorsInfo = []
      , floor = EditingFloor.init initialFloor
      , windowSize = initialSize
      , scale = Scale.init
      , offset = (35, 35)
      , scaling = False
      , prototypes = Prototypes.init []
      , error = NoError
      , floorProperty = FloorProperty.init initialFloor.name 0 0 0
      , selectedResult = Nothing
      , personInfo = Dict.empty
      , diff = Nothing
      , candidates = []
      , url = url
      , searchBox = searchBox
      , tab = SearchTab
      , clickEmulator = []
      , candidateRequest = NotWaiting
      , personPopupSize = (300, 160)
      }

    initCmd = loadAuthCmd apiConfig
  in
    case urlResult of
      -- TODO refactor
      Ok url ->
        let
          (searchBox, cmd) = SearchBox.init apiConfig SearchBoxMsg url.query
        in
          (toModel url searchBox) ! [ initCmd, cmd ]
      Err _ ->
        let
          dummyURL = URL.dummy
          (searchBox, cmd) = SearchBox.init apiConfig SearchBoxMsg dummyURL.query
        in
          (toModel dummyURL searchBox)
          ! [ initCmd, cmd ] -- TODO modifyURL

--

type Msg = NoOp
  | AuthLoaded User
  | FloorsInfoLoaded (List FloorInfo)
  | FloorLoaded Floor
  | ColorsLoaded ColorPalette
  | PrototypesLoaded (List Prototype)
  | FloorSaved Bool Int
  | MoveOnCanvas (Int, Int)
  | EnterCanvas
  | LeaveCanvas
  | MouseUpOnCanvas
  | MouseDownOnCanvas (Int, Int)
  | MouseDownOnObject Id (Int, Int)
  | MouseUpOnObject Id
  | MouseDownOnResizeGrip Id
  | StartEditObject Id
  | KeyCodeMsg Bool Int
  | SelectBackgroundColor String
  | SelectColor String
  | SelectShape Object.Shape
  | ObjectNameInputMsg ObjectNameInput.Msg
  | ShowContextMenuOnObject Id
  | ShowContextMenuOnFloorInfo Id
  | HideContextMenu
  | SelectIsland Id
  | WindowSize (Int, Int)
  | MouseWheel Float
  | ChangeMode EditMode
  | ScaleEnd
  | PrototypesMsg Prototypes.Msg
  | RegisterPrototype Id
  | FloorPropertyMsg FloorProperty.Msg
  | Rotate Id
  | FirstNameOnly (List Id)
  | HeaderMsg Header.Msg
  | SearchBoxMsg SearchBox.Msg
  | RegisterPeople (List Person)
  | RequestCandidate Id String
  | GotCandidateSelection Id (List Person)
  | UpdatePersonCandidate Id (List Id)
  | GotDiffSource (Floor, Maybe Floor)
  | CloseDiff
  | ConfirmDiff
  | ChangeTab Tab
  | ClosePopup
  | ShowDetailForObject Id
  | CreateNewFloor
  | CopyFloor String
  | NewFloorCreated String
  | EmulateClick Id Bool Time
  | TokenRemoved
  | Error GlobalError

debug : Bool
debug = False --|| True

debugMsg : Msg -> Msg
debugMsg action =
  if debug then
    case action of
      MoveOnCanvas _ -> action
      _ -> Debug.log "action" action
  else
    action

performAPI : (a -> Msg) -> Task.Task API.Error a -> Cmd Msg
performAPI tagger task =
  Task.perform (Error << APIError) tagger task

urlUpdate : Result String URL.Model -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  case result of
    Ok newURL ->
      let
        floorId = newURL.floorId

        --TODO what is changed?

        (newSearchBox, searchBoxCmd) =
          case (model.url.query /= newURL.query, newURL.query) of
            (True, Just query) ->
              let
                withPrivate =
                  not (User.isGuest model.user)

                thisFloorId =
                  Just floorId
              in
                SearchBox.doSearch model.apiConfig SearchBoxMsg withPrivate thisFloorId query model.searchBox
            _ ->
              (model.searchBox, Cmd.none)

        forEdit = not (User.isGuest model.user)

        loadFloorCmd' =
          if String.length floorId > 0 then
            loadFloorCmd model.apiConfig forEdit floorId
          else
            Cmd.none

        nextIsEditing =
          not (User.isGuest model.user) && newURL.editMode

        newEditMode =
          if nextIsEditing then Select else Viewing False

        requestPrivateFloors =
          case newEditMode of
            Viewing _ -> False
            _ -> not (User.isGuest model.user)

        _ = Debug.log ("node test/server/commands deleteFloor " ++ newURL.floorId) ""
      in
        { model |
          url = newURL
        , editMode = newEditMode
        , tab =
            -- TODO detect what is changed
            if nextIsEditing then
              case model.editMode of
                Viewing _ -> EditTab
                _ -> model.tab
            else
              SearchTab
        , searchBox = newSearchBox
        } !
          [ loadFloorCmd'
          , searchBoxCmd
          , loadFloorsInfoCmd model.apiConfig requestPrivateFloors
          ]
    Err _ ->
      let
        validURL = URL.validate model.url
      in
        model ! [ Navigation.modifyUrl (URL.stringify validURL) ]


update : ({} -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update removeToken action model =
  case debugMsg action of
    NoOp ->
      model ! []

    AuthLoaded user ->
      let
        requestPrivateFloors =
          case model.editMode of
            Viewing _ -> False
            _ -> not (User.isGuest user)

        floorId =
          model.url.floorId

        loadFloorCmd' =
          if String.length floorId > 0 then
            (loadFloorCmd model.apiConfig) requestPrivateFloors floorId
          else
            Cmd.none

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
        , editMode =
            if User.isAdmin user then
              if model.url.editMode then Select else Viewing False
            else
              Viewing False
        }
        ! [ loadFloorsInfoCmd model.apiConfig requestPrivateFloors
          , loadFloorCmd'
          , loadSettingsCmd
          ]

    ColorsLoaded colorPalette ->
      { model | colorPalette = colorPalette } ! []

    PrototypesLoaded prototypeList ->
      { model | prototypes = Prototypes.init prototypeList } ! []

    FloorsInfoLoaded floors ->
      { model | floorsInfo = floors } ! []

    FloorLoaded floor ->
      updateOnFloorLoaded floor model

    FloorSaved isPublish newVersion ->
      let
        newFloorId =
          (EditingFloor.present model.floor).id

        (message, cmd) =
          if isPublish then
            let
              message =
                Success ("Successfully published " ++ (EditingFloor.present model.floor).name)
            in
              message !
                [ Task.perform (always NoOp) Error <| (Process.sleep 3000.0 `andThen` \_ -> Task.succeed NoError)
                , Navigation.modifyUrl (URL.stringify <| URL.updateFloorId (Just newFloorId) model.url)
                ]
          else
            model.error ! []

        newFloor =
          EditingFloor.changeFloorAfterSave isPublish newVersion model.floor
      in
        { model |
          floor = newFloor
        , error = message
        } ! [ cmd ]

    MoveOnCanvas (clientX, clientY) ->
      let
        (x, y) =
          (clientX, clientY - 37)

        model' =
          { model |
            pos = (x, y)
          }

        (prevX, prevY) =
          model.pos

        newModel =
          case model.draggingContext of
            ShiftOffsetPrevScreenPos ->
              { model' |
                offset =
                  let
                    (offsetX, offsetY) = model.offset
                    (dx, dy) =
                      ((x - prevX), (y - prevY))
                  in
                    ( offsetX + Scale.screenToImage model.scale dx
                    , offsetY + Scale.screenToImage model.scale dy
                    )
              }
            _ -> model'
      in
        newModel ! []

    EnterCanvas ->
      model ! []

    LeaveCanvas ->
      { model |
        draggingContext =
          case model.draggingContext of
            ShiftOffsetPrevScreenPos -> None
            _ -> model.draggingContext
      } ! []

    MouseDownOnObject lastTouchedId (clientX, clientY') ->
      let
        clientY = clientY' - 37

        (model', cmd) =
          if ObjectNameInput.isEditing model.objectNameInput then
            let
              (objectNameInput, ev) =
                ObjectNameInput.forceFinish model.objectNameInput
            in
              case ev of
                Just (id, name) ->
                  updateOnFinishNameInput False id name { model | objectNameInput = objectNameInput }

                Nothing ->
                  { model | objectNameInput = objectNameInput } ! []
          else
            model ! []

        -- TODO
        help model =
          { model |
            pos = (clientX, clientY)
          , selectedObjects =
              if model.keys.ctrl then
                if List.member lastTouchedId model.selectedObjects
                then List.filter ((/=) lastTouchedId) model.selectedObjects
                else lastTouchedId :: model.selectedObjects
              else if model.keys.shift then
                let
                  allObjects =
                    (EditingFloor.present model.floor).objects
                  objectsExcept target =
                    List.filter (\e -> idOf e /= idOf target) allObjects
                in
                  case (findObjectById allObjects lastTouchedId, primarySelectedObject model) of
                    (Just e, Just primary) ->
                      List.map idOf <|
                        primary :: (withinRange (primary, e) (objectsExcept primary)) --keep primary
                    _ -> [lastTouchedId]
              else
                if List.member lastTouchedId model.selectedObjects
                then model.selectedObjects
                else [lastTouchedId]
          , draggingContext = MoveObject lastTouchedId (clientX, clientY)
          , selectorRect = Nothing
          }
      in
        help model' ! [ cmd, emulateClick lastTouchedId True ]

    MouseUpOnObject lastTouchedId ->
      let
        (clientX, clientY) =
          model.pos

        (model', cmd) =
          -- TODO refactor to dedupe
          case model.draggingContext of
            MoveObject id (x, y) ->
              updateByMoveObjectEnd id (x, y) (clientX, clientY) model

            Selector ->
              { model |
                selectorRect =
                  case model.selectorRect of
                    Just (x, y, _, _) ->
                      let
                        (w, h) =
                          ( Scale.screenToImage model.scale clientX - x
                          , Scale.screenToImage model.scale clientY - y
                          )
                      in
                        Just (x, y, w, h)
                    _ -> model.selectorRect
              } ! []

            StampFromScreenPos _ ->
              updateOnFinishStamp model

            PenFromScreenPos pos ->
              updateOnFinishPen pos model

            ResizeFromScreenPos id pos ->
              updateOnFinishResize id pos model

            _ ->
              model ! []
      in
        { model' |
          draggingContext = None
        } ! [ cmd, emulateClick lastTouchedId False ]

    MouseUpOnCanvas ->
      let
        (clientX, clientY) =
          model.pos

        (model', cmd) =
          case model.draggingContext of
            MoveObject id (x, y) ->
              updateByMoveObjectEnd id (x, y) (clientX, clientY) model

            Selector ->
              { model |
                selectorRect =
                  case model.selectorRect of
                    Just (x, y, _, _) ->
                      let
                        (w, h) =
                          ( Scale.screenToImage model.scale clientX - x
                          , Scale.screenToImage model.scale clientY - y
                          )
                      in
                        Just (x, y, w, h)
                    _ -> model.selectorRect
              } ! []

            StampFromScreenPos _ ->
              updateOnFinishStamp model

            PenFromScreenPos pos ->
              updateOnFinishPen pos model

            ResizeFromScreenPos id pos ->
              updateOnFinishResize id pos model

            _ -> model ! []

        newModel =
          { model' |
            draggingContext = None
          }
      in
        newModel ! [ cmd ]

    MouseDownOnCanvas (clientX, clientY') ->
      let
        clientY = clientY' - 37

        selectorRect =
          case model.editMode of
            Select ->
              let
                (x, y) = fitPositionToGrid model.gridSize <|
                  screenToImageWithOffset model.scale (clientX, clientY) model.offset
              in
                Just (x, y, model.gridSize, model.gridSize)
            _ -> model.selectorRect

        draggingContext =
          case model.editMode of
            LabelMode ->
              None
            Stamp ->
              StampFromScreenPos (clientX, clientY)
            Pen ->
              PenFromScreenPos (clientX, clientY)
            Select ->
              ShiftOffsetPrevScreenPos
            Viewing _ ->
              ShiftOffsetPrevScreenPos

        (model', cmd) =
          case ObjectNameInput.forceFinish model.objectNameInput of
            (objectNameInput, Just (id, name)) ->
              updateOnFinishNameInput False id name { model | objectNameInput = objectNameInput }
            (objectNameInput, _) ->
              { model | objectNameInput = objectNameInput } ! []

        (model'', cmd2) =
          if model.editMode == LabelMode then
            updateOnFinishLabel model
          else
            (model', Cmd.none)

        newModel =
          { model'' |
            pos = (clientX, clientY)
          , selectedObjects = []
          , selectorRect = selectorRect
          , contextMenu = NoContextMenu
          , draggingContext = draggingContext
          }
      in
        newModel ! [ cmd, cmd2 ]

    MouseDownOnResizeGrip id ->
      let
        (clientX, clientY) =
          model.pos

        (model', cmd) =
          case ObjectNameInput.forceFinish model.objectNameInput of
            (objectNameInput, Just (id, name)) ->
              updateOnFinishNameInput False id name { model | objectNameInput = objectNameInput }
            (objectNameInput, _) ->
              { model | objectNameInput = objectNameInput } ! []

        newModel =
          { model' |
            selectedObjects = []
          , contextMenu = NoContextMenu
          , draggingContext = ResizeFromScreenPos id (clientX, clientY)
          }
      in
        newModel ! [ cmd ]

    StartEditObject id ->
      case findObjectById (EditingFloor.present model.floor).objects id of
        Just e ->
          let
            (id, name) = (idOf e, nameOf e)

            model' =
              { model |
                selectedResult = Nothing
              , contextMenu = NoContextMenu
              }

            (newModel, cmd) =
              startEditAndFocus e model
          in
            newModel !
              [ requestCandidate id name
              -- , Task.perform identity identity (Task.succeed MouseUpOnCanvas) -- TODO get rid of this hack
              , cmd
              ]

        Nothing ->
          model ! [] -- [ Task.perform identity identity (Task.succeed MouseUpOnCanvas) ] -- TODO get rid of this hack

    SelectBackgroundColor color ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.changeObjectBackgroundColor model.selectedObjects color) model.floor
      in
        { model |
          floor = newFloor
        } ! [ saveCmd ]

    SelectColor color ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.changeObjectColor model.selectedObjects color) model.floor
      in
        { model |
          floor = newFloor
        } ! [ saveCmd ]

    SelectShape shape ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.changeObjectShape model.selectedObjects shape) model.floor
      in
        { model |
          floor = newFloor
        } ! [ saveCmd ]

    ObjectNameInputMsg message ->
      let
        (objectNameInput, event) =
          ObjectNameInput.update message model.objectNameInput

        model' =
          { model |
            objectNameInput = objectNameInput
          }
      in
        case event of
          ObjectNameInput.OnInput id name ->
            model' ! [ requestCandidate id name ]

          ObjectNameInput.OnFinish objectId name candidateId ->
            case candidateId of
              Just personId ->
                updateOnSelectCandidate objectId personId model'

              Nothing ->
                updateOnFinishNameInput True objectId name model'

          ObjectNameInput.OnSelectCandidate objectId personId ->
            updateOnSelectCandidate objectId personId model'

          ObjectNameInput.OnUnsetPerson objectId ->
            let
              (newFloor, saveCmd) =
                EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.unsetPerson objectId) model.floor
            in
              { model' |
                floor = newFloor
              } ! [ saveCmd ]

          ObjectNameInput.None ->
            model' ! []

    RequestCandidate id name ->
      case model.candidateRequest of
        Waiting _ ->
          { model | candidateRequest = Waiting (Just (id, name)) } ! []

        NotWaiting ->
          { model | candidateRequest = Waiting Nothing }
          ! [ performAPI (GotCandidateSelection id) (API.personCandidate model.apiConfig name) ]

    ShowContextMenuOnObject id ->
      { model |
        contextMenu = Object model.pos id
      } ! []

    ShowContextMenuOnFloorInfo id ->
      { model |
        contextMenu =
          -- TODO idealy, change floor and show context menu
          if (EditingFloor.present model.floor).id == id then
            FloorInfo model.pos id
          else
            NoContextMenu
      } ! []

    HideContextMenu ->
      { model |
        contextMenu = NoContextMenu
      } ! []

    SelectIsland id ->
      let
        newModel =
          case findObjectById (EditingFloor.present model.floor).objects id of
            Just object ->
              let
                island' =
                  island
                    [object]
                    (List.filter (\e -> (idOf e) /= id)
                    (EditingFloor.present model.floor).objects)
              in
                { model |
                  selectedObjects = List.map idOf island'
                , contextMenu = NoContextMenu
                }
            Nothing ->
              model
      in
        newModel ! []

    KeyCodeMsg isDown keyCode ->
      let
        (keys, event) = ShortCut.update isDown keyCode model.keys
        model' =
          { model | keys = keys }
      in
        updateByKeyEvent event model'

    MouseWheel value ->
      let
        (clientX, clientY) = model.pos
        newScale =
            if value < 0 then
              Scale.update Scale.ScaleUp model.scale
            else
              Scale.update Scale.ScaleDown model.scale
        ratio =
          Scale.ratio model.scale newScale
        (offsetX, offsetY) =
          model.offset
        newOffset =
          let
            x = Scale.screenToImage model.scale clientX
            y = Scale.screenToImage model.scale (clientY - 37) --TODO header hight
          in
          ( floor (toFloat (x - floor (ratio * (toFloat (x - offsetX)))) / ratio)
          , floor (toFloat (y - floor (ratio * (toFloat (y - offsetY)))) / ratio)
          )
        newModel =
          { model |
            scale = newScale
          , offset = newOffset
          , scaling = True
          }
        cmd =
          Task.perform (always NoOp) (always ScaleEnd) (Process.sleep 200.0)
      in
        newModel ! [ cmd ]

    ScaleEnd ->
        { model | scaling = False } ! []

    WindowSize (w, h) ->
        { model | windowSize = (w, h) } ! []

    ChangeMode mode ->
        { model | editMode = mode } ! []

    PrototypesMsg action ->
      let
        newModel =
          { model |
            prototypes = Prototypes.update action model.prototypes
          , editMode = Stamp -- TODO if event == select
          }
      in
        newModel ! []

    RegisterPrototype id ->
      let
        object =
          findObjectById (EditingFloor.present model.floor).objects id
        model' =
          { model |
            contextMenu = NoContextMenu
          }
      in
        case object of
          Just e ->
            let
              (_, _, w, h) = rect e
              (newId, seed) = IdGenerator.new model.seed
              newPrototypes =
                Prototypes.register (newId, backgroundColorOf e, nameOf e, (w, h)) model.prototypes
            in
              { model' |
                seed = seed
              , prototypes = newPrototypes
              } ! [ (savePrototypesCmd model.apiConfig) newPrototypes.data ]

          Nothing ->
            model' ! []

    FloorPropertyMsg message ->
      let
        (floorProperty, cmd1, event) =
          FloorProperty.update message model.floorProperty

        ((newFloor, newSeed), cmd2) =
          updateFloorByFloorPropertyEvent model.apiConfig event model.seed model.floor

        newModel =
          { model |
            floor = newFloor
          , floorProperty = floorProperty
          , seed = newSeed
          }
      in
        newModel ! [ Cmd.map FloorPropertyMsg cmd1, cmd2 ]

    Rotate id ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.rotateObject id) model.floor
      in
        { model |
          floor = newFloor
        , contextMenu = NoContextMenu
        } ! [ saveCmd ]

    FirstNameOnly ids ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.toFirstNameOnly ids) model.floor
      in
        { model |
          floor = newFloor
        , contextMenu = NoContextMenu
        } ! [ saveCmd ]

    HeaderMsg action ->
      let
        (cmd, event) =
          Header.update action

        (newModel, cmd2) =
          case event of
            Header.OnLogout ->
              model ! [ (removeToken {}) ]

            Header.OnToggleEditing ->
              let
                nextIsEditing =
                  case model.editMode of
                    Viewing _ -> True
                    _ -> False
              in
                model !
                  [ Navigation.modifyUrl <|
                      URL.stringify <|
                        URL.updateEditMode nextIsEditing model.url
                  ]

            Header.OnTogglePrintView opened ->
              { model |
                editMode =
                  if opened then
                    Viewing True
                  else if model.url.editMode then
                    Select
                  else
                    Viewing False
              } ! []

            Header.None ->
              model ! []
      in
        newModel ! [ Cmd.map HeaderMsg cmd, cmd2 ]

    SearchBoxMsg msg ->
      let
        (searchBox, cmd1, event) =
          SearchBox.update msg model.searchBox

        model' =
          { model | searchBox = searchBox }

        (selectedResult, cmd2) =
          updateOnSearchBoxEvent event model'

        newOffset =
          adjustOffset selectedResult model'

        model'' =
          { model' |
            selectedResult = selectedResult
          , offset = newOffset
          }

        newModel =
          case selectedResult of
            Just id -> adjustPositionByFocus id model''
            Nothing -> model''

      in
        newModel ! [ Cmd.map SearchBoxMsg cmd1, cmd2 ]

    RegisterPeople people ->
      { model |
        personInfo =
          addAll (.id) people model.personInfo
      } ! []

    GotCandidateSelection objectId people ->
      let
        newRequestCmd =
          case model.candidateRequest of
            Waiting (Just (id, name)) ->
              Task.perform identity identity <| Task.succeed (RequestCandidate id name)
            Waiting Nothing ->
              Cmd.none
            NotWaiting ->
              Cmd.none
        newModel =
          { model |
            candidateRequest = NotWaiting
          , personInfo =
              addAll (.id) people model.personInfo
          , candidates = List.map .id people
          }
      in
        newModel ! [ newRequestCmd ]

    UpdatePersonCandidate objectId personIds ->
      let
        (newFloor, saveCmd) =
          case personIds of
            head :: _ :: _ ->
              EditingFloor.commit
                (saveFloorCmd model.apiConfig)
                (Floor.setPerson objectId head)
                model.floor

            _ ->
              model.floor ! []
      in
        { model |
          floor = newFloor
        } ! [ saveCmd ]

    GotDiffSource diffSource ->
      { model | diff = Just diffSource } ! []

    CloseDiff ->
      { model | diff = Nothing } ! []

    ConfirmDiff ->
      let
        floor =
          (EditingFloor.present model.floor)

        (cmd, newSeed, newFloor) =
          ( publishFloorCmd model.apiConfig floor FloorDiff.noObjectsChange
          , model.seed
          , model.floor
          )
      in
        { model |
          diff = Nothing
        , seed = newSeed
        , floor = newFloor
        } ! [ cmd ]

    ChangeTab tab ->
      { model | tab = tab } ! []

    ClosePopup ->
      { model | selectedResult = Nothing } ! []

    ShowDetailForObject id ->
      let
        allObjects = (EditingFloor.present model.floor).objects
        personId =
          case findObjectById allObjects id of
            Just e ->
              relatedPerson e
            Nothing ->
              Nothing
        cmd =
          case personId of
            Just id -> regesterPerson model.apiConfig id
            Nothing -> Cmd.none

        selectedResult =
          Just id

        newOffset =
          adjustOffset selectedResult model
      in
        { model |
          selectedResult = selectedResult
        , offset = newOffset
        } ! [ cmd ]

    CreateNewFloor ->
      let
        (newFloorId, newSeed) =
          IdGenerator.new model.seed

        lastFloorOrder =
          case List.drop (List.length model.floorsInfo - 1) model.floorsInfo of
            [] ->
              0
            x :: _ ->
              case x of
                FloorInfo.Public floor ->
                  floor.ord
                FloorInfo.PublicWithEdit publicFloor editingFloor ->
                  editingFloor.ord
                FloorInfo.Private floor ->
                  floor.ord

        newFloor =
          Floor.initWithOrder newFloorId lastFloorOrder

        cmd =
          performAPI
            (always (NewFloorCreated newFloorId))
            (API.saveEditingFloor model.apiConfig newFloor (snd <| FloorDiff.diff newFloor Nothing))
      in
        { model | seed = newSeed } ! [ cmd ]

    CopyFloor id ->
      let
        (newFloorId, newSeed) =
          IdGenerator.new model.seed

        newFloor =
          Floor.copy newFloorId (EditingFloor.present model.floor)

        cmd =
          performAPI
            (always (NewFloorCreated newFloorId))
            (API.saveEditingFloor model.apiConfig newFloor (snd <| FloorDiff.diff newFloor Nothing))
      in
        { model |
          seed = newSeed
        , contextMenu = NoContextMenu
        } ! [ cmd ]

    NewFloorCreated newFloorId ->
      model !
        [ Navigation.modifyUrl (URL.stringify <| URL.updateFloorId (Just newFloorId) model.url)
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
              [ Task.perform identity identity (Task.succeed (StartEditObject id)) ]
            else
              []
            )

    TokenRemoved ->
      { model |
        user = User.guest
      , tab = SearchTab
      , editMode = Viewing False
      } ! []

    Error e ->
      let
        newModel =
          { model | error = e }
      in
        newModel ! []


startEditAndFocus : Object -> Model -> (Model, Cmd Msg)
startEditAndFocus e model =
  { model |
    objectNameInput = ObjectNameInput.start (idOf e, nameOf e) model.objectNameInput
  } !
    [ focusCmd "name-input"
    ]


updateOnSearchBoxEvent : SearchBox.Event -> Model -> (Maybe Id, Cmd Msg)
updateOnSearchBoxEvent event model =
  case event of
    SearchBox.OnSubmit ->
      ( Nothing
      , Navigation.modifyUrl ( URL.stringify <| URL.updateQuery model.searchBox.query model.url )
      )

    SearchBox.OnResults ->
      let
        results =
          SearchBox.allResults model.searchBox

        regesterPersonCmd =
          Cmd.batch <|
          List.filterMap (\r ->
            case r.personId of
              Just id -> Just (regesterPersonIfNotCached model.apiConfig model.personInfo id)
              Nothing -> Nothing
          ) results

        selectedResult =
          case results of
            { objectIdAndFloorId } :: [] ->
              case objectIdAndFloorId of
                Just (e, fid) ->
                  Just (idOf e)
                Nothing ->
                  Nothing
            _ -> Nothing
      in
        (selectedResult, regesterPersonCmd)

    SearchBox.OnSelectResult { personId, objectIdAndFloorId } ->
      let
        (selectedResult, cmd1) =
          case objectIdAndFloorId of
            Just (e, fid) ->
              ( Just (idOf e)
              , Navigation.modifyUrl (URL.stringify <| URL.updateFloorId (Just fid) model.url)
              )
            Nothing ->
              (Nothing, Cmd.none)

        cmd2 =
          case personId of
            Just id -> (regesterPersonIfNotCached model.apiConfig model.personInfo id)
            Nothing -> Cmd.none
      in
        (selectedResult, Cmd.batch [cmd1, cmd2])

    SearchBox.OnError e ->
      (Nothing, performAPI (always NoOp) (Task.fail e))

    SearchBox.None ->
      (model.selectedResult, Cmd.none)


adjustOffset : Maybe Id -> Model -> (Int, Int)
adjustOffset selectedResult model =
  let
    maybeShiftedOffset =
      selectedResult `Maybe.andThen` \id ->
      findObjectById (EditingFloor.present model.floor).objects id `Maybe.andThen` \e ->
      relatedPerson e `Maybe.andThen` \personId ->
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
            e
    in
      Maybe.withDefault model.offset maybeShiftedOffset


updateOnSelectCandidate : Id -> String -> Model -> (Model, Cmd Msg)
updateOnSelectCandidate objectId personId model =
  case Dict.get personId model.personInfo of
    Just person ->
      let
        (newFloor, cmd) =
          EditingFloor.commit
            (saveFloorCmd model.apiConfig)
            (Floor.setPerson objectId personId)
            model.floor

        (newModel, cmd2) =
          updateOnFinishNameInput True objectId person.name
            { model |
              floor = newFloor
            }
      in
        newModel ! [ cmd, cmd2 ]

    Nothing ->
      model ! [] -- maybe never happen


requestCandidate : Id -> String -> Cmd Msg
requestCandidate id name =
  Task.perform identity identity <| Task.succeed (RequestCandidate id name)


emulateClick : String -> Bool -> Cmd Msg
emulateClick id down =
  Task.perform identity identity <|
  Time.now `Task.andThen` \time ->
  (Task.succeed (EmulateClick id down time))


noOpCmd : Task a () -> Cmd Msg
noOpCmd task =
  Task.perform (always NoOp) (always NoOp) task


updateOnFinishStamp : Model -> (Model, Cmd Msg)
updateOnFinishStamp model =
  let
    (candidatesWithNewIds, newSeed) =
      IdGenerator.zipWithNewIds model.seed (stampCandidates model)

    candidatesWithNewIds' =
      List.map
        (\(((_, color, name, (w, h)), (x, y)), newId) -> (newId, (x, y, w, h), color, name))
        candidatesWithNewIds

    (newFloor, cmd) =
      EditingFloor.commit
        (saveFloorCmd model.apiConfig)
        (Floor.createDesk candidatesWithNewIds')
        model.floor
  in
    { model |
      seed = newSeed
    , floor = newFloor
    , editMode = Select -- maybe selecting stamped desks would be better?
    } ! [ cmd ]


updateOnFinishPen : (Int, Int) -> Model -> (Model, Cmd Msg)
updateOnFinishPen (x, y) model =
  let
    (newFloor, newSeed, cmd) =
      case temporaryPen model (x, y) of
        Just (color, name, (left, top, width, height)) ->
          let
            (newId, newSeed) =
              IdGenerator.new model.seed

            (newFloor, cmd) =
              EditingFloor.commit
                (saveFloorCmd model.apiConfig)
                (Floor.createDesk [(newId, (left, top, width, height), color, name)])
                model.floor
          in
            ( newFloor
            , newSeed
            , cmd
            )

        Nothing ->
          (model.floor, model.seed, Cmd.none)
  in
    { model |
      seed = newSeed
    , floor = newFloor
    } ! [ cmd ]


updateOnFinishResize : Id -> (Int, Int) -> Model -> (Model, Cmd Msg)
updateOnFinishResize id (x, y) model =
  case findObjectById (EditingFloor.present model.floor).objects id of
    Just e ->
      let
        (newFloor, cmd) =
          case temporaryResizeRect model (x, y) (rect e) of
            Just (_, _, width, height) ->
              EditingFloor.commit
                (saveFloorCmd model.apiConfig)
                (Floor.resizeObject id (width, height))
                model.floor

            Nothing ->
              model.floor ! []
      in
        { model | floor = newFloor } ! [ cmd ]

    Nothing ->
      model ! []


updateOnFinishLabel : Model -> (Model, Cmd Msg)
updateOnFinishLabel model =
  let
    (left, top) =
      fitPositionToGrid model.gridSize <|
        screenToImageWithOffset model.scale model.pos model.offset

    (width, height) =
      fitSizeToGrid model.gridSize (100, 100) -- TODO configure?

    bgColor = "transparent" -- text color TODO configure?

    color = "#000"

    name = ""

    fontSize = 40 -- TODO

    (newId, newSeed) =
      IdGenerator.new model.seed

    (newFloor, saveCmd) =
      EditingFloor.commit
        (saveFloorCmd model.apiConfig)
        (Floor.createLabel [(newId, (left, top, width, height), bgColor, name, fontSize, color)])
        model.floor

    model' =
      { model |
        seed = newSeed
      , editMode = Select
      , floor = newFloor
      }
  in
    case findObjectById (EditingFloor.present model'.floor).objects newId of
      Just e ->
        let
          (newModel, cmd) =
            startEditAndFocus e model'
        in
          newModel ! [ saveCmd, cmd ]

      Nothing ->
        model' ! [ saveCmd ]


updateOnFloorLoaded : Floor -> Model -> (Model, Cmd Msg)
updateOnFloorLoaded floor model =
  let
    (realWidth, realHeight) =
      Floor.realSize floor

    newModel =
      { model |
        floor = EditingFloor.init floor
      , floorProperty = FloorProperty.init floor.name realWidth realHeight floor.ord
      }

    cmd =
      case floor.update of
        Nothing -> Cmd.none
        Just { by } ->
          case Dict.get by model.personInfo of
            Just _ -> Cmd.none
            Nothing ->
              let
                task =
                  API.getPersonByUser model.apiConfig by `andThen` \person ->
                    Task.succeed (RegisterPeople [person])
              in
                performAPI identity task
  in
    newModel ! [ cmd ]


updateFloorByFloorPropertyEvent : API.Config -> FloorProperty.Event -> Seed -> EditingFloor -> ((EditingFloor, Seed), Cmd Msg)
updateFloorByFloorPropertyEvent apiConfig event seed efloor =
    case event of
      FloorProperty.None ->
        (efloor, seed) ! []

      FloorProperty.OnNameChange name ->
        let
          (newFloor, saveCmd) =
            EditingFloor.commit
              (saveFloorCmd apiConfig)
              (Floor.changeName name)
              efloor
        in
          (newFloor, seed) ! [ saveCmd ]

      FloorProperty.OnOrdChange ord ->
        let
          (newFloor, saveCmd) =
            EditingFloor.commit
              (saveFloorCmd apiConfig)
              (Floor.changeOrd ord)
              efloor
        in
          (newFloor, seed) ! [ saveCmd ]

      FloorProperty.OnRealSizeChange (w, h) ->
        let
          (newFloor, saveCmd) =
            EditingFloor.commit
              (saveFloorCmd apiConfig)
              (Floor.changeRealSize (w, h))
              efloor
        in
          (newFloor, seed) ! [ saveCmd ]

      FloorProperty.OnFileWithDataURL file dataURL ->
        let
          (id, newSeed) =
            IdGenerator.new seed

          (newFloor, saveCmd) =
            EditingFloor.commit
              (saveFloorCmd apiConfig)
              (Floor.setLocalFile id file dataURL)
              efloor
        in
          (newFloor, newSeed) ! [ saveCmd ]

      FloorProperty.OnPreparePublish ->
        let
          cmd =
            performAPI GotDiffSource (API.getDiffSource apiConfig (EditingFloor.present efloor).id)
        in
          (efloor, seed) ! [ cmd ]

      FloorProperty.OnFileLoadFailed err ->
        let
          cmd =
            Task.perform (Error << FileError) (always NoOp) (Task.fail err)
        in
          (efloor, seed) ! [ cmd ]


regesterPersonOfObject : API.Config -> Object -> Cmd Msg
regesterPersonOfObject apiConfig e =
  case Object.relatedPerson e of
    Just personId ->
      regesterPerson apiConfig personId
    Nothing ->
      Cmd.none


regesterPerson : API.Config -> String -> Cmd Msg
regesterPerson apiConfig personId =
  performAPI identity <|
    API.getPerson apiConfig personId `andThen` \person ->
      Task.succeed (RegisterPeople [person])


regesterPersonIfNotCached : API.Config -> Dict String Person -> String -> Cmd Msg
regesterPersonIfNotCached apiConfig personInfo personId =
  if Dict.member personId personInfo then
    Cmd.none
  else
    regesterPerson apiConfig personId


updateOnFinishNameInput : Bool -> String -> String -> Model -> (Model, Cmd Msg)
updateOnFinishNameInput continueEditing id name model =
  let
    allObjects = (EditingFloor.present model.floor).objects

    (objectNameInput, requestCandidateCmd) =
      case findObjectById allObjects id of
        Just object ->
          if continueEditing then
            case nextObjectToInput object allObjects of
              Just e ->
                ( ObjectNameInput.start (idOf e, nameOf e) model.objectNameInput
                , requestCandidate (idOf e) (nameOf e)
                )

              Nothing ->
                ( model.objectNameInput
                , requestCandidate id name
                )
          else
            (model.objectNameInput, Cmd.none)

        Nothing ->
          (model.objectNameInput, Cmd.none)

    updatePersonCandidateCmd =
      case findObjectById allObjects id of
        Just object ->
          updatePersonCandidateAndRegisterPersonDetailIfAPersonIsNotRelatedTo model.apiConfig object

        Nothing ->
          Cmd.none

    selectedObjects =
      case objectNameInput.editingObject of
        Just (id, _) ->
          [id]

        Nothing ->
          []

    (newFloor, saveCmd) =
      EditingFloor.commit
        (saveFloorCmd model.apiConfig)
        (Floor.changeObjectName [id] name)
        model.floor

    newModel =
      { model |
        floor = newFloor
      , objectNameInput = objectNameInput
      , candidates = []
      , selectedObjects = selectedObjects
      }
  in
    newModel ! [ requestCandidateCmd, updatePersonCandidateCmd, saveCmd ]


updatePersonCandidateAndRegisterPersonDetailIfAPersonIsNotRelatedTo : API.Config -> Object -> Cmd Msg
updatePersonCandidateAndRegisterPersonDetailIfAPersonIsNotRelatedTo apiConfig object =
  case Object.relatedPerson object of
    Just personId ->
      Cmd.none

    Nothing ->
      let
        task =
          API.personCandidate apiConfig (nameOf object) `andThen` \people ->
          Task.succeed (RegisterPeople people) `andThen` \_ ->
          Task.succeed (UpdatePersonCandidate (idOf object) (List.map .id people))
      in
        performAPI identity task

nextObjectToInput : Object -> List Object -> Maybe Object
nextObjectToInput object allObjects =
  let
    island' =
      island
        [object]
        (List.filter (\e -> (idOf e) /= (idOf object)) allObjects)
  in
    case ObjectsOperation.nearest ObjectsOperation.Down object island' of
      Just e ->
        if idOf object == idOf e then
          Nothing
        else
          Just e
      _ ->
        Nothing


adjustPositionByFocus : Id -> Model -> Model
adjustPositionByFocus focused model = model


savePrototypesCmd : API.Config -> List Prototype -> Cmd Msg
savePrototypesCmd apiConfig prototypes =
  performAPI
    (always (NoOp))
    (API.savePrototypes apiConfig prototypes)


saveFloorCmd : API.Config -> Floor -> ObjectsChange -> Cmd Msg
saveFloorCmd apiConfig floor change =
  let
    firstTask =
      case floor.imageSource of
        Floor.LocalFile id file url ->
          API.saveEditingImage apiConfig id file
        _ ->
          Task.succeed ()

    secondTask =
      API.saveEditingFloor apiConfig floor change
  in
    performAPI
      (FloorSaved False)
      (firstTask `andThen` (always secondTask))


publishFloorCmd : API.Config -> Floor -> ObjectsChange -> Cmd Msg
publishFloorCmd apiConfig floor change =
  let
    firstTask =
      case floor.imageSource of
        Floor.LocalFile id file url ->
          API.saveEditingImage apiConfig id file
        _ ->
          Task.succeed ()

    secondTask =
      API.publishEditingFloor apiConfig floor.id
  in
    performAPI
      (FloorSaved True)
      (firstTask `andThen` (always secondTask))


updateByKeyEvent : ShortCut.Event -> Model -> (Model, Cmd Msg)
updateByKeyEvent event model =
  case (model.keys.ctrl, event) of
    (True, ShortCut.A) ->
      { model |
        selectedObjects =
          List.map idOf <| Floor.objects (EditingFloor.present model.floor)
      } ! []

    (True, ShortCut.C) ->
      { model |
        copiedObjects = selectedObjects model
      } ! []

    (True, ShortCut.V) ->
      let
        base =
          case model.selectorRect of
            Just (x, y, w, h) ->
              (x, y)
            Nothing -> (0, 0) --TODO

        (copiedIdsWithNewIds, newSeed) =
          IdGenerator.zipWithNewIds model.seed model.copiedObjects

        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.paste copiedIdsWithNewIds base) model.floor
      in
        { model |
          floor = newFloor
        , seed = newSeed
        , selectedObjects = List.map snd copiedIdsWithNewIds
        , selectorRect = Nothing
        } ! [ saveCmd ]

    (True, ShortCut.X) ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.delete model.selectedObjects) model.floor
      in
        { model |
          floor = newFloor
        , copiedObjects = selectedObjects model
        , selectedObjects = []
        } ! [ saveCmd ]

    (True, ShortCut.Y) ->
      { model | floor = EditingFloor.redo model.floor } ! []

    (True, ShortCut.Z) ->
      { model | floor = EditingFloor.undo model.floor } ! []

    (_, ShortCut.UpArrow) ->
      shiftSelectionToward ObjectsOperation.Up model ! []

    (_, ShortCut.DownArrow) ->
      shiftSelectionToward ObjectsOperation.Down model ! []

    (_, ShortCut.LeftArrow) ->
      shiftSelectionToward ObjectsOperation.Left model ! []

    (_, ShortCut.RightArrow) ->
      shiftSelectionToward ObjectsOperation.Right model ! []

    (_, ShortCut.Del) ->
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.delete model.selectedObjects) model.floor
      in
        { model |
          floor = newFloor
        } ! [ saveCmd ]

    -- (_, ShortCut.Other 9) -> -- maybe "shift within island is the proper behavior"

    _ ->
      model ! []


updateByMoveObjectEnd : Id -> (Int, Int) -> (Int, Int) -> Model -> (Model, Cmd Msg)
updateByMoveObjectEnd id (x0, y0) (x1, y1) model =
  let
    shift =
      Scale.screenToImageForPosition model.scale (x1 - x0, y1 - y0)
  in
    if shift /= (0, 0) then
      let
        (newFloor, saveCmd) =
          EditingFloor.commit (saveFloorCmd model.apiConfig) (Floor.move model.selectedObjects model.gridSize shift) model.floor
      in
        { model |
          floor = newFloor
        } ! [ saveCmd ]
    else if not model.keys.ctrl && not model.keys.shift then
      { model |
        selectedObjects = [id]
      } ! []
    else
      model ! []


candidatesOf : Model -> List Person
candidatesOf model =
  List.filterMap (\personId -> Dict.get personId model.personInfo) model.candidates


shiftSelectionToward : ObjectsOperation.Direction -> Model -> Model
shiftSelectionToward direction model =
  let
    floor = (EditingFloor.present model.floor)
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
                _ -> model.selectedObjects
        in
          { model |
            selectedObjects = toBeSelected
          }
      _ -> model


loadAuthCmd : API.Config -> Cmd Msg
loadAuthCmd apiConfig =
    performAPI AuthLoaded (API.getAuth apiConfig)


loadFloorsInfoCmd : API.Config -> Bool -> Cmd Msg
loadFloorsInfoCmd apiConfig withPrivate =
    performAPI FloorsInfoLoaded (API.getFloorsInfo apiConfig withPrivate)


loadFloorCmd : API.Config -> Bool -> String -> Cmd Msg
loadFloorCmd apiConfig forEdit floorId =
  let
    recover404 e =
      case e of
        Http.BadResponse 404 _ ->
          FloorLoaded (Floor.init floorId)
        _ ->
          Error (APIError e)

    task =
      if forEdit then
        API.getEditingFloor apiConfig floorId
      else
        API.getFloor apiConfig floorId
  in
    Task.perform recover404 FloorLoaded task


focusCmd : String -> Cmd Msg
focusCmd id =
  Task.perform (Error << HtmlError) (always NoOp) (Dom.focus id)


blurCmd : String -> Cmd Msg
blurCmd id =
  Task.perform (Error << HtmlError) (always NoOp) (Dom.blur id)


-- TODO bad naming
isSelected : Model -> Object -> Bool
isSelected model object =
  case model.editMode of
    Viewing _ -> False
    _ -> List.member (idOf object) model.selectedObjects


primarySelectedObject : Model -> Maybe Object
primarySelectedObject model =
  case model.selectedObjects of
    head :: _ ->
      findObjectById (objects <| (EditingFloor.present model.floor)) head
    _ -> Nothing


selectedObjects : Model -> List Object
selectedObjects model =
  List.filterMap (\id ->
    findObjectById (EditingFloor.present model.floor).objects id
  ) model.selectedObjects


screenToImageWithOffset : Scale.Model -> (Int, Int) -> (Int, Int) -> (Int, Int)
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
        (prototypeId, color, name, deskSize) =
          prototype
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
              (deskWidth, deskHeight) = deskSize
              (left, top) =
                fitPositionToGrid model.gridSize (x2' - deskWidth // 2, y2' - deskHeight // 2)
            in
              [ ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top))
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


currentFloorForView : Model -> Maybe Floor
currentFloorForView model =
  case model.editMode of
    Viewing _ ->
      FloorInfo.findViewingFloor model.url.floorId model.floorsInfo

    _ ->
      Just (EditingFloor.present model.floor)

--
