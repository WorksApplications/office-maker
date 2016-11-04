module Page.Master.Model exposing (..)

import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.Prototype exposing (Prototype)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import API.API as API

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
  , savePrototypeDebounce : Debounce (List Prototype)
  }
