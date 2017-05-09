module Page.Map.SearchResultView exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Model.Object as Object exposing (..)
import Model.Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))
import Model.Person exposing (Person)
import Model.Mode as Mode exposing (Mode(..))
import Model.SearchResult as SearchResult exposing (SearchResult)
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n exposing (Language)
import View.Icons as I
import View.Styles as S
import CoreType exposing (..)
import Page.Map.Model as Model exposing (Model, DraggingContext(..))
import Page.Map.Msg exposing (Msg(..))
import Page.Map.SearchResultItemView as SearchResultItemView exposing (Item(..))


type alias Id =
    String


view : Model -> List (Html Msg)
view model =
    case model.searchResult of
        Nothing ->
            loading

        Just [] ->
            wrap [ text (I18n.nothingFound model.lang) ]

        Just results ->
            let
                grouped =
                    SearchResult.groupByPostAndReorder
                        (Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor)
                        model.personInfo
                        results
            in
                wrap (List.map (viewListForOnePost model) grouped)


loading : List (Html Msg)
loading =
    wrap [ text "Loading..." ]


wrap : List (Html Msg) -> List (Html Msg)
wrap children =
    [ closeButton
    , div [ style S.searchResult ] children
    ]


closeButton : Html Msg
closeButton =
    div
        [ style S.searchResultClose
        , onClick CloseSearchResult
        ]
        [ I.searchResultClose
        , text "Close"
        ]


viewListForOnePost : Model -> ( Maybe String, List SearchResult ) -> Html Msg
viewListForOnePost model ( maybePostName, results ) =
    let
        floorsInfo =
            model.floorsInfo
                |> FloorInfo.toPublicList
                |> List.map (\floor -> ( floor.id, floor ))
                |> Dict.fromList

        thisFloorId =
            model.floor
                |> Maybe.map (\floor -> (EditingFloor.present floor).id)

        onStartDraggingMsg =
            if Mode.isEditMode model.mode then
                Just StartDraggingFromMissingPerson
            else
                Nothing

        onStartDraggingExistingObjectMsg =
            if Mode.isEditMode model.mode then
                Just StartDraggingFromExistingObject
            else
                Nothing

        children =
            results
                |> List.filterMap
                    (\result ->
                        toItemViewModel model.lang floorsInfo model.personInfo model.selectedResult result
                            |> Maybe.map
                                (\item ->
                                    let
                                        onSelectResultMsg =
                                            case result of
                                                SearchResult.Object object floorId ->
                                                    SelectSearchResult (Object.idOf object) floorId (SearchResult.getPersonId result)

                                                _ ->
                                                    NoOp
                                    in
                                        SearchResultItemView.view
                                            thisFloorId
                                            onSelectResultMsg
                                            onStartDraggingMsg
                                            onStartDraggingExistingObjectMsg
                                            model.lang
                                            item
                                )
                    )
    in
        div
            [ style S.searchResultGroup ]
            [ Lazy.lazy2 groupHeader model.lang maybePostName
            , div [] children
            ]


groupHeader : Language -> Maybe String -> Html Msg
groupHeader lang maybePostName =
    case maybePostName of
        Just name ->
            Lazy.lazy2 groupHeaderHelp lang name

        Nothing ->
            Lazy.lazy groupHeaderNoPost lang


groupHeaderHelp : Language -> String -> Html Msg
groupHeaderHelp lang name =
    div
        [ style S.searchResultGroupHeader
        , onClick (SearchByPost name)
        ]
        [ text name ]


groupHeaderNoPost : Language -> Html Msg
groupHeaderNoPost lang =
    div [ style S.searchResultGroupHeader ] [ text "No Post" ]


toItemViewModel : Language -> Dict FloorId FloorBase -> Dict PersonId Person -> Maybe Id -> SearchResult -> Maybe Item
toItemViewModel lang floorsInfo personInfo currentlyFocusedObjectId result =
    case result of
        SearchResult.Object object floorId ->
            case ( Dict.get floorId floorsInfo, Object.updateAtOf object ) of
                ( Just info, Just updateAt ) ->
                    let
                        objectIsFocused =
                            Just (Object.idOf object) == currentlyFocusedObjectId

                        maybePersonIdAndName =
                            Object.relatedPerson object
                                |> Maybe.andThen (\personId -> Dict.get personId personInfo)
                                |> Maybe.andThen (\person -> Just ( person.id, person.name ))
                    in
                        Just <|
                            SearchResultItemView.Object
                                (Object.idOf object)
                                (Object.nameOf object)
                                floorId
                                info.name
                                maybePersonIdAndName
                                updateAt
                                objectIsFocused

                _ ->
                    Nothing

        SearchResult.MissingPerson personId ->
            case Dict.get personId personInfo of
                Just person ->
                    Just (SearchResultItemView.MissingPerson personId person.name)

                Nothing ->
                    Nothing
