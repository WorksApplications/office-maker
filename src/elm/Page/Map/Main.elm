port module Page.Map.Main exposing (..)

import Navigation

-- import TimeTravel.Navigation as TimeTravel

import Page.Map.Model exposing (Model)
import Page.Map.Update as Update exposing (Flags)
import Page.Map.View as View
import Page.Map.Msg exposing (Msg)


port removeToken : {} -> Cmd msg

port setSelectionStart : {} -> Cmd msg

port tokenRemoved : ({} -> msg) -> Sub msg

port undo : ({} -> msg) -> Sub msg

port redo : ({} -> msg) -> Sub msg

port clipboard : (String -> msg) -> Sub msg


main : Program Flags Model Msg
main =
  -- TimeTravel.programWithFlags urlParser
  Navigation.programWithFlags Update.parseURL
    { init = Update.init
    , view = View.view
    , update = Update.update removeToken setSelectionStart
    , subscriptions = Update.subscriptions tokenRemoved undo redo clipboard
    }
