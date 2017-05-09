module View.DiffView exposing (view)

import Dict exposing (Dict)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import View.Styles as Styles
import View.DialogView as DialogView
import Model.DateFormatter as DateFormatter
import Model.Object as Object exposing (..)
import Model.ObjectsChange as ObjectsChange exposing (ObjectModification)
import Model.Floor as Floor exposing (Floor)
import Model.FloorDiff as FloorDiff
import Model.Person exposing (Person)
import Model.I18n as I18n exposing (Language)


type alias Options msg =
    { onClose : msg
    , onConfirm : msg
    }


view : Language -> Date -> Dict String Person -> Options msg -> ( Floor, Maybe Floor ) -> Html msg
view lang visitDate personInfo options ( current, prev ) =
    popup options.onClose <|
        [ viewHeader lang visitDate current prev
        , lazy3 viewBody lang current prev
        , lazy3 buttons lang options.onClose options.onConfirm
        ]


viewBody : Language -> Floor -> Maybe Floor -> Html msg
viewBody lang current prev =
    let
        ( propertyChanges, objectsChange ) =
            FloorDiff.diff current prev

        { added, modified, deleted } =
            ObjectsChange.separate objectsChange
    in
        div [ style Styles.diffPopupBody ]
            [ propertyChangesView lang propertyChanges
            , viewAdditions lang added
            , viewModifications lang modified
            , viewDeletions lang deleted
            ]


viewAdditions : Language -> List Object -> Html msg
viewAdditions lang added =
    if List.isEmpty added then
        text ""
    else
        div []
            [ h3 [] [ text (I18n.additions lang (List.length added)) ]
            , ul [] (List.map (\new -> li [] [ text (nameHelp lang <| nameOf new) ]) added)
            ]


viewModifications : Language -> List ObjectModification -> Html msg
viewModifications lang modified =
    if List.isEmpty modified then
        text ""
    else
        div []
            [ h3 [] [ text (I18n.modifications lang (List.length modified)) ]
            , ul [] (List.map (\mod -> li [] [ text (toString (List.map viewObjectPropertyChange mod.changes)) ]) modified)
            ]


viewDeletions : Language -> List Object -> Html msg
viewDeletions lang deleted =
    if List.isEmpty deleted then
        text ""
    else
        div []
            [ h3 [] [ text (I18n.deletions lang (List.length deleted)) ]
            , ul [] (List.map (\old -> li [] [ text (nameHelp lang <| nameOf old) ]) deleted)
            ]


nameHelp : Language -> String -> String
nameHelp lang name =
    if String.trim name == "" then
        I18n.noName lang
    else
        name


viewObjectPropertyChange : ObjectPropertyChange -> String
viewObjectPropertyChange change =
    case change of
        ChangeName new old ->
            "name chaged: " ++ old ++ " -> " ++ new

        ChangeSize new old ->
            "size chaged: " ++ toString old ++ " -> " ++ toString new

        ChangePosition new old ->
            "position chaged: " ++ toString old ++ " -> " ++ toString new

        ChangeBackgroundColor new old ->
            "background color chaged: " ++ old ++ " -> " ++ new

        ChangeColor new old ->
            "color chaged: " ++ old ++ " -> " ++ new

        ChangeFontSize new old ->
            "font size chaged: " ++ toString old ++ " -> " ++ toString new

        ChangeBold new old ->
            "bold chaged: " ++ toString old ++ " -> " ++ toString new

        ChangeUrl new old ->
            "url chaged: " ++ toString old ++ " -> " ++ toString new

        ChangeShape new old ->
            "shape chaged: " ++ toString old ++ " -> " ++ toString new

        ChangePerson new old ->
            "person chaged: " ++ toString old ++ " -> " ++ toString new


viewHeader : Language -> Date -> Floor -> Maybe Floor -> Html msg
viewHeader lang visitDate current prev =
    h2 [ style Styles.diffPopupHeader ]
        [ text
            (case prev of
                Just { update } ->
                    case update of
                        Just { by, at } ->
                            I18n.changesFromDate lang (DateFormatter.formatDateOrTime lang visitDate at)

                        Nothing ->
                            Debug.crash "this should never happen"

                Nothing ->
                    I18n.changes lang
            )
        ]


propertyChangesView : Language -> List ( String, String, String ) -> Html msg
propertyChangesView lang list =
    if List.isEmpty list then
        text ""
    else
        div []
            (h3 [] [ text "Property Changes" ]
                :: List.map propertyChangesViewEach list
            )


propertyChangesViewEach : ( String, String, String ) -> Html msg
propertyChangesViewEach ( propName, new, old ) =
    div [] [ text (propName ++ ": " ++ old ++ " => " ++ new) ]


buttons : Language -> msg -> msg -> Html msg
buttons lang onClose onConfirm =
    let
        cancelButton =
            button
                [ onClick onClose
                , style Styles.diffPopupCancelButton
                ]
                [ text (I18n.cancel lang) ]

        confirmButton =
            button
                [ onClick onConfirm
                , style Styles.diffPopupConfirmButton
                ]
                [ text (I18n.confirm lang) ]
    in
        div [ style Styles.diffPopupFooter ] [ cancelButton, confirmButton ]


popup : msg -> List (Html msg) -> Html msg
popup onClose inner =
    DialogView.viewWithMarginParcentage onClose
        100000
        10
        20
        [ div [ style Styles.diffPopupInnerContainer ] inner ]



--
