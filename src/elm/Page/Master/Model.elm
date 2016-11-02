module Page.Master.Model exposing (..)

import Time exposing (second)
import Task
import Http
import Navigation

import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.User as User exposing (User)
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (..)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import API.API as API
import API.Cache as Cache exposing (Cache, UserState)

import Debounce exposing (Debounce)


type alias Model =
  { apiConfig : API.Config
  , title : String
  , colorPalette : ColorPalette
  , prototypes : List Prototype
  , error : Maybe String
  , headerState : Header.State
  , lang : Language
  , saveColorDebounce : Debounce ColorPalette
  }
