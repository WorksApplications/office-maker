module Component.Dialog exposing (..)

import Task
import Json.Decode as Decode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App

import View.Styles as S
import View.CommonStyles as CS


type alias Config msg =
  { strategy : Strategy msg
  , transform : Msg msg -> msg
  }


type Strategy msg =
  ConfirmOrClose (String, msg) (String, msg)


type alias Dialog = Bool


type Msg msg
  = NoOp
  | Open
  | Confirm msg
  | Close msg


init : Dialog
init = False


update : Msg msg -> Dialog -> (Dialog, Cmd msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    Open ->
      True ! []

    Close msg ->
      False ! [ Task.perform identity identity <| Task.succeed msg ]

    Confirm msg ->
      False ! [ Task.perform identity identity <| Task.succeed msg ]


open : (Msg msg -> msg) -> Cmd msg
open f =
  Task.perform identity identity (Task.succeed (f Open))


view : Config msg -> String -> Dialog -> Html msg
view config content opened =
  if opened then
    let
      footer =
        case config.strategy of
          ConfirmOrClose (confirmText, confirmMsg) (cancelText, cancelMsg) ->
            App.map config.transform <|
              div [ style CS.dialogFooter ]
                [ button [ style CS.defaultButton, onClick (Close cancelMsg) ] [ text cancelText ]
                , button [ style CS.primaryButton, onClick (Confirm confirmMsg) ] [ text confirmText ]
                ]
    in
      div
        [ style S.modalBackground
        , onClick (config.transform <|
            case config.strategy of
              ConfirmOrClose _ (cancelText, cancelMsg) ->
                Close cancelMsg
          )
        ]
        [ div
            [ style CS.dialog
            , onWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed <| config.transform NoOp)
            ]
            [ div [] [ text content ]
            , footer
            ]
        ]
  else
    text ""





--
