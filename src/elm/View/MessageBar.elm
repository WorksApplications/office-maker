module View.MessageBar exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import View.Styles as Styles


none : Html msg
none =
    div [ style Styles.noneBar ] []


success : String -> Html msg
success msg =
    div [ style Styles.successBar ] [ text msg ]


error : String -> Html msg
error message =
    div [ class "message-bar-error", style Styles.errorBar ] [ text message ]
