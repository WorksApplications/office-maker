module View.DiffView exposing(..) -- where

import Maybe

import Html exposing (..)
-- import Html.App
import Html.Attributes exposing (..)
-- import Html.Events exposing (..)

-- import View.Styles as Styles

import Model
import Model.Floor

type alias Floor = Model.Floor.Model

view : Floor -> Maybe Floor -> Html Model.Msg
view current prev =
  text ""

--
