module View.MessageBar exposing(view)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as Styles

import Model.Errors exposing (GlobalError(..))
import Model.API as API
import Http

view : GlobalError -> Html msg
view e =
  case e of
    NoError ->
      noneView

    Success message ->
      successView message

    APIError e ->
      errorView (describeAPIError e)

    FileError e ->
      errorView ("Unexpected FileError: " ++ toString e)

    HtmlError e ->
      errorView ("Unexpected HtmlError: " ++ toString e)


noneView : Html msg
noneView =
  div [ style Styles.noneBar ] [ ]


successView : String -> Html msg
successView msg =
  div [ style Styles.successBar ] [ text msg ]


errorView : String -> Html msg
errorView message =
  div [ style Styles.errorBar ] [ text message ]


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
      if code == 409 then
        "Conflict: Someone has already changed. Please refresh and try again."
      else
        "Unexpected BadResponse: " ++ toString code ++ " " ++ str



--
