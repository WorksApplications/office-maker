module Main exposing (..) -- where

import Html.App as App exposing (..)
import Model
import View.View as View

type alias Flags =
  { initialSize : (Int, Int)
  , initialHash : String
  , randomSeed : (Int, Int)
  , visitDate : Float
  }

main : Program Flags
main =
  App.programWithFlags
    { init = \flags -> Model.init flags.randomSeed flags.initialSize flags.initialHash flags.visitDate
    , view = View.view
    , update =  Model.update
    , subscriptions = Model.subscriptions
    }
