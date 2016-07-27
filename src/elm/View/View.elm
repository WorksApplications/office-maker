module View.View exposing (view)

import Dict exposing (..)
import Maybe
import String

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
import FloorProperty

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model exposing (..)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Equipment as Equipment exposing (..)
import Model.Scale as Scale
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)
import Model.Prototypes as Prototypes exposing (Prototype, StampCandidate)
import Model.User as User
import Model.Person exposing (Person)
import Model.SearchResult exposing (SearchResult)

import InlineHover exposing (hover)


contextMenuView : Model -> Html Msg
contextMenuView model =
  case model.contextMenu of
    NoContextMenu ->
      text ""

    Equipment (x, y) id ->
      div
        [ style (S.contextMenu (x, y + 37) (fst model.windowSize, snd model.windowSize) 2) -- TODO
        ] -- TODO
        [ contextMenuItemView (SelectIsland id) "Select Island"
        , contextMenuItemView (RegisterPrototype id) "Register as stamp"
        , contextMenuItemView (Rotate id) "Rotate"
        ]


contextMenuItemView : Msg -> String -> Html Msg
contextMenuItemView action text' =
  hover
    S.contextMenuItemHover
    div
    [ style S.contextMenuItem
    , onMouseDown' action
    ]
    [ text text' ]


mainView : Model -> Html Msg
mainView model =
  let
    (windowWidth, windowHeight) = model.windowSize

    isEditMode =
      model.editMode /= Viewing True && model.editMode /= Viewing False

    sub =
      if model.editMode == Viewing True then
        text ""
      else subView model
  in
    main' [ style (S.mainView windowHeight) ]
      [ FloorsInfoView.view CreateNewFloor (User.isAdmin model.user) isEditMode model.floor.present.id model.floorsInfo
      , MessageBar.view model.error
      , CanvasView.view model
      , sub
      ]


subView : Model -> Html Msg
subView model =
  let
    pane =
      if model.tab == SearchTab then
        subViewForSearch model
      else
        subViewForEdit model

    tabs =
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
        (FloorProperty.view model.visitDate model.user model.floor.present model.floorProperty)
  in
    [ card <| penView model
    , card <| propertyView model
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
            FloorInfo.Public f -> (Maybe.withDefault "draft" f.id, f)
            FloorInfo.PublicWithEdit _ f -> (Maybe.withDefault "draft" f.id, f)
            FloorInfo.Private f -> (Maybe.withDefault "draft" f.id, f)
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
    { personId, equipmentIdAndFloorId } = result

    floorName =
      case equipmentIdAndFloorId of
        Just (e, fid) ->
          if fid == "draft" || String.left 3 fid == "tmp" then
            "draft"
          else
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

    nameOfEquipment =
      case equipmentIdAndFloorId of
        Just (e, fid) -> nameOf e
        Nothing -> ""

    name =
      case personId of
        Just id ->
          case Dict.get id personInfo of
            Just person -> person.name
            Nothing -> nameOfEquipment
        Nothing -> nameOfEquipment

    selectable =
      equipmentIdAndFloorId /= Nothing

    selected =
      case (selectedResult, equipmentIdAndFloorId) of
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


card : List (Html msg) -> Html msg
card children =
  div [ style S.card ] children


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

    each index (prototype, selected) =
      let
        (_, _, _, (w, h)) = prototype
        left = width // 2 - w // 2
        top = height // 2 - h // 2
      in
        snd <| CanvasView.temporaryStampView Scale.init False (prototype, (left + index * width, top))

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
        (List.indexedMap each prototypes)
  in
    div
      [ style (S.prototypePreviewView stampMode) ]
      ( inner :: buttons )


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
    (if selectedIndex < List.length prototypes - 1 then [False] else [])
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


propertyView : Model -> List (Html Msg)
propertyView model =
    [ colorPropertyView model
    ]


colorPropertyView : Model -> Html Msg
colorPropertyView model =
  let
    match color =
      case colorProperty (selectedEquipments model) of
        Just c -> color == c
        Nothing -> False

    viewForEach color =
      li
        [ style (S.colorProperty color (match color))
        , onMouseDown' (SelectColor color)
        ]
        []
  in
    ul
      [ style S.colorProperties ]
      (List.map viewForEach model.colorPalette)


view : Model -> Html Msg
view model =
  let
    header =
      case model.editMode of
        Viewing True ->
          App.map HeaderMsg (Header.viewPrintMode model.floor.present.name)
        _ ->
          App.map HeaderMsg (Header.view (Just (model.user, False)))

    diffView =
      Maybe.withDefault (text "") <|
        Maybe.map
          ( DiffView.view
              model.visitDate
              model.personInfo
              { onClose = CloseDiff, onConfirm = ConfirmDiff, noOp = NoOp }
          )
          model.diff -- TODO
  in
    div
      []
      [ header
      , mainView model
      , diffView
      , contextMenuView model
      ]

--
