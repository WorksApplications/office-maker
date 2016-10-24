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


type alias Popup = Bool


type Msg msg
  = NoOp
  | Open
  | Confirm msg
  | Close msg


init : Popup
init = False


update : Msg msg -> Popup -> (Popup, Cmd msg)
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


open : (Msg msg -> msg) -> msg
open f = f Open


popup : Config msg -> List (Html msg) -> Popup -> Html msg
popup config content opened =
  if opened then
    let
      footer =
        case config.strategy of
          ConfirmOrClose (confirmText, confirmMsg) (cancelText, cancelMsg) ->
            App.map config.transform <|
              div [ ]
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
            [ style S.smallPopup
            , onWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed <| config.transform NoOp)
            ]
            [ div [ style S.diffPopupInnerContainer ] content
            , footer
            ]
        ]
  else
    text ""





--
