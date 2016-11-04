module Page.Master.Model exposing (..)

import Debounce exposing (Debounce)

import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.Object exposing (Shape)
import Model.Prototype exposing (Prototype)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import API.API as API

import Page.Master.PrototypeForm exposing (PrototypeForm)


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
