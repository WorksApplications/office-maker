module View.View exposing (view)

import Dict exposing (..)
import Maybe

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)

import SearchBox
import Header
import View.Styles as S
import View.Icons as Icons
import View.MessageBar as MessageBar
import View.FloorsInfoView as FloorsInfoView
import View.DiffView as DiffView
import View.CanvasView as CanvasView
import View.PropertyView as PropertyView
import View.ContextMenu as ContextMenu
import View.Common exposing (..)
import View.PrototypePreviewView as PrototypePreviewView
import FloorProperty

import Util.HtmlUtil exposing (..)

import Update exposing (..)
import Model.Model exposing (..)
import Model.Floor exposing (Floor)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Object as Object exposing (..)
import Model.Prototypes as Prototypes exposing (StampCandidate)
import Model.User as User
import Model.Person exposing (Person)
import Model.SearchResult exposing (SearchResult)
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n exposing (Language)

mainView : Model -> Html Msg
mainView model =
  let
    (_, windowHeight) = model.windowSize

    sub =
      if model.editMode == Viewing True then
        text ""
      else
        subView model

    floorInfo =
      floorInfoView model
  in
    main' [ style (S.mainView windowHeight) ]
      [ floorInfo
      , MessageBar.view model.lang model.error
      , CanvasView.view model
      , sub
      ]


floorInfoView : Model -> Html Msg
floorInfoView model =
  case model.editMode of
    Viewing True ->
      text ""

    _ ->
      let
        isEditMode =
          model.editMode /= Viewing True && model.editMode /= Viewing False

      in
        FloorsInfoView.view
          ShowContextMenuOnFloorInfo
          MoveOnCanvas
          GoToFloor
          CreateNewFloor
          model.keys.ctrl
          model.user
          isEditMode
          (EditingFloor.present model.floor).id
          model.floorsInfo


subView : Model -> Html Msg
subView model =
  let
    floorIdIsNotSet =
      (EditingFloor.present model.floor).id == ""

    pane =
      if model.tab == SearchTab || floorIdIsNotSet then
        subViewForSearch model
      else
        subViewForEdit model

    tabs =
      if floorIdIsNotSet then
        []
      else
        case (model.editMode, User.isGuest model.user) of
          (Viewing _, _) -> []
          (_, True) -> []
          (_, _) ->
            [ subViewTab (ChangeTab SearchTab) 0 Icons.searchTab (model.tab == SearchTab)
            , subViewTab (ChangeTab EditTab) 1 Icons.editTab (model.tab == EditTab)
            ]
  in
    div
      [ style (S.subView)
      ]
      (pane ++ tabs)


subViewForEdit : Model -> List (Html Msg)
subViewForEdit model =
  let
    floorView =
      List.map
        (App.map FloorPropertyMsg)
        (if (EditingFloor.present model.floor).id == "" then
          []
        else
          FloorProperty.view
            model.lang
            model.visitDate
            model.user
            (EditingFloor.present model.floor)
            model.floorProperty
        )
  in
    [ card <| penView model
    , card <| PropertyView.view model
    , card <| floorView
    ]


subViewForSearch : Model -> List (Html Msg)
subViewForSearch model =
  let
    searchWithPrivate =
      not <| User.isGuest model.user

    floorsInfoDict =
      Dict.fromList <|
        List.map (\f ->
          case f of
            FloorInfo.Public f -> (f.id, f)
            FloorInfo.PublicWithEdit _ f -> (f.id, f)
            FloorInfo.Private f -> (f.id, f)
          ) model.floorsInfo

    format =
      formatSearchResult model.lang floorsInfoDict model.personInfo model.selectedResult

    isEditing =
      (model.editMode /= Viewing True && model.editMode /= Viewing False)

  in
    [ card <| [ SearchBox.view SearchBoxMsg model.searchBox ]
    , card <| [ SearchBox.resultsView model.lang SearchBoxMsg isEditing format model.searchBox ]
    ]


formatSearchResult : Language -> Dict String Floor -> Dict String Person -> Maybe Id -> SearchResult -> Html Msg
formatSearchResult lang floorsInfo personInfo selectedResult = \result ->
  let
    { personId, objectIdAndFloorId } = result

    floorName =
      case objectIdAndFloorId of
        Just (e, fid) ->
          case Dict.get fid floorsInfo of
            Just info ->
              info.name

            Nothing ->
              "?"

        Nothing ->
          I18n.missing lang

    isPerson =
      personId /= Nothing

    icon =
      div
        [ style S.searchResultItemIcon
        ]
        [ if isPerson then Icons.searchResultItemPerson else text "" ]

    nameOfObject =
      case objectIdAndFloorId of
        Just (e, fid) -> nameOf e
        Nothing -> ""

    name =
      case personId of
        Just id ->
          case Dict.get id personInfo of
            Just person -> person.name
            Nothing -> nameOfObject

        Nothing -> nameOfObject

    selectable =
      objectIdAndFloorId /= Nothing

    selected =
      case (selectedResult, objectIdAndFloorId) of
        (Just id, Just (e, _)) ->
          idOf e == id
        _ ->
          False
  in
    div
      [ style <| S.searchResultItemInner selectable selected
      ]
      [ icon, div [] [text (name ++ "(" ++ floorName ++ ")")] ]


subViewTab : msg -> Int -> Html msg -> Bool -> Html msg
subViewTab msg index icon active =
  div
    [ style (S.subViewTab index active)
    , onClick msg
    ]
    [ icon ]


penView : Model -> List (Html Msg)
penView model =
  let
    prototypes =
      Prototypes.prototypes model.prototypes

    stampMode =
      (model.editMode == Stamp)
  in
    [ modeSelectionView model
    , case model.editMode of
        Select ->
          input
            [ id "paste-from-spreadsheet"
            , style S.pasteFromSpreadsheetInput
            , placeholder (I18n.pasteFromSpreadsheet model.lang)
            ] []

        Stamp ->
          lazy2 PrototypePreviewView.view prototypes True

        _ ->
          text ""
    ]


modeSelectionView : Model -> Html Msg
modeSelectionView model =
  div
    [ style S.modeSelectionView ]
    [ modeSelectionViewEach Icons.selectMode model.editMode Select
    , modeSelectionViewEach Icons.penMode model.editMode Pen
    , modeSelectionViewEach Icons.stampMode model.editMode Stamp
    , modeSelectionViewEach Icons.labelMode model.editMode LabelMode
    ]


modeSelectionViewEach : (Bool -> Html Msg) -> EditMode -> EditMode -> Html Msg
modeSelectionViewEach viewIcon currentEditMode targetEditMode =
  let
    selected =
      currentEditMode == targetEditMode
  in
    div
      [ style (S.modeSelectionViewEach selected)
      , onClick' (ChangeMode targetEditMode)
      ]
      [ viewIcon selected ]


view : Model -> Html Msg
view model =
  let
    header =
      case model.editMode of
        Viewing True ->
          App.map HeaderMsg (Header.viewPrintMode (EditingFloor.present model.floor).name)

        _ ->
          App.map HeaderMsg (Header.view model.lang model.title (Just (model.user, False)))

    diffView =
      Maybe.withDefault (text "") <|
        Maybe.map
          ( DiffView.view
              model.lang
              model.visitDate
              model.personInfo
              { onClose = CloseDiff, onConfirm = ConfirmDiff, noOp = NoOp }
          )
          model.diff
  in
    div
      []
      [ header
      , mainView model
      , diffView
      , ContextMenu.view model
      ]

--
