module Page.Map.ContextMenu exposing (view)

import Maybe
import Dict
import Html exposing (..)

import View.ContextMenu as ContextMenu
import Model.Object as Object
import Model.ObjectsOperation as ObjectsOperation
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n

import Page.Map.Msg exposing (..)
import Page.Map.Model as Model exposing (Model, ContextMenu(..), DraggingContext(..), Tab(..))

view : Model -> Html Msg
view model =
  case model.contextMenu of
    NoContextMenu ->
      text ""

    Object (x, y) id ->
      let
        itemsForPerson =
          model.floor `Maybe.andThen` \eFloor ->
          ObjectsOperation.findObjectById (EditingFloor.present eFloor).objects id `Maybe.andThen` \obj ->
          Object.relatedPerson obj `Maybe.andThen` \personId ->
          Dict.get personId model.personInfo `Maybe.andThen` \person ->
            Just <|
            [ (SelectSamePost person.post, I18n.selectSamePost model.lang, Just person.post)
            , (SearchByPost person.post, I18n.searchSamePost model.lang, Just person.post)
            ]

        forOneDesk =
          if [id] == model.selectedObjects then
            (Maybe.withDefault [] itemsForPerson) ++
            [ (SelectIsland id, I18n.selectIsland model.lang, Nothing)
            , (SelectSameColor id, I18n.selectSameColor model.lang, Nothing)
            , (RegisterPrototype id, I18n.registerAsStamp model.lang, Nothing)
            , (Rotate id, I18n.rotate model.lang, Nothing)
            ]
          else
            []

        common =
          [ (FirstNameOnly model.selectedObjects, I18n.pickupFirstWord model.lang, Nothing)
          , (RemoveSpaces model.selectedObjects, I18n.removeSpaces model.lang, Nothing)
          ]

        items =
          forOneDesk ++ common
      in
        ContextMenu.view items model.windowSize (x, y)

    FloorInfo (x, y) floorId ->
      if Maybe.map (\efloor -> (EditingFloor.present efloor).id) model.floor == Just floorId then
        let
          items =
            [ (CopyFloor floorId False, I18n.copyFloor model.lang, Nothing)
            -- , (CopyFloor floorId True, I18n.copyFloorWithEmptyDesks model.lang, Nothing)
            ]
        in
          ContextMenu.view items model.windowSize (x, y)
      else
        text ""
