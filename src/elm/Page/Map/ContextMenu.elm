module Page.Map.ContextMenu exposing (view)

import Maybe
import Dict
import Html exposing (..)

import View.ContextMenu as ContextMenu
import Model.Object as Object
import Model.ObjectsOperation as ObjectsOperation
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
        selectSamePostOption =
          ObjectsOperation.findObjectById (Model.getEditingFloorOrDummy model).objects id `Maybe.andThen` \obj ->
          Object.relatedPerson obj `Maybe.andThen` \personId ->
            let
              str =
                -- case Dict.get personId model.personInfo of
                --   Just person ->
                --     "Select " ++ person.post
                --
                --   Nothing ->
                    (I18n.selectSamePost model.lang)
            in
              Just [ (SelectSamePost personId, str) ]

        forOneDesk =
          if [id] == model.selectedObjects then
            (Maybe.withDefault [] selectSamePostOption) ++
            [ (SelectIsland id, I18n.selectIsland model.lang)
            , (SelectSameColor id, I18n.selectSameColor model.lang)
            , (RegisterPrototype id, I18n.registerAsStamp model.lang)
            , (Rotate id, I18n.rotate model.lang)
            ]
          else
            []

        common =
          [ (FirstNameOnly model.selectedObjects, I18n.pickupFirstWord model.lang)
          , (RemoveSpaces model.selectedObjects, I18n.removeSpaces model.lang)
          ]

        items =
          forOneDesk ++ common
      in
        ContextMenu.view items model.windowSize (x, y)

    FloorInfo (x, y) id ->
      let
        items =
          [(CopyFloor id, I18n.copyFloor model.lang)]
      in
        ContextMenu.view items model.windowSize (x, y)
