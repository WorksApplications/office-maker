module View.MessageBarForMainView exposing(view)

import Http
import Html exposing (..)

import View.MessageBar as MessageBar

import Model.I18n as I18n exposing (Language)
import Model.Errors exposing (GlobalError(..))

import API.API as API


view : Language -> GlobalError -> Html msg
view lang e =
  case e of
    NoError ->
      MessageBar.none

    Success message ->
      MessageBar.success message

    APIError e ->
      MessageBar.error (describeAPIError lang e)

    FileError e ->
      MessageBar.error (I18n.unexpectedFileError lang ++ ": " ++ toString e)

    HtmlError e ->
      MessageBar.error (I18n.unexpectedHtmlError lang ++ ": " ++ toString e)

    PasteError s ->
      MessageBar.error s


describeAPIError : Language -> API.Error -> String
describeAPIError lang e =
  case e of
    Http.Timeout ->
      I18n.timeout lang

    Http.NetworkError ->
      I18n.networkErrorDetectedPleaseRefreshAndTryAgain lang

    Http.UnexpectedPayload str ->
      I18n.unexpectedPayload lang ++ ": " ++ str

    Http.BadResponse code str ->
      if code == 409 then
        I18n.conflictSomeoneHasAlreadyChangedPleaseRefreshAndTryAgain lang
      else
        I18n.unexpectedBadResponse lang ++ ": " ++ toString code ++ " " ++ str


--
