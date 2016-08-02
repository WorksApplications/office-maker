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

import Model.Equipment as Equipment exposing (..)
import Model.Floor as Floor
import Model.FloorDiff as FloorDiff
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

    (propertyChanges, { added, modified, deleted }) =
      FloorDiff.diff current prev

    body =
      div [ style Styles.diffPopupBody ]
        [ propertyChangesView propertyChanges
        , if List.isEmpty added then text "" else h3 [] [ text ((toString (List.length added)) ++ " Additions") ]
        , if List.isEmpty added then text "" else ul [] (List.map (\new -> li [] [ text (idOf new) ] ) added)
        , if List.isEmpty modified then text "" else h3 [] [ text ((toString (List.length modified)) ++ " Modifications") ]
        , if List.isEmpty modified then text "" else ul [] (List.map (\mod -> li [] [ text (toString mod.changes) ] ) modified)
        , if List.isEmpty deleted then text "" else h3 [] [ text ((toString (List.length deleted)) ++ " Deletions") ]
        , if List.isEmpty deleted then text "" else ul [] (List.map (\old -> li [] [ text (idOf old) ] ) deleted)
        ]

  in
    popup options.noOp options.onClose <|
      [ header
      , body
      , buttons options.onClose options.onConfirm
      ]


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
