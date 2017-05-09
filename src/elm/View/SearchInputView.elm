module View.SearchInputView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Lazy
import Model.I18n as I18n exposing (Language)
import View.Styles as S
import Util.HtmlUtil as HtmlUtil


view : Language -> (String -> msg) -> msg -> String -> Html msg
view lang onInputMsg onSubmit query =
    HtmlUtil.form_ onSubmit
        [ style S.searchBoxContainer ]
        [ Lazy.lazy3 textInput lang onInputMsg query
        , Lazy.lazy submitButton lang
        ]


textInput : Language -> (String -> msg) -> String -> Html msg
textInput lang onInputMsg query =
    input
        [ id "search-box-input"
        , placeholder (I18n.searchPlaceHolder lang)
        , style S.searchBox
        , defaultValue query
        , HtmlUtil.onInput onInputMsg
        ]
        []


submitButton : Language -> Html msg
submitButton lang =
    input
        [ type_ "submit"
        , style S.searchBoxSubmit
        , value (I18n.search lang)
        ]
        []
