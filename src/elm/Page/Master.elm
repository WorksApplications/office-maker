port module Page.Master exposing (..)

import Time exposing (second)
import Task
import Http
import Navigation

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import API.API as API
import API.Cache as Cache exposing (Cache, UserState)
import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.User as User exposing (User)
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (..)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import View.Common exposing (..)
import View.Styles as Styles

import Debounce exposing (Debounce)


port removeToken : {} -> Cmd msg

port tokenRemoved : ({} -> msg) -> Sub msg


main : Program Flags
main =
  App.programWithFlags
    { init = init
    , view = view
    , update = update removeToken
    , subscriptions = \_ -> Sub.none
    }


--------


type alias Model =
  { apiConfig : API.Config
  , title : String
  , colors : List String
  , error : Maybe String
  , headerState : Header.State
  , lang : Language
  , saveColorDebounce : Debounce (List String)
  }


----

type alias Flags =
  { apiRoot : String
  , accountServiceRoot : String
  , authToken : String
  , title : String
  , lang : String
  }

----

type Msg
  = NoOp
  | Loaded UserState User ColorPalette (List Prototype)
  | UpdateHeaderState Header.Msg
  | InputColor Int String
  | SaveColorDebounceMsg Debounce.Msg
  | NotAuthorized
  | APIError Http.Error


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    apiConfig =
      { apiRoot = flags.apiRoot
      , accountServiceRoot = flags.accountServiceRoot
      , token = flags.authToken
      }

    defaultUserState =
      Cache.defaultUserState (if flags.lang == "ja" then JA else EN)
  in
    { apiConfig = apiConfig
    , title = flags.title
    , colors = ["#afd", "#456", "#f49"]
    , error = Nothing
    , headerState = Header.init
    , lang = defaultUserState.lang
    , saveColorDebounce = Debounce.init
    } ! [ initCmd apiConfig defaultUserState ]


initCmd : API.Config -> UserState -> Cmd Msg
initCmd apiConfig defaultUserState =
  performAPI
    identity
    ( Cache.getWithDefault Cache.cache defaultUserState `Task.andThen` \userState ->
      API.getAuth apiConfig `Task.andThen` \user ->
        -- if User.isGuest user then
        --   Task.succeed NotAuthorized
        -- else
          API.getColors apiConfig `Task.andThen` \colors ->
          API.getPrototypes apiConfig `Task.andThen` \prototypes ->
          Task.succeed (Loaded userState user colors prototypes)
    )


performAPI : (a -> Msg) -> Task.Task API.Error a -> Cmd Msg
performAPI tagger task =
  Task.perform APIError tagger task


saveColorDebounceConfig : Debounce.Config Msg
saveColorDebounceConfig =
  { strategy = Debounce.later (1 * second)
  , transform = SaveColorDebounceMsg
  }


update : ({} -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update removeToken message model =
  case message of
    NoOp ->
      model ! []

    Loaded userState user colors prototypes ->
      model ! [] -- TODO

    UpdateHeaderState msg ->
      { model | headerState = Header.update msg model.headerState } ! []

    InputColor index color ->
      let
        colors =
          setColor index color model.colors

        (saveColorDebounce, cmd) =
          Debounce.push
            saveColorDebounceConfig
            colors
            model.saveColorDebounce
      in
        { model
        | colors = colors
        , saveColorDebounce = saveColorDebounce
        } ! [ cmd ]

    SaveColorDebounceMsg msg ->
      let
        (saveColorDebounce, cmd) =
          Debounce.update
            saveColorDebounceConfig
            (Debounce.takeLast saveColors)
            msg
            model.saveColorDebounce
      in
        { model | saveColorDebounce = saveColorDebounce } ! [ cmd ]

    NotAuthorized ->
      model ! [ Task.perform (always NoOp) (always NoOp) API.goToLogin ]

    APIError e ->
      { model | error = Just (toString e) } ! []


setColor : Int -> String -> List String -> List String
setColor index color list =
  case list of
    head :: tail ->
      if index == 0 then
        color :: tail
      else
        head :: setColor (index - 1) color tail

    [] ->
      list


saveColors : List String -> Cmd Msg
saveColors colors = Cmd.none -- TODO


view : Model -> Html Msg
view model =
  div
    []
    [ headerView model
    , card <| colorMasterView model
    ]


headerView : Model -> Html Msg
headerView model =
  Header.view
    { onSignInClicked = NoOp
    , onSignOutClicked = NoOp
    , onToggleEditing = NoOp
    , onTogglePrintView = NoOp
    , onSelectLang = \_ -> NoOp
    , onUpdate = UpdateHeaderState
    , title = model.title
    , lang = EN
    , user = Nothing
    , editing = False
    , printMode = False
    }
    model.headerState


colorMasterView : Model -> List (Html Msg)
colorMasterView model =
  List.indexedMap row model.colors


row : Int -> String -> Html Msg
row index color =
  div [ style [("height", "30px"), ("display", "flex")] ]
    [ colorSample color
    , input [ onInput (InputColor index), value color ] []
    ]


colorSample : String -> Html Msg
colorSample color =
  div [ style [("background-color", color), ("width", "30px")] ] [ ]
