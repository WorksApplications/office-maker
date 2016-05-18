module View.DiffView exposing(..) -- where

import Maybe
import Dict exposing (Dict)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Util.DateUtil exposing (..)

import View.Styles as Styles

import Model.Equipments as Equipments exposing (..)
import Model.Floor as Floor
import Model.Person exposing (Person)

type alias Floor = Floor.Model

type alias Options msg =
  { onClose : msg
  , onConfirm : msg
  }

view : Date -> Dict String Person -> Options msg -> (Floor, Maybe Floor) -> Html msg
view visitDate personInfo options (current, prev) =
  let
    header =
      case prev of
        Just { update } ->
          case update of
            Just { by , at } ->
              h2 [] [ text ("Changes from " ++ formatDateOrTime visitDate at) ]
            Nothing ->
              Debug.crash "this should never happen"
        Nothing ->
          h2 [] [ text "Changes"]

    newEquipments =
      Floor.equipments current
    oldEquipments =
      Maybe.withDefault [] <| Maybe.map Floor.equipments prev

    oldDict =
      List.foldl (\e dict -> Dict.insert (idOf e) e dict) Dict.empty oldEquipments

    f new (dict, add, modify) =
      case Dict.get (idOf new) dict of
        Just old ->
          ( Dict.remove (idOf new) dict, add,
            case diffEquipment new old of
              [] -> modify
              list -> list :: modify
          )
        Nothing ->
          (dict, new :: add, modify)

    (ramainingOldDict, add, modify) =
      List.foldl f (oldDict, [], []) newEquipments

    delete =
      Dict.values ramainingOldDict

  in
    popup options.onClose <|
      [ header
      , if List.isEmpty add then text "" else h3 [] [ text ((toString (List.length add)) ++ " Additions") ]
      , if List.isEmpty add then text "" else ul [] (List.map (\new -> li [] [ text (idOf new) ] ) add)
      , if List.isEmpty modify then text "" else h3 [] [ text ((toString (List.length modify)) ++ " Modifications") ]
      , if List.isEmpty modify then text "" else ul [] (List.map (\d -> li [] [ text (toString d) ] ) modify)
      , if List.isEmpty delete then text "" else h3 [] [ text ((toString (List.length delete)) ++ " Deletions") ]
      , if List.isEmpty delete then text "" else ul [] (List.map (\old -> li [] [ text (idOf old) ] ) delete)
      , buttons options.onClose options.onConfirm
      ]

diffEquipment : Equipment -> Equipment -> List String
diffEquipment new old =
  let
    a =
      if nameOf new /= nameOf old then
        Just ("name chaged: " ++ nameOf old ++ " -> " ++ nameOf new)
      else
        Nothing
    b =
      if rect new /= rect old then
        Just ("position/size chaged: " ++ toString (rect old) ++ " -> " ++ toString (rect new))
      else
        Nothing
    c =
      if colorOf new /= colorOf old then
        Just ("color chaged: " ++ colorOf old ++ " -> " ++ colorOf new)
      else
        Nothing
  in
    List.filterMap identity [a, b, c]




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
