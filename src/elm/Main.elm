module Main exposing (..) -- where

import Html exposing (text)
import Html.App as App exposing (..)
-- import StartApp

import Model
-- import View.View as View

type alias Flags =
  { initialSize : (Int, Int)
  , initialHash : String
  , randomSeed : (Int, Int)
  }

main : Program Flags
main =
  App.programWithFlags
    { init = \flags -> Model.init flags.randomSeed flags.initialSize flags.initialHash
    , view = \model -> text "" --View.view
    , update =  Model.update
    , subscriptions = \_ -> Sub.none -- Model.subscriptions
    }
