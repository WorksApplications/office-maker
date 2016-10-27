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
              annotation =
                Maybe.map (.post) (Dict.get personId model.personInfo)
            in
              Just [ (SelectSamePost personId, I18n.selectSamePost model.lang, annotation) ]

        forOneDesk =
          if [id] == model.selectedObjects then
            (Maybe.withDefault [] selectSamePostOption) ++
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

    FloorInfo (x, y) id ->
      let
        items =
          [(CopyFloor id, I18n.copyFloor model.lang, Nothing)]
      in
        ContextMenu.view items model.windowSize (x, y)
