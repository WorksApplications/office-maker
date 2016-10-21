port module Page.Map.Main exposing (..)


import Navigation

import TimeTravel.Navigation as TimeTravel

import Page.Map.Update as Update exposing (Flags)
import Page.Map.View as View
import Page.Map.URL as URL exposing (URL)


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


urlParser : Navigation.Parser (Result String URL)
urlParser =
  Navigation.makeParser URL.parse
