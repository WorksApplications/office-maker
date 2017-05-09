module Page.Map.SearchResultItemView exposing (Item(..), view)

import Time exposing (Time)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import CoreType exposing (..)
import Model.I18n as I18n exposing (Language)
import View.Icons as Icons
import View.Styles as S


type alias PostName =
    String


type alias ObjectName =
    String


type alias PersonName =
    String


type alias FloorName =
    String



-- VIEW MODEL


type Item
    = Post PostName
    | Object ObjectId ObjectName FloorId FloorName (Maybe ( PersonId, PersonName )) Time Bool
    | MissingPerson PersonId PersonName


view : Maybe FloorId -> msg -> Maybe (PersonId -> PersonName -> msg) -> Maybe (ObjectId -> String -> Maybe PersonId -> FloorId -> Time -> msg) -> Language -> Item -> Html msg
view currentFloorId onSelect onStartDragMissing onStartDragExisting lang item =
    case item of
        Post postName ->
            wrapForNonDrag <|
                itemViewCommon postIcon <|
                    div [] [ itemViewLabel (Just onSelect) False postName ]

        Object objectId _ floorId floorName (Just ( personId, personName )) updateAt focused ->
            let
                wrap =
                    case onStartDragExisting of
                        Just onStartDragExisting ->
                            if currentFloorId == Just floorId then
                                identity
                            else
                                wrapForDrag (onStartDragExisting objectId personName (Just personId) floorId updateAt)

                        Nothing ->
                            identity
            in
                wrap <|
                    itemViewCommon personIcon <|
                        div [] [ itemViewLabel (Just onSelect) focused (personName ++ "(" ++ floorName ++ ")") ]

        Object objectId objectName floorId floorName Nothing updateAt focused ->
            let
                wrap =
                    case onStartDragExisting of
                        Just onStartDragExisting ->
                            wrapForDrag (onStartDragExisting objectId objectName Nothing floorId updateAt)

                        Nothing ->
                            identity
            in
                wrap <|
                    itemViewCommon noIcon <|
                        div [] [ itemViewLabel (Just onSelect) focused (objectName ++ "(" ++ floorName ++ ")") ]

        MissingPerson personId personName ->
            let
                wrap =
                    case onStartDragMissing of
                        Just onStartDragMissing ->
                            wrapForDrag (onStartDragMissing personId personName)

                        Nothing ->
                            identity
            in
                wrap <|
                    itemViewCommon personIcon <|
                        div [] [ itemViewLabel Nothing False (personName ++ "(" ++ I18n.missing lang ++ ")") ]


wrapForNonDrag : Html msg -> Html msg
wrapForNonDrag child =
    div
        [ style (S.searchResultItem False)
        ]
        [ child ]


wrapForDrag : msg -> Html msg -> Html msg
wrapForDrag onStartDrag child =
    div
        [ onMouseDown onStartDrag
        , style (S.searchResultItem True)
        ]
        [ child ]


itemViewCommon : Html msg -> Html msg -> Html msg
itemViewCommon icon label =
    div
        [ style S.searchResultItemInner ]
        [ icon, label ]


itemViewLabel : Maybe msg -> Bool -> String -> Html msg
itemViewLabel onSelect focused s =
    let
        selectable =
            onSelect /= Nothing

        events =
            case onSelect of
                Just onSelect ->
                    [ onClick onSelect ]

                Nothing ->
                    []
    in
        span
            (events ++ [ style (S.searchResultItemInnerLabel selectable focused) ])
            [ text s ]


personIcon : Html msg
personIcon =
    div [ style S.searchResultItemIcon ] [ Icons.searchResultItemPerson ]


postIcon : Html msg
postIcon =
    div [ style S.searchResultItemIcon ] [ Icons.searchResultItemPost ]


noIcon : Html msg
noIcon =
    div [ style S.searchResultItemIcon ] []
