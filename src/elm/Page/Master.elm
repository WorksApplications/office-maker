port module Page.Master exposing (..)

import Navigation

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Task
import Http

import API.API as API
import API.Cache as Cache exposing (Cache, UserState)
import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.User as User exposing (User)
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (..)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import View.Styles as Styles

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
  , error : Maybe String
  , headerState : Header.State
  , lang : Language
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
    , error = Nothing
    , headerState = Header.init
    , lang = if flags.lang == "ja" then JA else EN
    } ! [ initCmd apiConfig defaultUserState ]


initCmd : API.Config -> UserState -> Cmd Msg
initCmd apiConfig defaultUserState =
  performAPI
    identity
    ( Cache.getWithDefault Cache.cache defaultUserState `Task.andThen` \userState ->
      API.getAuth apiConfig `Task.andThen` \user ->
        if User.isGuest user then
          Task.succeed NotAuthorized
        else
          API.getColors apiConfig `Task.andThen` \colors ->
          API.getPrototypes apiConfig `Task.andThen` \prototypes ->
          Task.succeed (Loaded userState user colors prototypes)
    )


performAPI : (a -> Msg) -> Task.Task API.Error a -> Cmd Msg
performAPI tagger task =
  Task.perform APIError tagger task


update : ({} -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update removeToken message model =
  case message of
    NoOp ->
      model ! []

    Loaded userState user colors prototypes ->
      model ! [] -- TODO

    UpdateHeaderState msg ->
      { model | headerState = Header.update msg model.headerState } ! []

    NotAuthorized ->
      model ! [ Task.perform (always NoOp) (always NoOp) API.goToLogin ]

    APIError e ->
      { model | error = Just (toString e) } ! []


view : Model -> Html Msg
view model =
  div
    []
    [ Header.view
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
    ]
