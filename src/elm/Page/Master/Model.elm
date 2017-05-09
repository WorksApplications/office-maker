module Page.Master.Model exposing (..)

import Debounce exposing (Debounce)
import Component.Header as Header
import Model.User as User exposing (User)
import Model.I18n as I18n exposing (Language(..))
import Model.Prototype exposing (Prototype)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import API.API as API
import Page.Master.PrototypeForm exposing (PrototypeForm)


type alias Model =
    { apiConfig : API.Config
    , title : String
    , allAdmins : List User
    , colorPalette : ColorPalette
    , prototypes : List PrototypeForm
    , error : Maybe String
    , header : Header.Model
    , lang : Language
    , saveColorDebounce : Debounce ColorPalette
    , savePrototypeDebounce : Debounce Prototype
    }
