port module Page.Master exposing (..)

import Navigation

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Task
import Http

import API.API as API
import Component.Header as Header
import Model.I18n as I18n exposing (Language(..))
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
  { accountServiceRoot : String
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
  | UpdateHeaderState Header.Msg


init : Flags -> (Model, Cmd Msg)
init { apiRoot, accountServiceRoot, authToken, title, lang } =
  { accountServiceRoot = accountServiceRoot
  , title = title
  , error = Nothing
  , headerState = Header.init
  , lang = if lang == "ja" then JA else EN
  } ! []


update : ({} -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update removeToken message model =
  case message of
    NoOp ->
      model ! []

    UpdateHeaderState msg ->
      { model | headerState = Header.update msg model.headerState } ! []



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
