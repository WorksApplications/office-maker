module Component.FloorDeleter exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import InlineHover exposing (hover)
import Util.HtmlUtil as HtmlUtil
import Model.I18n as I18n exposing (Language)
import Model.User as User exposing (User)
import Model.Floor exposing (Floor)
import Component.Dialog as Dialog exposing (Dialog)
import View.Styles as S


type Msg
    = SelectDeleteFloor
    | DialogMsg (Dialog.Msg Msg)
    | DeleteFloor Floor Bool


type alias Config msg =
    { onDeleteFloor : Floor -> Cmd msg
    }


type alias FloorDeleter =
    { dialog : Dialog
    }


init : FloorDeleter
init =
    { dialog = Dialog.init
    }


update : (Msg -> msg) -> Config msg -> Msg -> FloorDeleter -> ( FloorDeleter, Cmd msg )
update transform config message model =
    case message of
        SelectDeleteFloor ->
            ( model, Dialog.open DialogMsg |> Cmd.map transform )

        DialogMsg msg ->
            let
                ( dialog, cmd ) =
                    Dialog.update msg model.dialog
            in
                ( { model
                    | dialog = dialog
                  }
                , cmd |> Cmd.map transform
                )

        DeleteFloor floor ok ->
            ( model
            , if ok then
                config.onDeleteFloor floor
              else
                Cmd.none
            )


button : Language -> User -> Floor -> Html Msg
button lang user floor =
    if User.isAdmin user && Dict.isEmpty floor.objects then
        hover S.deleteFloorButtonHover
            Html.button
            [ HtmlUtil.onClick_ SelectDeleteFloor
            , style S.deleteFloorButton
            ]
            [ text (I18n.deleteFloor lang)
            ]
    else
        text ""


dialog : Floor -> FloorDeleter -> Html Msg
dialog floor model =
    Dialog.view
        { strategy =
            Dialog.ConfirmOrClose
                ( "delete", DeleteFloor floor True )
                ( "cancel", DeleteFloor floor False )
        , transform = DialogMsg
        }
        "delete this floor?"
        model.dialog
