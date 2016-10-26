module Page.Map.View exposing (view)

import Maybe

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)

import View.Styles as S
import View.Icons as Icons
import View.MessageBarForMainView as MessageBar
import View.FloorsInfoView as FloorsInfoView
import View.DiffView as DiffView
import View.Common exposing (..)
import View.SearchInputView as SearchInputView

import Component.FloorProperty as FloorProperty
import Component.Header as Header

import Util.HtmlUtil exposing (..)

import Model.EditMode as EditMode exposing (EditMode(..))
import Model.Prototypes as Prototypes exposing (StampCandidate)
import Model.User as User
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n exposing (Language)

import Page.Map.Model as Model exposing (Model, ContextMenu(..), DraggingContext(..), Tab(..))
import Page.Map.Update exposing (..)
import Page.Map.CanvasView as CanvasView
import Page.Map.PropertyView as PropertyView
import Page.Map.ContextMenu as ContextMenu
import Page.Map.PrototypePreviewView as PrototypePreviewView
import Page.Map.SearchResultView as SearchResultView

mainView : Model -> Html Msg
mainView model =
  let
    (_, windowHeight) = model.windowSize

    sub =
      if EditMode.isPrintMode model.editMode then
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
  if EditMode.isPrintMode model.editMode then
    text ""
  else
    FloorsInfoView.view
      ShowContextMenuOnFloorInfo
      MoveOnCanvas
      GoToFloor
      CreateNewFloor
      model.keys.ctrl
      model.user
      (EditMode.isEditMode model.editMode)
      (Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor)
      model.floorsInfo


subView : Model -> Html Msg
subView model =
  let
    pane =
      if model.tab == SearchTab || model.floor == Nothing then
        subViewForSearch model
      else
        subViewForEdit model

    tabs =
      if model.floor == Nothing then
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
        (case model.floor of
          Just editingFloor ->
            FloorProperty.view
              model.lang
              model.visitDate
              model.user
              (EditingFloor.present editingFloor)
              model.floorProperty

          _ ->
            []
        )
  in
    [ card <| penView model
    , card <| PropertyView.view model
    , card <| floorView
    ]


subViewForSearch : Model -> List (Html Msg)
subViewForSearch model =
  [ card <| [ SearchInputView.view model.lang UpdateSearchQuery SubmitSearch model.searchQuery ]
  , card <| [ SearchResultView.view SelectSearchResult model ]
  ]


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
    (title, printMode, editing) =
      case (model.floor, model.editMode) of
        (Just floor, Viewing True) ->
          ((EditingFloor.present floor).name, True, False)

        (_, Viewing False) ->
          (model.title, False, False)

        _ ->
          (model.title, False, True)

    header =
      Header.view
        { onSignInClicked = SignIn
        , onSignOutClicked = SignOut
        , onToggleEditing = ToggleEditing
        , onTogglePrintView = TogglePrintView model.editMode
        , onSelectLang = SelectLang
        , onUpdate = UpdateHeaderState
        , title = title
        , lang = model.lang
        , user = Just model.user
        , editing = editing
        , printMode = printMode
        }
        model.headerState

    diffView =
      Maybe.withDefault (text "") <|
        Maybe.map
          ( DiffView.view
              model.lang
              model.visitDate
              model.personInfo
              { onClose = CloseDiff, onConfirm = ConfirmDiff }
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
