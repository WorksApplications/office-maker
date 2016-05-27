module Model exposing (..) -- where

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
import Http

import Util.UndoRedo as UndoRedo
import Util.ShortCut as ShortCut
import Util.HtmlUtil as HtmlUtil exposing (..)
import Util.IdGenerator as IdGenerator exposing (Seed)
import Util.DictUtil exposing (..)

import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Equipments as Equipments exposing (..)
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Model.Scale as Scale
import Model.API as API
import Model.Prototypes as Prototypes exposing (..)
import Model.Floor as Floor exposing (Model, setEquipments, setLocalFile, equipments, addEquipments)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.URL as URL

import FloorProperty
import SearchBox
import Header exposing (..)
import EquipmentNameInput

type alias Floor = Floor.Model

type alias Commit = Floor.Msg

type alias Model =
  { seed : Seed
  , visitDate : Date
  , user : User
  , pos : (Int, Int)
  , draggingContext : DraggingContext
  , selectedEquipments : List Id
  , copiedEquipments : List Equipment
  , equipmentNameInput : EquipmentNameInput.Model
  , gridSize : Int
  , selectorRect : Maybe (Int, Int, Int, Int)
  , keys : ShortCut.Model
  , editMode : EditMode
  , colorPalette : List String
  , contextMenu : ContextMenu
  , floor : UndoRedo.Model Floor Commit
  , floorsInfo : List Floor
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
  }

type ContextMenu =
    NoContextMenu
  | Equipment (Int, Int) Id

type EditMode =
    Viewing
  | Select
  | Pen
  | Stamp

type DraggingContext =
    None
  | MoveEquipment Id (Int, Int)
  | Selector
  | ShiftOffsetPrevScreenPos
  | PenFromScreenPos (Int, Int)
  | StampFromScreenPos (Int, Int)

type Tab =
  SearchTab | EditTab

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Window.resizes (\e -> WindowSize (e.width, e.height))
    , Keyboard.downs (KeyCodeMsg True)
    , Keyboard.ups (KeyCodeMsg False)
    ]

gridSize : Int
gridSize = 8 -- 2^N

init : (Int, Int) -> (Int, Int) -> (Result String URL.Model) -> Float -> (Model, Cmd Msg)
init randomSeed initialSize urlResult visitDate =
  let
    initialFloor =
      Floor.init Nothing
    toModel url searchBox =
      { seed = IdGenerator.init randomSeed
      , visitDate = Date.fromTime visitDate
      , user = User.guest
      , pos = (0, 0)
      , draggingContext = None
      , selectedEquipments = []
      , copiedEquipments = []
      , equipmentNameInput = EquipmentNameInput.init
      , gridSize = gridSize
      , selectorRect = Nothing
      , keys = ShortCut.init
      , editMode = Viewing
      , colorPalette = []
      , contextMenu = NoContextMenu
      , floorsInfo = []
      , floor = UndoRedo.init { data = initialFloor, update = Floor.update }
      , windowSize = initialSize
      , scale = Scale.init
      , offset = (35, 35)
      , scaling = False
      , prototypes = Prototypes.init []
      , error = NoError
      , floorProperty = FloorProperty.init initialFloor.name 0 0
      , selectedResult = Nothing
      , personInfo = Dict.empty
      , diff = Nothing
      , candidates = []
      , url = url
      , searchBox = searchBox
      , tab = SearchTab
      }
    initCmd =
      Task.perform (always NoOp) identity (Task.succeed Init)
  in
    case urlResult of
      Ok url ->
        (toModel url (SearchBox.init url.query)) ! [ initCmd ]
      Err _ ->
        let
          dummyURL = URL.dummy
        in
          (toModel URL.dummy (SearchBox.init dummyURL.query))
          ! [ initCmd ] -- TODO modifyURL

--

type Msg = NoOp
  | Init
  | AuthLoaded User
  | FloorsInfoLoaded (List Floor)
  | FloorLoaded Floor
  | DraftFloorLoaded (Maybe Floor)
  | ColorsLoaded (List String)
  | PrototypesLoaded (List Prototype)
  | FloorSaved Bool
  | MoveOnCanvas (Int, Int)
  | EnterCanvas
  | LeaveCanvas
  | MouseUpOnCanvas
  | MouseDownOnCanvas
  | MouseDownOnEquipment Id
  | StartEditEquipment Id
  | KeyCodeMsg Bool Int
  | SelectColor String
  | EquipmentNameInputMsg EquipmentNameInput.Msg
  | ShowContextMenuOnEquipment Id
  | SelectIsland Id
  | WindowSize (Int, Int)
  | MouseWheel Float
  | ChangeMode EditMode
  | ScaleEnd
  | PrototypesMsg Prototypes.Msg
  | RegisterPrototype Id
  | FloorPropertyMsg FloorProperty.Msg
  | Rotate Id
  | HeaderMsg Header.Msg
  | SearchBoxMsg SearchBox.Msg
  | ChangeEditing Bool
  | RegisterPeople (List Person)
  | GotCandidateSelection Id (List Person)
  | UpdatePersonCandidate Id (List Id)
  | GotDiffSource (Floor, Maybe Floor)
  | CloseDiff
  | ConfirmDiff
  | ChangeTab Tab
  | Error GlobalError

debug : Bool
debug = False

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

        (newSearchBox, searchBoxCmd) =
          case newURL.query of
            Just query ->
              let
                withPrivate =
                  not (User.isGuest model.user)
              in
                SearchBox.doSearch SearchBoxMsg withPrivate query model.searchBox
            Nothing ->
              (model.searchBox, Cmd.none)

        forEdit = not (User.isGuest model.user)
        loadFloorCmd' =
          if String.length floorId == 36 then
            -- Debug.log "1" <|
              loadFloorCmd forEdit (Just floorId)
          else if floorId == "" then
              loadDraftFloor model.user
          else
            -- Debug.log "4" <|
              Cmd.none
      in
        { model |
          url = newURL
        , editMode =
            if User.isAdmin model.user then
              if newURL.editMode then Select else Viewing
            else
              Viewing
        , searchBox = newSearchBox
        } ! [ loadFloorCmd', searchBoxCmd ]
    Err _ ->
      let
        validURL = URL.validate model.url
      in
        model ! [ Navigation.modifyUrl (URL.stringify validURL) ]

update : Msg -> Model -> (Model, Cmd Msg)
update action model =
  case debugMsg action of
    NoOp ->
      model ! []
    Init ->
      model ! [ loadAuthCmd ]
    AuthLoaded user ->
      let
        requestPrivateFloors = not (User.isGuest user)
        floorId = model.url.floorId
        forEdit = not (User.isGuest model.user)
        loadFloorCmd' =
          if String.length floorId == 36 then
            loadFloorCmd forEdit (Just floorId)
          else
            loadDraftFloor user
        loadSettingsCmd =
          if User.isGuest user then
            Cmd.none
          else
            Cmd.batch
              [ performAPI ColorsLoaded API.getColors
              , performAPI PrototypesLoaded API.getPrototypes
              ]
      in
        { model |
          user = user
        , editMode =
            if User.isAdmin user then
              if model.url.editMode then Select else Viewing
            else
              Viewing
        }
        ! [ loadFloorsInfoCmd requestPrivateFloors
          , loadFloorCmd'
          , loadSettingsCmd
          ]
    ColorsLoaded colors ->
      { model | colorPalette = colors } ! []
    PrototypesLoaded prototypeList ->
      { model | prototypes = Prototypes.init prototypeList } ! []
    FloorsInfoLoaded floors ->
      { model | floorsInfo = floors } ! []
    FloorLoaded floor ->
      updateOnFloorLoaded floor model
    DraftFloorLoaded maybeFloor ->
      case maybeFloor of
        Just floor ->
          updateOnFloorLoaded floor model
        Nothing ->
          if not (User.isGuest model.user) then
            let
              draftFloor = Floor.init Nothing
              floor = UndoRedo.init { data = draftFloor, update = Floor.update }
            in
              { model | floor = floor }
              ! [ saveFloorCmd draftFloor ]
          else
            model ! []

    FloorSaved isPublish ->
      let
        newFloorId =
          (UndoRedo.data model.floor).id

        (message, cmd) =
          if isPublish then
            let
              newFloorId' =
                case newFloorId of
                  Just id ->
                    id
                  Nothing ->
                    Debug.crash "new id not found."
              message = Success ("Successfully published " ++ newFloorId')
            in
              message !
                [ Task.perform (always NoOp) Error <| (Process.sleep 3000.0 `andThen` \_ -> Task.succeed NoError)
                , Navigation.modifyUrl (URL.stringify <| URL.updateFloorId newFloorId model.url)
                ]
          else
            model.error ! []
      in
        { model |
          floor = UndoRedo.commit model.floor (Floor.onSaved isPublish)
        , error = message
        } ! [ cmd ]
    MoveOnCanvas (clientX, clientY) ->
      let
        (x, y) = (clientX, clientY - 37)
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
    MouseDownOnEquipment lastTouchedId ->
      let
        (clientX, clientY) = model.pos
        newModel =
          { model |
            selectedEquipments =
              if model.keys.ctrl then
                if List.member lastTouchedId model.selectedEquipments
                then List.filter ((/=) lastTouchedId) model.selectedEquipments
                else lastTouchedId :: model.selectedEquipments
              else if model.keys.shift then
                let
                  allEquipments =
                    (UndoRedo.data model.floor).equipments
                  equipmentsExcept target =
                    List.filter (\e -> idOf e /= idOf target) allEquipments
                in
                  case (findEquipmentById allEquipments lastTouchedId, primarySelectedEquipment model) of
                    (Just e, Just primary) ->
                      List.map idOf <|
                        primary :: (withinRange (primary, e) (equipmentsExcept primary)) --keep primary
                    _ -> [lastTouchedId]
              else
                if List.member lastTouchedId model.selectedEquipments
                then model.selectedEquipments
                else [lastTouchedId]
          , draggingContext = MoveEquipment lastTouchedId (clientX, clientY)
          , selectorRect = Nothing
          }
      in
        newModel ! []
    MouseUpOnCanvas ->
      let
        (clientX, clientY) = model.pos
        (model', cmd) =
          case model.draggingContext of
            MoveEquipment id (x, y) ->
              let
                newModel =
                  updateByMoveEquipmentEnd id (x, y) (clientX, clientY) model
                cmd =
                  saveFloorCmd (UndoRedo.data newModel.floor)
              in
                newModel ! [ cmd ]
            Selector ->
              ({ model |
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
              }, Cmd.none)
            StampFromScreenPos _ ->
              let
                (candidatesWithNewIds, newSeed) =
                  IdGenerator.zipWithNewIds model.seed (stampCandidates model)
                candidatesWithNewIds' =
                  List.map
                    (\(((_, color, name, (w, h)), (x, y)), newId) -> (newId, (x, y, w, h), color, name))
                    candidatesWithNewIds
                newFloor =
                  UndoRedo.commit model.floor (Floor.create candidatesWithNewIds')
                cmd =
                  saveFloorCmd (UndoRedo.data newFloor)
              in
                { model |
                  seed = newSeed
                , floor = newFloor
                } ! [ cmd ]
            PenFromScreenPos (x, y) ->
              let
                (newFloor, newSeed, cmd) =
                  case temporaryPen model (x, y) of
                    Just (color, name, (left, top, width, height)) ->
                      let
                        (newId, newSeed) =
                          IdGenerator.new model.seed
                        newFloor =
                          UndoRedo.commit model.floor (Floor.create [(newId, (left, top, width, height), color, name)])
                      in
                        ( newFloor
                        , newSeed
                        , saveFloorCmd (UndoRedo.data newFloor)
                        )
                    Nothing ->
                      (model.floor, model.seed, Cmd.none)
              in
                { model |
                  seed = newSeed
                , floor = newFloor
                } ! [ cmd ]
            _ -> model ! []
        newModel =
          { model' |
            draggingContext = None
          }
      in
        newModel ! [ cmd ]
    MouseDownOnCanvas ->
      let
        (model', cmd) =
          case EquipmentNameInput.forceFinish model.equipmentNameInput of
            (equipmentNameInput, EquipmentNameInput.OnFinish id name) ->
              updateOnFinishNameInput id name { model | equipmentNameInput = equipmentNameInput }
            (equipmentNameInput, _) ->
              { model | equipmentNameInput = equipmentNameInput } ! []

        (clientX, clientY) =
          model.pos
        selectorRect =
          case model.editMode of
            Select ->
              let
                (x, y) = fitToGrid model.gridSize <|
                  screenToImageWithOffset model.scale (clientX, clientY) model.offset
              in
                Just (x, y, model.gridSize, model.gridSize)
            _ -> model.selectorRect
        draggingContext =
          case model.editMode of
            Stamp ->
              StampFromScreenPos (clientX, clientY)
            Pen ->
              PenFromScreenPos (clientX, clientY)
            Select ->
              ShiftOffsetPrevScreenPos
            Viewing ->
              ShiftOffsetPrevScreenPos

        (model'', cmd2) =
          case EquipmentNameInput.forceFinish model.equipmentNameInput of
            (equipmentNameInput, EquipmentNameInput.OnFinish id name) ->
              updateOnFinishNameInput id name { model | equipmentNameInput = equipmentNameInput }
            (equipmentNameInput, _) ->
              { model | equipmentNameInput = equipmentNameInput } ! []

        newModel =
          { model'' |
            selectedEquipments = []
          , selectorRect = selectorRect
          , contextMenu = NoContextMenu
          , draggingContext = draggingContext
          }
      in
        newModel ! [ cmd, cmd2 ]
    StartEditEquipment id ->
      case findEquipmentById (UndoRedo.data model.floor).equipments id of
        Just e ->
          { model |
            equipmentNameInput = EquipmentNameInput.start (idOf e, nameOf e) model.equipmentNameInput
          , contextMenu = NoContextMenu
          } ! [ focusCmd "name-input" ]
        Nothing ->
          model ! []
    SelectColor color ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (Floor.changeEquipmentColor model.selectedEquipments color)
          }
        cmd =
          saveFloorCmd (UndoRedo.data newModel.floor)
      in
        newModel ! [ cmd ]

    EquipmentNameInputMsg message ->
      let
        (equipmentNameInput, event) =
          EquipmentNameInput.update model.keys message model.equipmentNameInput
        model' =
          { model |
            equipmentNameInput = equipmentNameInput
          }
      in
        case event of
          EquipmentNameInput.OnInput id name ->
            model' ! [ performAPI (GotCandidateSelection id) (API.personCandidate name) ]
          EquipmentNameInput.OnFinish id name ->
            updateOnFinishNameInput id name model'
          EquipmentNameInput.OnSelectCandidate equipmentId personId ->
            case Dict.get personId model'.personInfo of
              Just person ->
                let
                  newFloor =
                    UndoRedo.commit
                    model'.floor
                    (Floor.setPerson equipmentId personId)
                  cmd =
                    saveFloorCmd (UndoRedo.data newFloor)
                  (newModel, cmd2) =
                    updateOnFinishNameInput equipmentId person.name
                      { model' |
                        floor = newFloor
                      }
                in
                  newModel ! [ cmd, cmd2 ]
              Nothing ->
                model' ! [] -- maybe never happen

          EquipmentNameInput.None ->
            model' ! []

    ShowContextMenuOnEquipment id ->
      let
        (clientX, clientY) = model.pos
        newModel =
          { model |
            contextMenu = Equipment (clientX, clientY) id
          }
      in
        newModel ! []
    SelectIsland id ->
      let
        newModel =
          case findEquipmentById (UndoRedo.data model.floor).equipments id of
            Just equipment ->
              let
                island' =
                  island
                    [equipment]
                    (List.filter (\e -> (idOf e) /= id)
                    (UndoRedo.data model.floor).equipments)
              in
                { model |
                  selectedEquipments = List.map idOf island'
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
        equipment =
          findEquipmentById (UndoRedo.data model.floor).equipments id
        model' =
          { model |
            contextMenu = NoContextMenu
          }
        newModel =
          case equipment of
            Just e ->
              let
                (_, _, w, h) = rect e
                (newId, seed) = IdGenerator.new model.seed
                newPrototypes =
                  Prototypes.register (newId, colorOf e, nameOf e, (w, h)) model.prototypes
              in
                { model' |
                  seed = seed
                , prototypes = newPrototypes
                }
            Nothing ->
              model'
      in
        newModel ! []
    FloorPropertyMsg message ->
      let
        (floorProperty, cmd1, event) =
          FloorProperty.update message model.floorProperty
        ((newFloor, newSeed), cmd2) =
          updateFloorByFloorPropertyEvent event model.seed model.floor

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
        newFloor =
          UndoRedo.commit model.floor (Floor.rotate id)
        newModel =
          { model |
            floor =  newFloor
          , contextMenu = NoContextMenu
          }
      in
        newModel ! []
    HeaderMsg action ->
      let
        (cmd, event) =
          Header.update action
        newModel =
          case event of
            LogoutDone -> { model | user = User.guest }
            Header.None -> model
      in
        newModel ! [ Cmd.map HeaderMsg cmd ]
    SearchBoxMsg msg ->
      let
        (searchBox, cmd1, event) =
          SearchBox.update msg model.searchBox

        model' =
          { model | searchBox = searchBox }



        (selectedResult, cmd2) =
          case event of
            SearchBox.OnSubmit ->
              ( Nothing
              , Navigation.modifyUrl ( URL.stringify <| URL.updateQuery model'.searchBox.query model'.url )
              )
            SearchBox.OnResults ->
              let
                results =
                  SearchBox.equipmentsInFloor (UndoRedo.data model'.floor).id model'.searchBox
              in
                case results of
                  head :: [] ->
                     (Just (idOf head), regesterPersonOfEquipment head)
                  _ -> (Nothing, Cmd.none)
            SearchBox.OnSelectResult id ->
              let
                equipments = Floor.equipments (UndoRedo.data model.floor)
                cmd =
                  case findEquipmentById equipments id of
                    Just e ->
                      regesterPersonOfEquipment e
                    Nothing ->
                      Cmd.none
              in
                (Just id, cmd)
            SearchBox.OnError e ->
              (Nothing, performAPI (always NoOp) (Task.fail e))
            SearchBox.None ->
              (model'.selectedResult, Cmd.none)

        model'' =
          { model' |
            selectedResult = selectedResult
          }

        newModel =
          case selectedResult of
            Just id -> adjustPositionByFocus id model''
            Nothing -> model''

      in
        newModel ! [ Cmd.map SearchBoxMsg cmd1, cmd2 ]

    ChangeEditing isEditing ->
      { model | editMode = if isEditing then Select else Viewing } ! []
    RegisterPeople people ->
      { model |
        personInfo =
          addAll (.id) people model.personInfo
      } ! []
    GotCandidateSelection equipmentId people ->
      let
        newModel =
          { model |
            personInfo =
              addAll (.id) people model.personInfo
          , candidates = List.map .id people
          }
      in
        newModel ! []
    UpdatePersonCandidate equipmentId personIds ->
      let
        newFloor =
          case personIds of
            head :: _ :: _ ->
              UndoRedo.commit
                model.floor
                (Floor.setPerson equipmentId head)
            _ ->
              model.floor

        newModel =
          { model |
            floor = newFloor
          }
        cmd = saveFloorCmd (UndoRedo.data newModel.floor)
      in
        newModel ! [ cmd ]
    GotDiffSource diffSource ->
      { model | diff = Just diffSource } ! []
    CloseDiff ->
      { model | diff = Nothing } ! []
    ConfirmDiff ->
      let
        floor =
          UndoRedo.data model.floor
        (cmd, newSeed, newFloor) =
          if floor.id == Nothing then
            let
              (newFloorId, newSeed) =
                IdGenerator.new model.seed
              newFloor =
                UndoRedo.commit
                  model.floor
                  (Floor.changeId newFloorId)
            in
              ( publishFloorCmd (UndoRedo.data newFloor)
              , newSeed
              , newFloor
              )
          else
            ( publishFloorCmd floor
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
    Error e ->
      let
        newModel =
          { model | error = e }
      in
        newModel ! []

noOpCmd : Task a () -> Cmd Msg
noOpCmd task =
  Task.perform (always NoOp) (always NoOp) task

updateOnFloorLoaded : Floor -> Model -> (Model, Cmd Msg)
updateOnFloorLoaded floor model =
  let
    (realWidth, realHeight) =
      Floor.realSize floor
    newModel =
      { model |
        floor = UndoRedo.init { data = floor, update = Floor.update }
      , floorProperty = FloorProperty.init floor.name realWidth realHeight
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
                  API.getPerson by `andThen` \person ->
                    Task.succeed (RegisterPeople [person])
              in
                performAPI identity task
  in
    newModel ! [ cmd ]


updateFloorByFloorPropertyEvent : FloorProperty.Event -> Seed -> UndoRedo.Model Floor Commit -> ((UndoRedo.Model Floor Commit, Seed), Cmd Msg)
updateFloorByFloorPropertyEvent event seed floor =
    case event of
      FloorProperty.None ->
        (floor, seed) ! []
      FloorProperty.OnNameChange name ->
        let
          newFloor =
            UndoRedo.commit floor (Floor.changeName name)
          cmd =
            saveFloorCmd (UndoRedo.data newFloor)
        in
          (newFloor, seed) ! [ cmd ]
      FloorProperty.OnRealSizeChange (w, h) ->
        let
          newFloor =
            UndoRedo.commit floor (Floor.changeRealSize (w, h))
          cmd =
            saveFloorCmd (UndoRedo.data newFloor)
        in
          (newFloor, seed) ! [ cmd ]
      FloorProperty.OnFileWithDataURL file dataURL ->
        let
          (id, newSeed) =
            IdGenerator.new seed
          newFloor =
            UndoRedo.commit floor (Floor.setLocalFile id file dataURL)
          cmd =
            saveFloorCmd (UndoRedo.data floor)
        in
          (newFloor, newSeed) ! [ cmd ]
      FloorProperty.OnPreparePublish ->
        let
          cmd =
            performAPI GotDiffSource (API.getDiffSource (UndoRedo.data floor).id)
        in
          (floor, seed) ! [ cmd ]
      FloorProperty.OnFileLoadFailed err ->
        let
          cmd =
            Task.perform (Error << FileError) (always NoOp) (Task.fail err)
        in
          (floor, seed) ! [ cmd ]

regesterPersonOfEquipment : Equipment -> Cmd Msg
regesterPersonOfEquipment e =
  case Equipments.relatedPerson e of
    Just personId ->
      performAPI identity <|
        API.getPerson personId `andThen` \person ->
          Task.succeed (RegisterPeople [person])
    Nothing ->
      Cmd.none

loadDraftFloor : User.User -> Cmd Msg
loadDraftFloor user =
  let
    newFloor =
      Floor.init Nothing
    loadTask =
      if User.isGuest user then
        Task.succeed Nothing
      else
        API.getDraftFloor
  in
    performAPI DraftFloorLoaded loadTask

updateOnFinishNameInput : String -> String -> Model -> (Model, Cmd Msg)
updateOnFinishNameInput id name model =
  let
    allEquipments = (UndoRedo.data model.floor).equipments
    (equipmentNameInput, cmd) =
      case findEquipmentById allEquipments id of
        Just equipment ->
          let
            island' =
              island
                [equipment]
                (List.filter (\e -> (idOf e) /= id) allEquipments)
            cmd =
              case Equipments.relatedPerson equipment of
                Just personId ->
                  Cmd.none
                Nothing ->
                  let
                    task =
                      API.personCandidate name `andThen` \people ->
                      Task.succeed (RegisterPeople people) `andThen` \_ ->
                      Task.succeed (UpdatePersonCandidate id (List.map .id people))
                  in
                    performAPI identity task
            newEquipmentNameInput =
              case EquipmentsOperation.nearest EquipmentsOperation.Down equipment island' of
                Just e ->
                  if idOf equipment == idOf e then
                    model.equipmentNameInput
                  else
                    EquipmentNameInput.start (idOf e, nameOf e) model.equipmentNameInput
                Nothing ->
                  model.equipmentNameInput
          in
            (newEquipmentNameInput, cmd)
        Nothing ->
          (model.equipmentNameInput, Cmd.none)
    selectedEquipments =
      case equipmentNameInput.editingEquipment of
        Just (id, _) ->
          [id]
        Nothing ->
          []
    newFloor =  --TODO if name really changed
      UndoRedo.commit model.floor (Floor.changeEquipmentName id name)

    cmd2 =
      saveFloorCmd (UndoRedo.data newFloor)
    newModel =
      { model |
        floor = newFloor
      , equipmentNameInput = equipmentNameInput
      , candidates = []
      , selectedEquipments = selectedEquipments
      }
  in
    newModel ! [ cmd, cmd2 ]

adjustPositionByFocus : Id -> Model -> Model
adjustPositionByFocus focused model = model


saveFloorCmd : Floor -> Cmd Msg
saveFloorCmd floor =
  let
    firstTask =
      case floor.imageSource of
        Floor.LocalFile id file url ->
          API.saveEditingImage id file
        _ ->
          Task.succeed ()
    secondTask = API.saveEditingFloor floor
  in
    performAPI
      (always (FloorSaved False))
      (firstTask `andThen` (always secondTask))


publishFloorCmd : Floor -> Cmd Msg
publishFloorCmd floor =
  let
    firstTask =
      case floor.imageSource of
        Floor.LocalFile id file url ->
          API.saveEditingImage id file
        _ ->
          Task.succeed ()
    secondTask =
      API.publishEditingFloor floor
  in
    performAPI
      (always (FloorSaved True))
      (firstTask `andThen` (always secondTask))

updateByKeyEvent : ShortCut.Event -> Model -> (Model, Cmd Msg)
updateByKeyEvent event model =
  case (model.keys.ctrl, event) of
    (True, ShortCut.A) ->
      { model |
        selectedEquipments =
          List.map idOf <| Floor.equipments (UndoRedo.data model.floor)
      } ! []
    (True, ShortCut.C) ->
      { model |
        copiedEquipments = selectedEquipments model
      } ! []
    (True, ShortCut.V) ->
      let
        base =
          case model.selectorRect of
            Just (x, y, w, h) ->
              (x, y)
            Nothing -> (0, 0) --TODO
        (copiedIdsWithNewIds, newSeed) =
          IdGenerator.zipWithNewIds model.seed model.copiedEquipments
      in
        { model |
          floor = UndoRedo.commit model.floor (Floor.paste copiedIdsWithNewIds base)
        , seed = newSeed
        , selectedEquipments = List.map snd copiedIdsWithNewIds
        , selectorRect = Nothing
        } ! []
    (True, ShortCut.X) ->
      { model |
        floor = UndoRedo.commit model.floor (Floor.delete model.selectedEquipments)
      , copiedEquipments = selectedEquipments model
      , selectedEquipments = []
      } ! []
    (True, ShortCut.Y) ->
      { model | floor = UndoRedo.redo model.floor } ! []
    (True, ShortCut.Z) ->
      { model | floor = UndoRedo.undo model.floor } ! []
    (_, ShortCut.UpArrow) ->
      shiftSelectionToward EquipmentsOperation.Up model ! []
    (_, ShortCut.DownArrow) ->
      shiftSelectionToward EquipmentsOperation.Down model ! []
    (_, ShortCut.LeftArrow) ->
      shiftSelectionToward EquipmentsOperation.Left model ! []
    (_, ShortCut.RightArrow) ->
      shiftSelectionToward EquipmentsOperation.Right model ! []
    (_, ShortCut.Del) ->
      let
        newModel =
          { model |
            floor = UndoRedo.commit model.floor (Floor.delete model.selectedEquipments)
          }
      in
        newModel ! [ saveFloorCmd (UndoRedo.data newModel.floor) ]
    (_, ShortCut.Other 9) -> --TODO waiting for fix double-click
      let
        floor = UndoRedo.data model.floor
      in
        case model.selectedEquipments of
          id :: _ ->
            case findEquipmentById floor.equipments id of
              Just e ->
                let
                  newModel =
                    { model |
                      equipmentNameInput = EquipmentNameInput.start (idOf e, nameOf e) model.equipmentNameInput
                    , contextMenu = NoContextMenu
                    }
                in
                  (newModel, focusCmd "name-input")
              Nothing ->
                model ! []
          _ ->
            model ! []
    _ ->
      model ! []


updateByMoveEquipmentEnd : Id -> (Int, Int) -> (Int, Int) -> Model -> Model
updateByMoveEquipmentEnd id (x0, y0) (x1, y1) model =
  let
    shift = Scale.screenToImageForPosition model.scale (x1 - x0, y1 - y0)
  in
    if shift /= (0, 0) then
      { model |
        floor = UndoRedo.commit model.floor (Floor.move model.selectedEquipments model.gridSize shift)
      }
    else if not model.keys.ctrl && not model.keys.shift then
      { model |
        selectedEquipments = [id]
      }
    else
      model

candidatesOf : Model -> List Person
candidatesOf model =
  List.filterMap (\personId -> Dict.get personId model.personInfo) model.candidates


shiftSelectionToward : EquipmentsOperation.Direction -> Model -> Model
shiftSelectionToward direction model =
  let
    floor = UndoRedo.data model.floor
    selected = selectedEquipments model
  in
    case selected of
      primary :: tail ->
        let
          toBeSelected =
            if model.keys.shift then
              List.map idOf <|
                expandOrShrink direction primary selected floor.equipments
            else
              case nearest direction primary floor.equipments of
                Just e ->
                  let
                    newEquipments = [e]
                  in
                    List.map idOf newEquipments
                _ -> model.selectedEquipments
        in
          { model |
            selectedEquipments = toBeSelected
          }
      _ -> model

loadAuthCmd : Cmd Msg
loadAuthCmd =
    performAPI AuthLoaded API.getAuth

loadFloorsInfoCmd : Bool -> Cmd Msg
loadFloorsInfoCmd withPrivate =
    performAPI FloorsInfoLoaded (API.getFloorsInfo withPrivate)


loadFloorCmd : Bool -> Maybe String -> Cmd Msg
loadFloorCmd forEdit floorId =
  let
    recover404 e =
      case e of
        Http.BadResponse 404 _ ->
          FloorLoaded (Floor.init floorId)
        _ ->
          Error (APIError e)
    task =
      Task.map
        FloorLoaded
        (if forEdit then API.getEditingFloor floorId else API.getFloor floorId)
  in
    Task.perform recover404 identity task


focusCmd : String -> Cmd Msg
focusCmd id =
  Task.perform (Error << HtmlError) (always NoOp) (HtmlUtil.focus id)

blurCmd : String -> Cmd Msg
blurCmd id =
  Task.perform (Error << HtmlError) (always NoOp) (HtmlUtil.blur id)

isSelected : Model -> Equipment -> Bool
isSelected model equipment =
  List.member (idOf equipment) model.selectedEquipments

primarySelectedEquipment : Model -> Maybe Equipment
primarySelectedEquipment model =
  case model.selectedEquipments of
    head :: _ ->
      findEquipmentById (equipments <| UndoRedo.data model.floor) head
    _ -> Nothing

selectedEquipments : Model -> List Equipment
selectedEquipments model =
  List.filterMap (\id ->
    findEquipmentById (UndoRedo.data model.floor).equipments id
  ) model.selectedEquipments


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
                fitToGrid model.gridSize (x2' - deskWidth // 2, y2' - deskHeight // 2)
            in
              [ ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top))
              ]
    _ -> []

temporaryPen : Model -> (Int, Int) -> Maybe (String, String, (Int, Int, Int, Int))
temporaryPen model from =
  let
    (offsetX, offsetY) = model.offset
    (left, top) =
      fitToGrid model.gridSize <|
        screenToImageWithOffset model.scale from (offsetX, offsetY)
    (right, bottom) =
      fitToGrid model.gridSize <|
        screenToImageWithOffset model.scale model.pos (offsetX, offsetY)
    width = right - left
    height = bottom - top
    color = "#fff" -- TODO
    name = ""
  in
    if width > 0 && height > 0 then
      Just (color, name, (left, top, width, height))
    else
      Nothing


--
