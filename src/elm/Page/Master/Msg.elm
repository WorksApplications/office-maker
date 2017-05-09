module Page.Master.Msg exposing (..)

import Http
import Debounce exposing (Debounce)
import API.Cache as Cache exposing (Cache, UserState)
import Component.Header as Header
import Model.User as User exposing (User)
import Model.Prototype exposing (Prototype)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import Page.Master.PrototypeForm exposing (PrototypeForm)


type Msg
    = NoOp
    | Loaded UserState User ColorPalette (List Prototype) (List User)
    | HeaderMsg Header.Msg
    | AddColor Bool
    | DeleteColor Bool Int
    | InputColor Bool Int String
    | UpdatePrototype Int PrototypeForm
    | SaveColorDebounceMsg Debounce.Msg
    | SavePrototypeDebounceMsg Debounce.Msg
    | NotAuthorized
    | APIError Http.Error
