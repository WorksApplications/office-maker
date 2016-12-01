module Page.Map.FloorUpdateInfoView exposing (view)

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)

import Util.DateUtil exposing (..)

import View.Styles as S

-- import Model.User as User exposing (User)
-- import Model.Floor exposing (Floor)
import Model.I18n as I18n exposing (Language)
import Model.EditingFloor as EditingFloor
import Model.Mode as Mode

import Page.Map.Model exposing (Model)


view : Model -> Html msg
view model =
  model.floor
    |> Maybe.map EditingFloor.present
    |> Maybe.andThen (\floor -> floor.update)
    |> Maybe.map (\{ by, at } ->
        viewHelp model.lang model.visitDate by at (Mode.isPrintMode model.mode)
      )
    |> Maybe.withDefault (text "")


viewHelp : Language -> Date -> String -> Date -> Bool -> Html msg
viewHelp lang visitDate by at printMode =
  div
    [ style
      ( if printMode then
          S.floorPropertyLastUpdateForPrint
        else
          S.floorPropertyLastUpdate
      )
    ]
    [ text (I18n.lastUpdateByAt lang by (formatDateOrTime visitDate at)) ]
