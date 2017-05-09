module Page.Map.FloorsInfoView exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ContextMenu
import CoreType exposing (..)
import View.CommonStyles as CommonStyles
import View.Styles as Styles
import Model.User as User exposing (User)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))
import Page.Map.Msg exposing (Msg(..))
import Page.Map.ContextMenuContext as ContextMenuContext


view : Bool -> User -> Bool -> Maybe String -> Dict FloorId FloorInfo -> Html Msg
view disableContextmenu user isEditMode currentFloorId floorsInfo =
    if isEditMode then
        viewEditingFloors disableContextmenu user currentFloorId floorsInfo
    else
        viewPublicFloors currentFloorId floorsInfo


viewEditingFloors : Bool -> User -> Maybe FloorId -> Dict FloorId FloorInfo -> Html Msg
viewEditingFloors disableContextmenu user currentFloorId floorsInfo =
    let
        contextMenuMsg floor =
            if not disableContextmenu && not (User.isGuest user) then
                Just (ContextMenu.open ContextMenuMsg (ContextMenuContext.FloorInfoContextMenu floor.id))
            else
                Nothing

        floorList =
            floorsInfo
                |> FloorInfo.toValues
                |> List.map (\floorInfo -> ( FloorInfo.isNeverPublished floorInfo, FloorInfo.editingFloor floorInfo ))
                |> List.sortBy (Tuple.second >> .ord)
                |> List.map
                    (\( isNeverPublished, floor ) ->
                        eachView
                            (contextMenuMsg floor)
                            (GoToFloor floor.id True)
                            (currentFloorId == Just floor.id)
                            (if floor.temporary then
                                Temporary
                             else if isNeverPublished then
                                Private
                             else
                                Public
                            )
                            floor.name
                    )

        create =
            if User.isAdmin user then
                [ createButton ]
            else
                []
    in
        wrapList (floorList ++ create)


viewPublicFloors : Maybe FloorId -> Dict FloorId FloorInfo -> Html Msg
viewPublicFloors currentFloorId floorsInfo =
    floorsInfo
        |> FloorInfo.toPublicList
        |> List.map
            (\floor ->
                eachView
                    Nothing
                    (GoToFloor floor.id False)
                    (currentFloorId == Just floor.id)
                    Public
                    floor.name
            )
        |> wrapList


wrapList : List (Html msg) -> Html msg
wrapList children =
    ul [ style floorsInfoViewStyle ] children


eachView : Maybe (Attribute msg) -> msg -> Bool -> ColorType -> String -> Html msg
eachView maybeOpenContextMenu onClickMsg selected colorType floorName =
    li
        (style (floorsInfoViewItemStyle selected colorType)
            :: onClick onClickMsg
            :: (maybeOpenContextMenu |> Maybe.map (List.singleton) |> Maybe.withDefault [])
        )
        [ span [ style floorsInfoViewItemLinkStyle ] [ text floorName ] ]


createButton : Html Msg
createButton =
    li
        [ style (floorsInfoViewItemStyle False Public)
        , onClick CreateNewFloor
        ]
        [ span [ style floorsInfoViewItemLinkStyle ] [ text "+" ] ]


type alias Styles =
    List ( String, String )


floorsInfoViewStyle : Styles
floorsInfoViewStyle =
    [ ( "position", "absolute" )
    , ( "width", "calc(100% - 300px)" )
    , ( "z-index", Styles.zFloorInfo )
    ]


type ColorType
    = Public
    | Private
    | Temporary


floorsInfoViewItemStyle : Bool -> ColorType -> Styles
floorsInfoViewItemStyle selected colorType =
    [ ( "background-color"
      , case colorType of
            Public ->
                "#fff"

            Private ->
                "#dbdbdb"

            Temporary ->
                "#dbdbaa"
      )
    , ( "border-right"
      , if selected then
            "solid 2px " ++ CommonStyles.selectColor
        else
            "solid 1px #d0d0d0"
      )
    , ( "border-bottom"
      , if selected then
            "solid 2px " ++ CommonStyles.selectColor
        else
            "solid 1px #d0d0d0"
      )
    , ( "border-top"
      , if selected then
            "solid 2px " ++ CommonStyles.selectColor
        else
            "none"
      )
    , ( "border-left"
      , if selected then
            "solid 2px " ++ CommonStyles.selectColor
        else
            "none"
      )
    , ( "min-width", "72px" )
    , ( "box-sizing", "border-box" )
    , ( "height", "30px" )
    , ( "position", "relative" )
    , ( "font-size", "12px" )
    , ( "float", "left" )
    , ( "cursor", "pointer" )
    ]


floorsInfoViewItemLinkStyle : Styles
floorsInfoViewItemLinkStyle =
    [ ( "display", "block" )
    , ( "text-align", "center" )
    , ( "vertical-align", "middle" )
    , ( "line-height", "30px" )
    , ( "padding", "0 8px" )
    ]
