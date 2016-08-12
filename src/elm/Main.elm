module Main exposing (..)

import Model
import Model.URL as URL
import View.View as View
import Navigation

import TimeTravel.Navigation as TimeTravel

type alias Flags =
  { apiRoot : String
  , title : String
  , initialSize : (Int, Int)
  , randomSeed : (Int, Int)
  , visitDate : Float
  }


main : Program Flags
main =
  -- TimeTravel.programWithFlags urlParser
  Navigation.programWithFlags urlParser
    { init = \flags result -> Model.init flags.apiRoot flags.title flags.randomSeed flags.initialSize result flags.visitDate
    , view = View.view
    , update =  Model.update
    , urlUpdate =  Model.urlUpdate
    , subscriptions = Model.subscriptions
    }


urlParser : Navigation.Parser (Result String URL.Model)
urlParser =
  Navigation.makeParser URL.parse
