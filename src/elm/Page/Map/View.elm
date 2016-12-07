module Page.Map.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Lazy exposing (..)

import ContextMenu

import View.Styles as S
import View.Icons as Icons
import View.MessageBarForMainView as MessageBar
import View.FloorsInfoView as FloorsInfoView
import View.DiffView as DiffView
import View.Common exposing (..)
import View.SearchInputView as SearchInputView

import Component.FloorProperty as FloorProperty
import Component.Header as Header
import Component.FileLoader as FileLoader
import Component.FloorDeleter as FloorDeleter

import Util.HtmlUtil exposing (..)

import Model.Mode as Mode exposing (Mode(..), EditingMode(..))
import Model.Prototypes as Prototypes exposing (PositionedPrototype)
import Model.EditingFloor as EditingFloor
import Model.I18n as I18n exposing (Language)
import Model.User as User exposing (User)

import Page.Map.Model as Model exposing (Model, DraggingContext(..))
import Page.Map.ContextMenuContext exposing (ContextMenuContext(..))
import Page.Map.Msg exposing (Msg(..))
import Page.Map.CanvasView as CanvasView
import Page.Map.PropertyView as PropertyView
import Page.Map.ContextMenu
import Page.Map.PrototypePreviewView as PrototypePreviewView
import Page.Map.SearchResultView as SearchResultView
import Page.Map.FloorUpdateInfoView as FloorUpdateInfoView

mainView : Model -> Html Msg
mainView model =
  let
    sub =
      if Mode.isPrintMode model.mode then
        text ""
      else
        subView model

    floorInfo =
      floorInfoView model
  in
    main_ [ style (S.mainView model.windowSize.height) ]
      [ floorInfo
      , Lazy.lazy2 MessageBar.view model.lang model.error
      , CanvasView.view model
      , sub
      , FloorUpdateInfoView.view model
      ]


floorInfoView : Model -> Html Msg
floorInfoView model =
  if Mode.isPrintMode model.mode then
    text ""
  else
    FloorsInfoView.view
      (\id -> ContextMenu.open ContextMenuMsg (FloorInfoContextMenu id))
      (Just >> GoToFloor)
      CreateNewFloor
      model.keys.ctrl
      model.user
      (Mode.isEditMode model.mode)
      (Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor)
      model.floorsInfo


subView : Model -> Html Msg
subView model =
  let
    searchResultView =
      if Mode.showingSearchResult model.mode then
        [ searchResultCard model ]
      else
        []

    editView =
      case Mode.currentEditMode model.mode of
        Just editingMode ->
          subViewForEdit model editingMode

        Nothing ->
          []
  in
    div [ style S.subView ] ( searchResultView ++ editView )


subViewForEdit : Model -> EditingMode -> List (Html Msg)
subViewForEdit model editingMode =
  let
    floorView =
      case model.floor of
        Just editingFloor ->
          FloorProperty.view
            FloorPropertyMsg
            model.lang
            model.user
            (EditingFloor.present editingFloor)
            model.floorProperty
            (Lazy.lazy2 fileLoadButton model.lang model.user)
            (Lazy.lazy2 publishButton model.lang model.user)
            (FloorDeleter.button model.lang model.user (EditingFloor.present editingFloor) |> Html.map FloorDeleterMsg)
            (FloorDeleter.dialog (EditingFloor.present editingFloor) model.floorDeleter |> Html.map FloorDeleterMsg)

        _ ->
          []
  in
    [ card False "#eee" Nothing Nothing <| drawingView model editingMode
    , card False "#eee" Nothing Nothing <| PropertyView.view model
    , card False "#eee" Nothing Nothing <| floorView
    ]


fileLoadButton : Language -> User -> Html Msg
fileLoadButton lang user =
  if User.isAdmin user then
    FileLoader.view lang |> Html.map FileLoaderMsg
  else
    text ""


publishButton : Language -> User -> Html Msg
publishButton lang user =
  if User.isAdmin user then
    button
      [ onClick_ PreparePublish
      , style S.publishButton ]
      [ text (I18n.publish lang) ]
  else
    text ""


searchResultCard : Model -> Html Msg
searchResultCard model =
  let
    maxHeight =
      model.windowSize.height - Model.headerHeight
  in
    card True "#eee" (Just maxHeight) (Just 320) <|
      SearchResultView.view model


drawingView : Model -> EditingMode -> List (Html Msg)
drawingView model editingMode =
  let
    prototypes =
      Prototypes.prototypes model.prototypes
  in
    [ Lazy.lazy modeSelectionView editingMode
    , case editingMode of
        Select ->
          Lazy.lazy pasteInput model.lang

        Stamp ->
          Lazy.lazy PrototypePreviewView.view prototypes

        _ ->
          text ""
    ]


pasteInput : Language -> Html msg
pasteInput lang =
  input
    [ id "paste-from-spreadsheet"
    , style S.pasteFromSpreadsheetInput
    , placeholder (I18n.pasteFromSpreadsheet lang)
    ] []


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
      , onClick_ (ChangeMode targetEditMode)
      ]
      [ viewIcon selected ]


view : Model -> Html Msg
view model =
  let
    printMode =
      Mode.isPrintMode model.mode

    title =
      case (model.floor, printMode) of
        (Just floor, True) ->
          (EditingFloor.present floor).name

        _ ->
          model.title

    header =
      Header.view
        { onSignInClicked = SignIn
        , onSignOutClicked = SignOut
        , onToggleEditing = ToggleEditing
        , onTogglePrintView = TogglePrintView
        , onSelectLang = SelectLang
        , onUpdate = HeaderMsg
        , title = title
        , lang = model.lang
        , user = Just model.user
        , editing = Mode.isEditMode model.mode
        , printMode = printMode
        , searchInput = Just (SearchInputView.view model.lang UpdateSearchQuery SubmitSearch model.searchQuery)
        }
        model.header

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
      , Page.Map.ContextMenu.view model
      , printGuide printMode
      ]


printGuide : Bool -> Html msg
printGuide isPrintMode =
  if isPrintMode then
    div
      [ style S.printGuide
      , class "no-print"
      ]
      [ div [ style ( S.printGuideItem 1122 793) ] [ text "A4" ]
      , div [ style ( S.printGuideItem 1587 1122) ] [ text "A3" ]
      , div [ style ( S.printGuideItem 2245 1587) ] [ text "A2" ]
      ]
  else
    text ""


--
