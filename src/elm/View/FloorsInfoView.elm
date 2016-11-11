module View.FloorsInfoView exposing(view)

import String
import Json.Decode as Decode

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.Styles as Styles

import Model.User as User exposing (User)
import Model.Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo(..))

import Util.HtmlUtil exposing (..)

import InlineHover exposing (hover)


linkBox : Maybe msg -> msg -> List (String, String) -> List (String, String) -> List (String, String) -> List (Html msg) -> Html msg
linkBox contextmenuMsg clickMsg liStyle hoverStyle innerStyle inner =
  hover hoverStyle
  li
    ( style liStyle ::
      onClick clickMsg ::
      ( case contextmenuMsg of
          Just msg ->
            [ onWithOptions "contextmenu" { stopPropagation = True, preventDefault = True } (Decode.succeed msg) ]

          Nothing ->
            []
      )
    )
    [ span [ style innerStyle ] inner ]


eachView : (String -> msg) -> (String -> msg) -> Bool -> User -> Bool -> Maybe String -> FloorInfo -> Maybe (Html msg)
eachView contextmenuMsg onClickMsg disableContextmenu user isEditMode currentFloorId floorInfo =
  Maybe.map
    (\floor ->
      eachView'
        (if not disableContextmenu && (not (User.isGuest user)) && isEditMode then Just (contextmenuMsg floor.id) else Nothing)
        (onClickMsg floor.id)
        (currentFloorId == Just floor.id)
        (markAsPrivate floorInfo)
        (markAsModified isEditMode floorInfo)
        floor
    )
    (getFloor isEditMode floorInfo)


eachView' : Maybe msg -> msg -> Bool -> Bool -> Bool -> FloorBase -> Html msg
eachView' contextmenuMsg onClickMsg selected markAsPrivate markAsModified floor =
  linkBox
    contextmenuMsg
    onClickMsg
    (Styles.floorsInfoViewItem selected markAsPrivate)
    (Styles.floorsInfoViewItemHover markAsPrivate)
    Styles.floorsInfoViewItemLink
    [ text (floor.name ++ (if markAsModified then "*" else ""))
    ]


createButton : msg -> Html msg
createButton msg =
  linkBox
    Nothing
    msg
    (Styles.floorsInfoViewItem False False)
    (Styles.floorsInfoViewItemHover False)
    Styles.floorsInfoViewItemLink
    [ text "+" ]


view : (String -> msg) -> ((Int, Int) -> msg) -> (Maybe (String, Bool) -> msg) -> msg -> Bool -> User -> Bool -> Maybe String -> List FloorInfo -> Html msg
view onContextMenu onMove onClickMsg onCreateNewFloor disableContextmenu user isEditMode currentFloorId floorInfoList =
  let
    requestPrivate =
      (not (User.isGuest user)) && isEditMode

    onClickMsg_ floorId =
      if String.length floorId > 0 then
        onClickMsg (Just (floorId, requestPrivate))
      else
        onClickMsg Nothing

    floorList =
      List.filterMap
        (eachView onContextMenu onClickMsg_ disableContextmenu user isEditMode currentFloorId)
        (List.sortBy (getOrd isEditMode) floorInfoList)

    create =
      if isEditMode && User.isAdmin user then
        [ createButton onCreateNewFloor ]
      else
        []
  in
    ul
      [ style Styles.floorsInfoView
      , onMouseMove' onMove
      ]
      ( floorList ++ create )


getOrd : Bool -> FloorInfo -> Int
getOrd isEditMode info =
  case info of
    Public floor ->
      floor.ord

    PublicWithEdit lastPublicFloor currentPrivateFloor ->
      if isEditMode then currentPrivateFloor.ord else lastPublicFloor.ord

    Private floor ->
      if isEditMode then floor.ord else -1


getFloor : Bool -> FloorInfo -> Maybe FloorBase
getFloor isEditMode info =
  case info of
    Public floor ->
      Just floor

    PublicWithEdit lastPublicFloor currentPrivateFloor ->
      if isEditMode then Just currentPrivateFloor else Just lastPublicFloor

    Private floor ->
      if isEditMode then Just floor else Nothing


markAsPrivate : FloorInfo -> Bool
markAsPrivate floorInfo =
  case floorInfo of
    Public _ -> False
    PublicWithEdit _ _ -> False
    Private _ -> True


markAsModified : Bool -> FloorInfo -> Bool
markAsModified isEditMode floorInfo =
  case floorInfo of
    Public _ -> False
    PublicWithEdit _ _ -> if isEditMode then True else False
    Private _ -> False
