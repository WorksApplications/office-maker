module View.SearchInputView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model.I18n as I18n exposing (Language)

import View.Styles as S

import Util.HtmlUtil as HtmlUtil

view : Language -> (String -> msg) -> msg -> String -> Html msg
view lang onInputMsg onSubmit query =
  HtmlUtil.form_ onSubmit
    [ style S.searchBoxContainer ]
    [ input
        [ type_ "input"
        , placeholder (I18n.search lang)
        , style S.searchBox
        , defaultValue query
        , HtmlUtil.onInput onInputMsg
        ]
        []
    , input
        [ type_ "submit"
        , style S.searchBoxSubmit
        , value "Search"
        ]
        []
    ]
