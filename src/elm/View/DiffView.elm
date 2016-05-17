module View.DiffView exposing(..) -- where

import Maybe
import Dict
import Html exposing (..)
-- import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import View.Styles as Styles

-- import Model
import Model.Equipments as Equipments exposing (..)
import Model.Floor as Floor

type alias Floor = Floor.Model

type alias Options msg =
  { onClose : msg
  , onConfirm : msg
  }

view : Options msg -> (Floor, Maybe Floor) -> Html msg
view options (current, prev) =
  let
    newEquipments =
      Floor.equipments current
    oldEquipments =
      Maybe.withDefault [] <| Maybe.map Floor.equipments prev

    oldDict =
      List.foldl (\e dict -> Dict.insert (idOf e) e dict) Dict.empty oldEquipments

    f new (dict, add, modify) =
      case Dict.get (idOf new) dict of
        Just old ->
          (Dict.remove (idOf new) dict, add, (new, old) :: modify)
        Nothing ->
          (dict, new :: add, modify)

    (ramainingOldDict, add, modify) =
      List.foldl f (oldDict, [], []) newEquipments

    delete =
      Dict.values ramainingOldDict

  in
    popup options.onClose <|
      [ h3 [] [ text "Additions" ]
      , ul [] (List.map (\new -> li [] [ text (idOf new) ] ) add)
      , h3 [] [ text "Modifications" ]
      , ul [] (List.map (\(new, old) -> li [] [ text (idOf new) ] ) modify)
      , h3 [] [ text "Deletions" ]
      , ul [] (List.map (\old -> li [] [ text (idOf old) ] ) delete)
      , buttons options.onClose options.onConfirm
      ]

buttons : msg -> msg -> Html msg
buttons onClose onConfirm =
  let
    cancelButton =
      button
        [ onClick onClose
        , style Styles.defaultButton ]
        [ text "Cancel" ]

    confirmButton =
      button
        [ onClick onConfirm
        , style Styles.primaryButton ]
        [ text "Confirm" ]
  in
    div [ style Styles.buttons ] [ cancelButton, confirmButton ]

popup : msg -> List (Html msg) -> Html msg
popup onClose inner =
  div
    [ style Styles.modalBackground
    , onClick onClose
    ]
    [ div [ style Styles.diffPopup ] inner ]





--
