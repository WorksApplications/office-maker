module Component.Dialog exposing (..)

import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.DialogView as DialogView
import View.CommonStyles as S


type alias Config msg =
    { strategy : Strategy msg
    , transform : Msg msg -> msg
    }


type Strategy msg
    = ConfirmOrClose ( String, msg ) ( String, msg )


type alias Dialog =
    Bool


type Msg msg
    = Open
    | Confirm msg
    | Close msg


init : Dialog
init =
    False


update : Msg msg -> Dialog -> ( Dialog, Cmd msg )
update msg model =
    case msg of
        Open ->
            True ! []

        Close msg ->
            False ! [ Task.perform identity <| Task.succeed msg ]

        Confirm msg ->
            False ! [ Task.perform identity <| Task.succeed msg ]


open : (Msg msg -> msg) -> Cmd msg
open f =
    Task.perform identity (Task.succeed (f Open))


view : Config msg -> String -> Dialog -> Html msg
view config content opened =
    if opened then
        let
            footer =
                case config.strategy of
                    ConfirmOrClose ( confirmText, confirmMsg ) ( cancelText, cancelMsg ) ->
                        Html.map config.transform <|
                            div [ style S.dialogFooter ]
                                [ button [ style S.defaultButton, onClick (Close cancelMsg) ] [ text cancelText ]
                                , button [ style S.primaryButton, onClick (Confirm confirmMsg) ] [ text confirmText ]
                                ]

            clickBackgroundMsg =
                config.transform <|
                    case config.strategy of
                        ConfirmOrClose _ ( cancelText, cancelMsg ) ->
                            Close cancelMsg
        in
            DialogView.viewWithSize clickBackgroundMsg
                100000
                300
                150
                [ div [] [ text content ]
                , footer
                ]
    else
        text ""



--
