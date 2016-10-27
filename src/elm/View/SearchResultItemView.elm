module View.SearchResultItemView exposing (Item(..), view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Model.I18n as I18n exposing (Language)

import View.Icons as Icons
import View.Styles as S


type alias PostName = String
type alias ObjectName = String
type alias PersonId = String
type alias PersonName = String
type alias FloorName = String

-- View Model

type Item
  = Post PostName
  | Object ObjectName FloorName (Maybe PersonName) Bool
  | MissingPerson PersonId PersonName


view : msg -> Maybe (PersonId -> PersonName -> msg) -> Language -> Item -> Html msg
view onSelect onStartDrag lang item =
  case item of
    Post postName ->
      wrapForNonDrag onSelect <|
      itemViewCommon True False postIcon <|
        div [] [ text postName ]

    Object _ floorName (Just personName) focused ->
      wrapForNonDrag onSelect <|
      itemViewCommon True focused personIcon <|
        div [] [ text (personName ++ "(" ++ floorName ++ ")") ]

    Object objectName floorName Nothing focused ->
      wrapForNonDrag onSelect <|
      itemViewCommon True focused noIcon <|
        div [] [ text (objectName ++ "(" ++ floorName ++ ")") ]

    MissingPerson personId personName ->
      let
        wrap =
          case onStartDrag of
            Just onStartDrag ->
              wrapForDrag (onStartDrag personId personName)

            Nothing ->
              identity
      in
        wrap <|
        itemViewCommon False False personIcon <|
          div [] [ text (personName ++ "(" ++ I18n.missing lang ++ ")") ]


wrapForNonDrag : msg -> Html msg -> Html msg
wrapForNonDrag onSelect child =
  div
    [ onClick onSelect
    , style (S.searchResultItem False)
    ]
    [ child ]


wrapForDrag : msg -> Html msg -> Html msg
wrapForDrag onStartDrag child =
  div
    [ onMouseDown onStartDrag
    , style (S.searchResultItem True)
    ]
    [ child ]


itemViewCommon : Bool -> Bool -> Html msg -> Html msg -> Html msg
itemViewCommon selectable focused icon label =
  div
    [ style (S.searchResultItemInner selectable focused) ]
    [ icon, label ]


personIcon : Html msg
personIcon =
  div [ style S.searchResultItemIcon ] [ Icons.searchResultItemPerson ]


postIcon : Html msg
postIcon =
  div [ style S.searchResultItemIcon ] [ Icons.searchResultItemPost ]


noIcon : Html msg
noIcon =
  div [ style S.searchResultItemIcon ] []

--
