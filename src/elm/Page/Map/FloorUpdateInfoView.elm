module Page.Map.FloorUpdateInfoView exposing (view)

import Dict
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Lazy
import View.Styles as S
import Model.DateFormatter as DateFormatter
import Model.I18n as I18n exposing (Language)
import Model.EditingFloor as EditingFloor
import Model.Mode as Mode
import Page.Map.Model exposing (Model)


view : Model -> Html msg
view model =
    model.floor
        |> Maybe.map EditingFloor.present
        |> Maybe.andThen (\floor -> floor.update)
        |> Maybe.map
            (\{ by, at } ->
                let
                    name =
                        Dict.get by model.personInfo
                            |> Maybe.map .name
                            |> Maybe.withDefault by
                in
                    viewHelp model.lang model.visitDate name at (Mode.isPrintMode model.mode)
            )
        |> Maybe.withDefault (text "")


viewHelp : Language -> Date -> String -> Date -> Bool -> Html msg
viewHelp lang visitDate by at printMode =
    Lazy.lazy2
        viewHelpHelp
        printMode
        (I18n.lastUpdateByAt lang by (formatDate lang printMode visitDate at))


formatDate : Language -> Bool -> Date -> Date -> String
formatDate lang printMode visitDate at =
    if printMode then
        DateFormatter.formatDate lang at
    else
        DateFormatter.formatDateOrTime lang visitDate at


viewHelpHelp : Bool -> String -> Html msg
viewHelpHelp printMode string =
    div
        [ style
            (if printMode then
                S.floorPropertyLastUpdateForPrint
             else
                S.floorPropertyLastUpdate
            )
        ]
        [ text string ]
