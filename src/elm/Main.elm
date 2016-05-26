module Main exposing (..) -- where

import Model
import Model.URL as URL
import View.View as View
import Navigation

type alias Flags =
  { initialSize : (Int, Int)
  , randomSeed : (Int, Int)
  , visitDate : Float
  }

main : Program Flags
main =
  Navigation.programWithFlags urlParser
    { init = \flags result -> Model.init flags.randomSeed flags.initialSize result flags.visitDate
    , view = View.view
    , update =  Model.update
    , urlUpdate =  Model.urlUpdate
    , subscriptions = Model.subscriptions
    }

urlParser : Navigation.Parser (Result String URL.Model)
urlParser =
  Navigation.makeParser URL.parse
