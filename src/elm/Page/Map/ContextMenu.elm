module Page.Map.ContextMenu exposing (view)

import Dict
import Html exposing (..)
import ContextMenu
import Model.User as User
import Model.Object as Object
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n
import Model.Floor as Floor
import Page.Map.Msg exposing (..)
import Page.Map.Model as Model exposing (Model, DraggingContext(..))
import Page.Map.ContextMenuContext exposing (..)


view : Model -> Html Msg
view model =
    ContextMenu.view
        ContextMenu.defaultConfig
        ContextMenuMsg
        (toItemGroups model)
        model.contextMenu


toItemGroups : Model -> ContextMenuContext -> List (List ( ContextMenu.Item, Msg ))
toItemGroups model context =
    case context of
        ObjectContextMenu id ->
            let
                itemsForPerson =
                    model.floor
                        |> Maybe.andThen
                            (\eFloor ->
                                Floor.getObject id (EditingFloor.present eFloor)
                                    |> Maybe.andThen
                                        (\obj ->
                                            Object.relatedPerson obj
                                                |> Maybe.andThen
                                                    (\personId ->
                                                        Dict.get personId model.personInfo
                                                            |> Maybe.map
                                                                (\person ->
                                                                    [ ( ContextMenu.itemWithAnnotation (I18n.selectSamePost model.lang) person.post, SelectSamePost person.post )
                                                                    , ( ContextMenu.itemWithAnnotation (I18n.searchSamePost model.lang) person.post, SearchByPost person.post )
                                                                    ]
                                                                )
                                                    )
                                        )
                            )

                forOneDesk =
                    if [ id ] == model.selectedObjects then
                        (Maybe.withDefault [] itemsForPerson)
                            ++ [ ( ContextMenu.item (I18n.selectIsland model.lang), SelectIsland id )
                               , ( ContextMenu.item (I18n.selectSameColor model.lang), SelectSameColor id )
                               , ( ContextMenu.item (I18n.registerAsStamp model.lang), RegisterPrototype id )
                               ]
                    else
                        []

                common =
                    [ ( ContextMenu.item (I18n.pickupFirstWord model.lang), FirstNameOnly model.selectedObjects )
                    , ( ContextMenu.item (I18n.removeSpaces model.lang), RemoveSpaces model.selectedObjects )
                    , ( ContextMenu.item (I18n.rotate model.lang), RotateObjects model.selectedObjects )
                    ]

                items =
                    forOneDesk ++ common
            in
                [ items ]

        FloorInfoContextMenu floorId ->
            if Maybe.map (EditingFloor.present >> .id) model.floor == Just floorId then
                if User.isGuest model.user then
                    []
                else if User.isAdmin model.user then
                    [ [ ( ContextMenu.item (I18n.copyFloor model.lang), CopyFloor floorId False )
                      , ( ContextMenu.item (I18n.copyAndCreateTemporaryFloor model.lang), CopyFloor floorId True )
                      ]
                    ]
                else
                    [ [ ( ContextMenu.item (I18n.copyAndCreateTemporaryFloor model.lang), CopyFloor floorId True )
                      ]
                    ]
            else
                []
