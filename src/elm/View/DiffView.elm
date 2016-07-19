module View.DiffView exposing(..)

import Maybe
import Dict exposing (Dict)
import Date exposing (Date)
import Html exposing (..)
import Json.Decode as Decode
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
  , noOp : msg
  }

view : Date -> Dict String Person -> Options msg -> (Floor, Maybe Floor) -> Html msg
view visitDate personInfo options (current, prev) =
  let
    header =
      h2 [ style Styles.diffPopupHeader ]
        [ text
            ( case prev of
              Just { update } ->
                case update of
                  Just { by , at } ->
                    "Changes from " ++ formatDateOrTime visitDate at
                  Nothing ->
                    Debug.crash "this should never happen"
              Nothing ->
                "Changes"
            )
        ]

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

    body =
      div [ style Styles.diffPopupBody ]
        [ propertyChangesView (propertyChanges current prev)
        , if List.isEmpty add then text "" else h3 [] [ text ((toString (List.length add)) ++ " Additions") ]
        , if List.isEmpty add then text "" else ul [] (List.map (\new -> li [] [ text (idOf new) ] ) add)
        , if List.isEmpty modify then text "" else h3 [] [ text ((toString (List.length modify)) ++ " Modifications") ]
        , if List.isEmpty modify then text "" else ul [] (List.map (\d -> li [] [ text (toString d) ] ) modify)
        , if List.isEmpty delete then text "" else h3 [] [ text ((toString (List.length delete)) ++ " Deletions") ]
        , if List.isEmpty delete then text "" else ul [] (List.map (\old -> li [] [ text (idOf old) ] ) delete)
        ]

  in
    popup options.noOp options.onClose <|
      [ header
      , body
      , buttons options.onClose options.onConfirm
      ]


propertyChanges : Floor -> Maybe Floor -> List (String, String, String)
propertyChanges current prev =
  case prev of
    Just prev ->
      let
        nameChange =
          if Floor.name current == Floor.name prev then
            []
          else
            [("Name", Floor.name current, Floor.name prev)]
        ordChange =
          if current.ord == prev.ord then
            []
          else
            [("Order", toString current.ord, toString prev.ord)]
        sizeChange =
          if current.realSize == prev.realSize then
            []
          else case (current.realSize, prev.realSize) of
            (Just (w1, h1), Just (w2, h2)) ->
              [("Size", "(" ++ toString w1 ++ ", " ++ toString h1 ++ ")", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")")]
            (Just (w1, h1), Nothing) ->
              [("Size", "(" ++ toString w1 ++ ", " ++ toString h1 ++ ")", "")]
            (Nothing, Just (w2, h2)) ->
              [("Size", "", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")")]
            _ ->
              [] -- should not happen
        imageChange =
          if current.imageSource /= prev.imageSource then
            [("Image", "", "")] -- TODO how to describe?
          else
            []
      in
        nameChange ++ ordChange ++ sizeChange
    Nothing ->
      (if Floor.name current /= "" then [ ("Name", Floor.name current, "") ] else []) ++
      (case current.realSize of
        Just (w2, h2) ->
          [("Size", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")", "")]
        Nothing -> []
      )


propertyChangesView : List (String, String, String) -> Html msg
propertyChangesView list =
  if List.isEmpty list then
    text ""
  else
    div []
      ( h3 [] [ text "Property Changes"] ::
        List.map propertyChangesViewEach list
      )


propertyChangesViewEach : (String, String, String) -> Html msg
propertyChangesViewEach (propName, new, old) =
  div [] [ text (propName ++ ": " ++ old ++ " => " ++ new)]


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
        , style Styles.diffPopupCancelButton ]
        [ text "Cancel" ]

    confirmButton =
      button
        [ onClick onConfirm
        , style Styles.diffPopupConfirmButton ]
        [ text "Confirm" ]
  in
    div [ style Styles.diffPopupFooter ] [ cancelButton, confirmButton ]

popup : msg -> msg -> List (Html msg) -> Html msg
popup noOp onClose inner =
  div
    [ style Styles.modalBackground
    , onClick onClose
    ]
    [ div
        [ style Styles.diffPopup
        , onWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed noOp)
        ]
        [ div [ style Styles.diffPopupInnerContainer ] inner ]
    ]





--
