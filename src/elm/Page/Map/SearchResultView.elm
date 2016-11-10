module Page.Map.SearchResultView exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import InlineHover exposing (hover)

import Model.Object as Object exposing (..)
import Model.Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))
import Model.Person exposing (Person)
import Model.EditMode as EditMode exposing (EditMode(..))
import Model.SearchResult as SearchResult exposing (SearchResult)
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n exposing (Language)

import View.SearchResultItemView as SearchResultItemView exposing (Item(..))
import View.Styles as S

import Page.Map.Model exposing (Model, ContextMenu(..), DraggingContext(..), Tab(..))
import Page.Map.Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
  case model.searchResult of
    Nothing ->
      div
        [ style S.searchResult ]
        [ text "" ]

    Just [] ->
      div
        [ style S.searchResult ]
        [ text (I18n.nothingFound model.lang) ]

    Just results ->
      let
        grouped =
          SearchResult.groupByPostAndReorder
            (Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor)
            model.personInfo
            results
      in
        div
          [ style S.searchResult ]
          ( List.map (viewListForOnePost model) grouped )


viewListForOnePost : Model -> (Maybe String, List SearchResult) -> Html Msg
viewListForOnePost model (maybePostName, results) =
  let
    floorsInfoDict =
      Dict.fromList <|
        List.map (\f ->
          case f of
            Public f -> (f.id, f)
            PublicWithEdit _ f -> (f.id, f)
            Private f -> (f.id, f)
          ) model.floorsInfo

    children =
      results
        |> List.filterMap (\result ->
          case toItemViewModel model.lang floorsInfoDict model.personInfo model.selectedResult result of
            Just item ->
              let
                thisFloorId =
                  model.floor
                    |> Maybe.map (\floor -> (EditingFloor.present floor).id )

                onSelectResultMsg =
                  SelectSearchResult result

                onStartDraggingMsg =
                  if EditMode.isEditMode model.editMode then
                    Just StartDraggingFromMissingPerson
                  else
                    Nothing

                onStartDraggingExistingObjectMsg =
                  if EditMode.isEditMode model.editMode then
                    Just StartDraggingFromExistingObject
                  else
                    Nothing
              in
                Just <|
                  SearchResultItemView.view
                    thisFloorId
                    onSelectResultMsg
                    onStartDraggingMsg
                    onStartDraggingExistingObjectMsg
                    model.lang
                    item

            Nothing ->
              Nothing
        )

    groupHeader =
      case maybePostName of
        Just name ->
          hover
            S.searchResultGroupHeaderHover
            div
            [ style S.searchResultGroupHeader
            , onClick (SearchByPost name)
            ]
            [ text name ]

        Nothing ->
          div [ style S.searchResultGroupHeader ] [ text "No Post" ]
  in
    div [ style S.searchResultGroup ]
      [ groupHeader
      , div [] children
      ]


toItemViewModel : Language -> Dict String FloorBase -> Dict String Person -> Maybe Id -> SearchResult -> Maybe Item
toItemViewModel lang floorsInfo personInfo currentlyFocusedObjectId result =
  case result of
    SearchResult.Object object floorId ->
      case Dict.get floorId floorsInfo of
        Just info ->
          let
            objectIsFocused =
              Just (idOf object) == currentlyFocusedObjectId

            maybePersonName =
              Object.relatedPerson object
                |> (flip Maybe.andThen) (\personId -> Dict.get personId personInfo)
                |> (flip Maybe.andThen) (\person -> Just person.name)
          in
            Just <|
              SearchResultItemView.Object
                (idOf object)
                (nameOf object)
                floorId
                info.name
                maybePersonName
                objectIsFocused

        _ ->
          Nothing

    SearchResult.MissingPerson personId ->
      case Dict.get personId personInfo of
        Just person -> Just (SearchResultItemView.MissingPerson personId person.name)
        Nothing -> Nothing
