port module Main exposing (..)

import Update exposing (Flags)
import Model.URL as URL
import View.View as View
import Navigation

import TimeTravel.Navigation as TimeTravel

port removeToken : {} -> Cmd msg

port setSelectionStart : {} -> Cmd msg

port tokenRemoved : ({} -> msg) -> Sub msg

port undo : ({} -> msg) -> Sub msg

port redo : ({} -> msg) -> Sub msg

port clipboard : (String -> msg) -> Sub msg


main : Program Flags
main =
  -- TimeTravel.programWithFlags urlParser
  Navigation.programWithFlags urlParser
    { init = Update.init
    , view = View.view
    , update = Update.update removeToken setSelectionStart
    , urlUpdate =  Update.urlUpdate
    , subscriptions = Update.subscriptions tokenRemoved undo redo clipboard
    }


urlParser : Navigation.Parser (Result String URL.Model)
urlParser =
  Navigation.makeParser URL.parse
