module Page.Master.Msg exposing (..)

import Http

import Debounce exposing (Debounce)

import API.Cache as Cache exposing (Cache, UserState)
import Component.Header as Header
import Model.User as User exposing (User)
import Model.Prototype exposing (Prototype)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)


type Msg
  = NoOp
  | Loaded UserState User ColorPalette (List Prototype)
  | UpdateHeaderState Header.Msg
  | InputColor Bool Int String
  | SaveColorDebounceMsg Debounce.Msg
  | NotAuthorized
  | APIError Http.Error
