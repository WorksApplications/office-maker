module View.MessageBar exposing(view)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as Styles

import Model.I18n as I18n exposing (Language)
import Model.Errors exposing (GlobalError(..))
import API.API as API
import Http


view : Language -> GlobalError -> Html msg
view lang e =
  case e of
    NoError ->
      noneView

    Success message ->
      successView message

    APIError e ->
      errorView (describeAPIError lang e)

    FileError e ->
      errorView (I18n.unexpectedFileError lang ++ ": " ++ toString e)

    HtmlError e ->
      errorView (I18n.unexpectedHtmlError lang ++ ": " ++ toString e)

    PasteError s ->
      errorView s


noneView : Html msg
noneView =
  div [ style Styles.noneBar ] [ ]


successView : String -> Html msg
successView msg =
  div [ style Styles.successBar ] [ text msg ]


errorView : String -> Html msg
errorView message =
  div [ class "message-bar-error", style Styles.errorBar ] [ text message ]


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
