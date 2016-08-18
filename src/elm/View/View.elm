module View.View exposing (view)

import Dict exposing (..)
import Maybe

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

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
import FloorProperty

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model exposing (..)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Object as Object exposing (..)
import Model.Scale as Scale
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (StampCandidate)
import Model.User as User
import Model.Person exposing (Person)
import Model.SearchResult exposing (SearchResult)
import Model.EditingFloor as EditingFloor


mainView : Model -> Html Msg
mainView model =
  let
    (_, windowHeight) = model.windowSize

    sub =
      if model.editMode == Viewing True then
        text ""
      else subView model

    floorInfo =
      floorInfoView model
  in
    main' [ style (S.mainView windowHeight) ]
      [ floorInfo
      , MessageBar.view model.error
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
          HideContextMenu
          CreateNewFloor
          (model.keys.ctrl)
          (User.isAdmin model.user)
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
      formatSearchResult floorsInfoDict model.personInfo model.selectedResult

    isEditing =
      (model.editMode /= Viewing True && model.editMode /= Viewing False)

  in
    [ card <| [ SearchBox.view SearchBoxMsg model.searchBox ]
    , card <| [ SearchBox.resultsView SearchBoxMsg isEditing format model.searchBox ]
    ]


formatSearchResult : Dict String Floor -> Dict String Person -> Maybe Id -> SearchResult -> Html Msg
formatSearchResult floorsInfo personInfo selectedResult = \result ->
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
          "Missing"

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
  in
    [ modeSelectionView model
    , prototypePreviewView prototypes (model.editMode == Stamp)
    ]


prototypePreviewView : List (Prototype, Bool) -> Bool -> Html Msg
prototypePreviewView prototypes stampMode =
  let
    width = 320 - (20 * 2) -- TODO
    height = 238 -- TODO

    selectedIndex =
      Maybe.withDefault 0 <|
      List.head <|
      List.filterMap (\((prototype, selected), index) -> if selected then Just index else Nothing) <|
      zipWithIndex prototypes

    buttons =
      prototypePreviewViewButtons selectedIndex prototypes

    inner =
      div
        [ style (S.prototypePreviewViewInner width selectedIndex) ]
        (List.indexedMap (prototypePreviewViewEach (width, height)) prototypes)
  in
    div
      [ style (S.prototypePreviewView stampMode) ]
      ( inner :: buttons )


prototypePreviewViewEach : (Int, Int) -> Int -> (Prototype, Bool) -> Html Msg
prototypePreviewViewEach (width, height) index (prototype, selected) =
  let
    (w, h) = prototype.size
    left = width // 2 - w // 2
    top = height // 2 - h // 2
  in
    snd <| CanvasView.temporaryStampView Scale.init False (prototype, (left + index * width, top))


prototypePreviewViewButtons : Int -> List (Prototype, Bool) -> List (Html Msg)
prototypePreviewViewButtons selectedIndex prototypes =
  List.map (\isLeft ->
    let
      label = if isLeft then "<" else ">"
    in
      div
        [ style (S.prototypePreviewScroll isLeft)
        , onClick' (if isLeft then PrototypesMsg Prototypes.prev else PrototypesMsg Prototypes.next)
        ]
        [ text label ]
    )
  ( (if selectedIndex > 0 then [True] else []) ++
    (if selectedIndex < List.length prototypes - 1 then [ False ] else [])
  )


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
          App.map HeaderMsg (Header.view model.title (Just (model.user, False)))

    diffView =
      Maybe.withDefault (text "") <|
        Maybe.map
          ( DiffView.view
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
