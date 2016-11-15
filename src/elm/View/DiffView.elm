module View.DiffView exposing (view)

import Maybe
import Dict exposing (Dict)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Util.DateUtil exposing (..)

import View.Styles as Styles
import View.DialogView as DialogView

import Model.Object as Object exposing (..)
import Model.ObjectsChange as ObjectsChange
import Model.Floor as Floor exposing (Floor)
import Model.FloorDiff as FloorDiff
import Model.Person exposing (Person)
import Model.I18n as I18n exposing (Language)

type alias Options msg =
  { onClose : msg
  , onConfirm : msg
  }


view : Language -> Date -> Dict String Person -> Options msg -> (Floor, Maybe Floor) -> Html msg
view lang visitDate personInfo options (current, prev) =
  let
    header =
      headerView lang visitDate current prev

    (propertyChanges, objectsChange) =
      FloorDiff.diff current prev

    { added, modified, deleted } =
      ObjectsChange.separate objectsChange

    body =
      div [ style Styles.diffPopupBody ]
        [ propertyChangesView lang propertyChanges
        , if List.isEmpty added then text "" else h3 [] [ text ((toString (List.length added)) ++ " Additions") ]
        , if List.isEmpty added then text "" else ul [] (List.map (\new -> li [] [ text (idOf new) ] ) added)
        , if List.isEmpty modified then text "" else h3 [] [ text ((toString (List.length modified)) ++ " Modifications") ]
        , if List.isEmpty modified then text "" else ul [] (List.map (\mod -> li [] [ text (toString (List.map viewObjectPropertyChange mod.changes)) ] ) modified)
        , if List.isEmpty deleted then text "" else h3 [] [ text ((toString (List.length deleted)) ++ " Deletions") ]
        , if List.isEmpty deleted then text "" else ul [] (List.map (\old -> li [] [ text (idOf old) ] ) deleted)
        ]

  in
    popup options.onClose <|
      [ header
      , body
      , buttons lang options.onClose options.onConfirm
      ]


viewObjectPropertyChange : ObjectPropertyChange -> String
viewObjectPropertyChange change =
  case change of
    Name new old ->
      "name chaged: " ++ old ++ " -> " ++ new

    Size new old ->
      "size chaged: " ++ toString old ++ " -> " ++ toString new

    Position new old ->
      "position chaged: " ++ toString old ++ " -> " ++ toString new

    BackgroundColor new old ->
      "background color chaged: " ++ old ++ " -> " ++ new

    Color new old ->
      "color chaged: " ++ old ++ " -> " ++ new

    FontSize new old ->
      "font size chaged: " ++ toString old ++ " -> " ++ toString new

    Shape new old ->
      "shape chaged: " ++ toString old ++ " -> " ++ toString new

    Person new old ->
      "person chaged: " ++ toString old ++ " -> " ++ toString new


headerView : Language -> Date -> Floor -> Maybe Floor -> Html msg
headerView lang visitDate current prev =
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


propertyChangesView : Language -> List (String, String, String) -> Html msg
propertyChangesView lang list =
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


buttons : Language -> msg -> msg -> Html msg
buttons lang onClose onConfirm =
  let
    cancelButton =
      button
        [ onClick onClose
        , style Styles.diffPopupCancelButton ]
        [ text (I18n.cancel lang) ]

    confirmButton =
      button
        [ onClick onConfirm
        , style Styles.diffPopupConfirmButton ]
        [ text (I18n.confirm lang) ]
  in
    div [ style Styles.diffPopupFooter ] [ cancelButton, confirmButton ]


popup : msg -> List (Html msg) -> Html msg
popup onClose inner =
  DialogView.viewWithMarginParcentage onClose 100000 10 20
    [ div [ style Styles.diffPopupInnerContainer ] inner ]

--
