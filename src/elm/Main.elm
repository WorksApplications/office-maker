port module Main exposing (..)

import Model
import Model.URL as URL
import View.View as View
import Navigation

import TimeTravel.Navigation as TimeTravel

type alias Flags =
  { apiRoot : String
  , accountServiceRoot : String
  , authToken : String
  , title : String
  , initialSize : (Int, Int)
  , randomSeed : (Int, Int)
  , visitDate : Float
  }


port removeToken : {} -> Cmd msg

port setSelectionStart : {} -> Cmd msg

port tokenRemoved : ({} -> msg) -> Sub msg

port undo : ({} -> msg) -> Sub msg

port redo : ({} -> msg) -> Sub msg

port clipboard : (String -> msg) -> Sub msg


main : Program Flags
main =
  TimeTravel.programWithFlags urlParser
  -- Navigation.programWithFlags urlParser
    { init = \flags result ->
        Model.init
          flags.apiRoot
          flags.accountServiceRoot
          flags.authToken
          flags.title
          flags.randomSeed
          flags.initialSize
          flags.visitDate
          result
    , view = View.view
    , update = Model.update removeToken setSelectionStart
    , urlUpdate =  Model.urlUpdate
    , subscriptions = Model.subscriptions tokenRemoved undo redo clipboard
    }


urlParser : Navigation.Parser (Result String URL.Model)
urlParser =
  Navigation.makeParser URL.parse
