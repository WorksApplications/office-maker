module Page.Map.SearchResultView exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Model.Object exposing (..)
import Model.Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))
import Model.Person exposing (Person)
import Model.EditMode as EditMode exposing (EditMode(..))
import Model.SearchResult exposing (SearchResult)
import Model.I18n as I18n exposing (Language)

import View.SearchResultItemView as SearchResultItemView exposing (Item(..))

import Page.Map.Model exposing (Model, ContextMenu(..), DraggingContext(..), Tab(..))
import Page.Map.Msg exposing (Msg(..))


view : (SearchResult -> Msg) -> Model -> Html Msg
view onSelectResult model =
  let
    floorsInfoDict =
      Dict.fromList <|
        List.map (\f ->
          case f of
            Public f -> (f.id, f)
            PublicWithEdit _ f -> (f.id, f)
            Private f -> (f.id, f)
          ) model.floorsInfo
  in
    case model.searchResult of
      Nothing ->
        div [ style S.searchResult ] [ text "" ]

      Just [] ->
        div [ style S.searchResult ] [ text (I18n.nothingFound model.lang) ]

      Just results ->
        let
          children =
            results
              |> List.filterMap (\result ->
                case toItemViewModel model.lang floorsInfoDict model.personInfo model.selectedResult result of
                  Just item ->
                    let
                      onSelectResultMsg =
                        onSelectResult result

                      onStartDraggingMsg =
                        if EditMode.isEditMode model.editMode then
                          Just StartDraggingFromMissingPerson
                        else
                          Nothing
                    in
                      Just <| SearchResultItemView.view onSelectResultMsg onStartDraggingMsg model.lang item

                  Nothing ->
                    Nothing
              )
        in
          ul [ style S.searchResult ] children


toItemViewModel : Language -> Dict String FloorBase -> Dict String Person -> Maybe Id -> SearchResult -> Maybe Item
toItemViewModel lang floorsInfo personInfo currentlyFocusedObjectId result =
  case (result.objectIdAndFloorId, result.personId) of
    (Just (e, fid), Just personId) ->
      case (Dict.get fid floorsInfo, Dict.get personId personInfo) of
        (Just info, Just person) ->
          Just (SearchResultItemView.Object (nameOf e) info.name (Just person.name) (Just (idOf e) == currentlyFocusedObjectId))

        _ ->
          Nothing

    (Just (e, floorId), _) ->
      case Dict.get floorId floorsInfo of
        Just info ->
          Just (SearchResultItemView.Object (nameOf e) info.name Nothing (Just (idOf e) == currentlyFocusedObjectId))

        _ ->
          Nothing

    (Nothing, Just personId) ->
      case Dict.get personId personInfo of
        Just person -> Just (SearchResultItemView.MissingPerson personId person.name)
        Nothing -> Nothing

    _ ->
      Nothing
