module View.SearchResultItemView exposing (Item(..), view)

import Dict exposing (Dict)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Model.Object exposing (..)
import Model.Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))
import Model.Person exposing (Person)
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


view : Maybe (PersonId -> msg) -> Language -> Item -> Html msg
view onStartDrag lang item =
  case item of
    Post postName ->
      itemViewCommon True False postIcon <|
        div [] [ text postName ]

    Object _ floorName (Just personName) focused ->
      itemViewCommon True focused personIcon <|
        div [] [ text (personName ++ "(" ++ floorName ++ ")") ]

    Object objectName floorName Nothing focused ->
      itemViewCommon True focused noIcon <|
        div [] [ text (objectName ++ "(" ++ floorName ++ ")") ]

    MissingPerson personId personName ->
      itemViewCommon False False personIcon <|
        div
          ( case onStartDrag of
              Just onStartDrag ->
                [ onMouseDown (onStartDrag personId) ]

              Nothing ->
                []
          )
          [ text (personName ++ "(" ++ I18n.missing lang ++ ")") ]


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
