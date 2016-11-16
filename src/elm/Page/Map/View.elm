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

import Model.Mode as Mode exposing (Mode(..), EditingMode(..), Tab(..))
import Model.Prototypes as Prototypes exposing (PositionedPrototype)
import Model.User as User
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n exposing (Language)

import Page.Map.Model as Model exposing (Model, ContextMenu(..), DraggingContext(..))
import Page.Map.Msg exposing (Msg(..))
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
      if Mode.isPrintMode model.mode then
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
  if Mode.isPrintMode model.mode then
    text ""
  else
    FloorsInfoView.view
      ShowContextMenuOnFloorInfo
      MoveOnCanvas
      GoToFloor
      CreateNewFloor
      model.keys.ctrl
      model.user
      (Mode.isEditMode model.mode)
      (Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor)
      model.floorsInfo


subView : Model -> Html Msg
subView model =
  let
    pane =
      case model.mode of
        Editing EditTab editingMode ->
          subViewForEdit model editingMode

        _ ->
          subViewForSearch model

    tabs =
      if model.floor /= Nothing && (not <| User.isGuest model.user) then
        case model.mode of
          Editing tab _ ->
            [ subViewTab (ChangeTab SearchTab) 0 Icons.searchTab (tab == SearchTab)
            , subViewTab (ChangeTab EditTab) 1 Icons.editTab (tab == EditTab)
            ]

          _ ->
            []
      else
        []
  in
    div [ style (S.subView) ] (pane ++ tabs)


subViewForEdit : Model -> EditingMode -> List (Html Msg)
subViewForEdit model editingMode =
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
    [ card Nothing <| drawingView model editingMode
    , card Nothing <| PropertyView.view model
    , card Nothing <| floorView
    ]


subViewForSearch : Model -> List (Html Msg)
subViewForSearch model =
  [ card Nothing [ SearchInputView.view model.lang UpdateSearchQuery SubmitSearch model.searchQuery ]
  , card (Just (snd model.windowSize - 37 - 69)) [ SearchResultView.view model ]
  ]


subViewTab : msg -> Int -> Html msg -> Bool -> Html msg
subViewTab msg index icon active =
  div
    [ style (S.subViewTab index active)
    , onClick msg
    ]
    [ icon ]


drawingView : Model -> EditingMode -> List (Html Msg)
drawingView model editingMode =
  let
    prototypes =
      Prototypes.prototypes model.prototypes
  in
    [ modeSelectionView editingMode
    , case editingMode of
        Select ->
          input
            [ id "paste-from-spreadsheet"
            , style S.pasteFromSpreadsheetInput
            , placeholder (I18n.pasteFromSpreadsheet model.lang)
            ] []

        Stamp ->
          lazy PrototypePreviewView.view prototypes

        _ ->
          text ""
    ]


modeSelectionView : EditingMode -> Html Msg
modeSelectionView editingMode =
  div
    [ style S.modeSelectionView ]
    [ modeSelectionViewEach Icons.selectMode editingMode Select
    , modeSelectionViewEach Icons.penMode editingMode Pen
    , modeSelectionViewEach Icons.stampMode editingMode Stamp
    , modeSelectionViewEach Icons.labelMode editingMode Label
    ]


modeSelectionViewEach : (Bool -> Html Msg) -> EditingMode -> EditingMode -> Html Msg
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
    (title, printMode) =
      case (model.floor, model.mode) of
        (Just floor, Viewing True) ->
          ((EditingFloor.present floor).name, True)

        _ ->
          (model.title, False)

    header =
      Header.view
        { onSignInClicked = SignIn
        , onSignOutClicked = SignOut
        , onToggleEditing = ToggleEditing
        , onTogglePrintView = TogglePrintView
        , onSelectLang = SelectLang
        , onUpdate = UpdateHeaderState
        , title = title
        , lang = model.lang
        , user = Just model.user
        , editing = Mode.isEditMode model.mode
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
