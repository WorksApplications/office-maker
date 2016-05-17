module View.ErrorView exposing(..) -- where

import Maybe

import Html exposing (..)
-- import Html.App
import Html.Attributes exposing (..)
-- import Html.Events exposing (..)

import View.Styles as Styles

import Model
import Model.API as API
import Http

view : Maybe Model.Error -> Html Model.Msg
view error =
  case error of
    Nothing ->
      text ""
    Just e ->
      let
        description =
          case e of
            Model.APIError e ->
              describeAPIError e
            Model.FileError e ->
              "Unexpected FileError: " ++ toString e
            Model.HtmlError e ->
              "Unexpected HtmlError: " ++ toString e
      in
        div [ style Styles.error ] [ text description ]

describeAPIError : API.Error -> String
describeAPIError e =
  case e of
    Http.Timeout ->
      "Timeout"
    Http.NetworkError ->
      "NetworkError detected. Please refresh and try again."
    Http.UnexpectedPayload str ->
      "UnexpectedPayload: " ++ str
    Http.BadResponse code str ->
      "Unexpected BadResponse: " ++ toString code ++ " " ++ str



--
