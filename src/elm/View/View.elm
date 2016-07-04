module View.View exposing (view)

import Dict exposing (..)
import Maybe

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import SearchBox
import Header
import EquipmentNameInput
import View.Styles as Styles
import View.Icons as Icons
import View.MessageBar as MessageBar
import View.EquipmentView as EquipmentView exposing (..)
import View.FloorsInfoView as FloorsInfoView
import View.DiffView as DiffView
import View.ProfilePopup as ProfilePopup
import FloorProperty

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model exposing (..)
import Model.Floor as Floor
import Model.Equipments as Equipments exposing (..)
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
        [ style (Styles.contextMenu (x, y + 37) (fst model.windowSize, snd model.windowSize) 2) -- TODO
        ] -- TODO
        [ contextMenuItemView (SelectIsland id) "Select Island"
        , contextMenuItemView (RegisterPrototype id) "Register as stamp"
        , contextMenuItemView (Rotate id) "Rotate"
        ]

contextMenuItemView : Msg -> String -> Html Msg
contextMenuItemView action text' =
  hover Styles.hovarableHover
  div
    [ style Styles.contextMenuItem
    , onMouseDown' action
    ]
    [ text text' ]

equipmentView : Model -> Maybe ((Int, Int), (Int, Int)) -> Bool -> Bool -> Equipment -> Bool -> Bool -> Html Msg
equipmentView model moving selected alpha equipment contextMenuDisabled disableTransition =
  case equipment of
    Desk id (left, top, width, height) color name personId ->
      let
        movingBool = moving /= Nothing
        (x, y) =
          case moving of
            Just ((startX, startY), (x, y)) ->
              let
                (dx, dy) = Scale.screenToImageForPosition model.scale ((x - startX), (y - startY))
              in
                fitToGrid model.gridSize (left + dx, top + dy)
            _ -> (left, top)
        eventOptions =
          case model.editMode of
            Viewing _ ->
              let
                noEvents = EquipmentView.noEvents
              in
                { noEvents |
                  onMouseDown = Just (ShowDetailForEquipment id)
                }
            _ ->
              { onContextMenu =
                  if contextMenuDisabled then
                    Nothing
                  else
                    Just (ShowContextMenuOnEquipment id)
              , onMouseDown = Just (MouseDownOnEquipment id)
              , onMouseUp = Just (MouseUpOnEquipment id)
              , onStartEditingName = Nothing -- Just (StartEditEquipment id)
              }
        floor = currentFloor model
        personInfo =
          model.selectedResult `Maybe.andThen` \id' ->
            if id' == id then
              findEquipmentById floor.equipments id `Maybe.andThen` \equipment ->
              Equipments.relatedPerson equipment `Maybe.andThen` \personId ->
              Dict.get personId model.personInfo
            else
              Nothing

        personMatched = personId /= Nothing
      in
        equipmentView'
          eventOptions
          (model.editMode /= Viewing True && model.editMode /= Viewing False)
          (id ++ toString movingBool)
          (x, y, width, height)
          color
          name
          selected
          alpha
          model.scale
          disableTransition
          personInfo
          personMatched

transitionDisabled : Model -> Bool
transitionDisabled model =
  not model.scaling

mainView : Model -> Html Msg
mainView model =
  let
    (windowWidth, windowHeight) = model.windowSize
    createMsg =
      if (model.editMode /= Viewing True && model.editMode /= Viewing False) && User.isAdmin model.user then
        Just CreateNewFloor
      else
        Nothing
    filteredFloorsInfo =
      List.filter
      (if (model.editMode /= Viewing True && model.editMode /= Viewing False) then (always True) else (.public))
      model.floorsInfo
  in
    main' [ style (Styles.mainView windowHeight) ]
      [ FloorsInfoView.view createMsg (currentFloor model).id filteredFloorsInfo
      , MessageBar.view model.error
      , canvasContainerView model
      , if model.editMode == Viewing True then text "" else subView model
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
      case model.editMode of
        Viewing _ -> []
        _ ->
          [ subViewTab (ChangeTab SearchTab) 0 Icons.searchTab (model.tab == SearchTab)
          , subViewTab (ChangeTab EditTab) 1 Icons.editTab (model.tab == EditTab)
          ]
  in
    div
      [ style (Styles.subView)
      ]
      (pane ++ tabs)

subViewForEdit : Model -> List (Html Msg)
subViewForEdit model =
  let
    floorView =
      List.map
        (App.map FloorPropertyMsg)
        (FloorProperty.view model.visitDate model.user (currentFloor model) model.floorProperty)
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
        List.map (\f -> (Maybe.withDefault "draft" f.id, f)) model.floorsInfo
    format =
      formatSearchResult floorsInfoDict model.personInfo

    thisFloorId =
      (currentFloor model).id
  in
    [ card <| [ SearchBox.view SearchBoxMsg model.searchBox ]
    , card <| [ SearchBox.resultsView SearchBoxMsg thisFloorId format model.searchBox ]
    ]

formatSearchResult : Dict String Floor -> Dict String Person -> SearchResult -> Html Msg
formatSearchResult floorsInfo personInfo { personId, equipmentIdAndFloorId } =
  let
    floorName =
      case equipmentIdAndFloorId of
        Just (e, fid) ->
          if fid == "draft" then
            "draft"
          else
            case Dict.get fid floorsInfo of
              Just info ->
                info.name
              Nothing ->
                "?" -- Seems a bug
        Nothing ->
          "Missing"
    isPerson =
      personId /= Nothing
    icon =
      div
        [ style Styles.searchResultItemIcon
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
  in
    div
      [ style <| Styles.searchResultItemInner
      ]
      [ icon, text (name ++ "(" ++ floorName ++ ")") ]


subViewTab : msg -> Int -> Html msg -> Bool -> Html msg
subViewTab msg index icon active =
  div
    [ style (Styles.subViewTab index active)
    , onClick msg
    ]
    [ icon ]

card : List (Html msg) -> Html msg
card children =
  div
    [ {-style Styles.card-}
    style [("margin-bottom", "20px"), ("padding", "20px")]
    ] children

penView : Model -> List (Html Msg)
penView model =
  let
    prototypes =
      Prototypes.prototypes model.prototypes
  in
    [ modeSelectionView model
    , prototypePreviewView prototypes (model.editMode == Stamp)
    ]


modeSelectionView : Model -> Html Msg
modeSelectionView model =
  let
    widthStyle = [("width", "80px")]
    selection =
      div
        [ style (Styles.selection (model.editMode == Select) ++ widthStyle)
        , onClick' (ChangeMode Select)
        ]
        [ Icons.selectMode (model.editMode == Select) ]
    pen =
      div
        [ style (Styles.selection (model.editMode == Pen) ++ widthStyle)
        , onClick' (ChangeMode Pen)
        ]
        [ Icons.penMode (model.editMode == Pen) ]
    stamp =
      div
        [ style (Styles.selection (model.editMode == Stamp) ++ widthStyle)
        , onClick' (ChangeMode Stamp)
        ]
        [ Icons.stampMode (model.editMode == Stamp) ]
  in
    div [ style (Styles.flex ++ [("margin-top", "10px")]) ] [selection, pen, stamp]

propertyView : Model -> List (Html Msg)
propertyView model =
    [ text "Properties"
    , colorPropertyView model
    ]

canvasContainerView : Model -> Html Msg
canvasContainerView model =
  let
    floor = currentFloor model
    popup' =
      Maybe.withDefault (text "") <|
      model.selectedResult `Maybe.andThen` \id ->
      findEquipmentById floor.equipments id `Maybe.andThen` \e ->
      Equipments.relatedPerson e `Maybe.andThen` \personId ->
      Dict.get personId model.personInfo `Maybe.andThen` \person ->
      Just (ProfilePopup.view ClosePopup model.scale model.offset e person)
  in
    div
      [ style (Styles.canvasContainer (model.editMode == Viewing True) ++
        ( if model.editMode == Stamp then
            [] -- [("cursor", "none")]
          else
            []
        ))
      , onMouseMove' MoveOnCanvas
      , onMouseDown MouseDownOnCanvas
      , onMouseUp MouseUpOnCanvas
      , onMouseEnter' EnterCanvas
      , onMouseLeave' LeaveCanvas
      , onMouseWheel MouseWheel
      ]
      [ canvasView model
      , popup'
      ]

canvasView : Model -> Html Msg
canvasView model =
  let
    floor = currentFloor model
    disableTransition = transitionDisabled model

    isViewing =
      case model.editMode of
        Viewing _ -> True
        _ -> False

    isDragged equipment =
      (case model.draggingContext of
        MoveEquipment _ _ -> True
        _ -> False
      ) && List.member (idOf equipment) model.selectedEquipments

    nonDraggingEquipments =
      List.map
        (\equipment ->
          equipmentView
            model
            Nothing
            (isSelected model equipment)
            (isDragged equipment)
            equipment
            model.keys.ctrl
            disableTransition)
        floor.equipments

    draggingEquipments =
      if (case model.draggingContext of
          MoveEquipment _ _ -> True
          _ -> False
        )
      then
        let
          equipments = List.filter isDragged floor.equipments
          (x, y) = model.pos
          moving =
            case model.draggingContext of
              MoveEquipment _ (startX, startY) -> Just ((startX, startY), (x, y))
              _ -> Nothing
        in
          List.map
            (\equipment ->
              equipmentView
                model
                moving
                (isSelected model equipment)
                False
                equipment
                model.keys.ctrl
                disableTransition
            )
            equipments
      else []

    equipments =
      draggingEquipments ++ nonDraggingEquipments

    selectorRect =
      case (model.editMode, model.selectorRect) of
        (Select, Just rect) ->
          div [style (Styles.selectorRect (Scale.imageToScreenForRect model.scale rect) ++ Styles.transition disableTransition )] []
        _ -> text ""

    temporaryStamps' = temporaryStampsView model
    temporaryPen' =
      case model.draggingContext of
        PenFromScreenPos (x, y) ->
          temporaryPenView model (x, y)
        _ -> text ""

    (offsetX, offsetY) = model.offset

    rect =
      Scale.imageToScreenForRect
        model.scale
        (offsetX, offsetY, Floor.width floor, Floor.height floor)

    image =
      img
        [ style [("width", "100%"), ("height", "100%")]
        , src (Maybe.withDefault "" (Floor.src floor))
        ] []

    nameInput =
      App.map EquipmentNameInputMsg <|
        EquipmentNameInput.view
          (screenRectOf model)
          (transitionDisabled model)
          (candidatesOf model)
          model.equipmentNameInput
  in
    div
      [ style (Styles.canvasView isViewing rect ++ Styles.transition disableTransition)
      ]
      ((image :: nameInput :: (selectorRect :: equipments)) ++ [temporaryPen'] ++ temporaryStamps')

screenRectOf : Model -> String -> Maybe (Int, Int, Int, Int)
screenRectOf model id =
  case findEquipmentById (currentFloor model).equipments id of
    Just (Desk id rect _ _ _) ->
      Just (Scale.imageToScreenForRect model.scale rect)
    Nothing -> Nothing

prototypePreviewView : List (Prototype, Bool) -> Bool -> Html Msg
prototypePreviewView prototypes stampMode =
  let
    width = 238 -- TODO
    height = 238 -- TODO
    each index (prototype, selected) =
      let
        (_, _, _, (w, h)) = prototype
        left = width // 2 - w // 2
        top = height // 2 - h // 2
      in
        temporaryStampView Scale.init False (prototype, (left + index * width, top))
    selectedIndex =
      Maybe.withDefault 0 <|
      List.head <|
      List.filterMap (\((prototype, selected), index) -> if selected then Just index else Nothing) <|
      zipWithIndex prototypes
    buttons =
      List.map (\label ->
        let
          position = (if label == "<" then "left" else "right", "3px")
        in
          div
            [ style (position :: Styles.prototypePreviewScroll)
            , onClick' (if label == "<" then PrototypesMsg Prototypes.prev else PrototypesMsg Prototypes.next)
            ]
            [ text label ]
        )
      ( (if selectedIndex > 0 then ["<"] else []) ++
        (if selectedIndex < List.length prototypes - 1 then [">"] else [])
      )

    inner =
      div
        [ style (Styles.prototypePreviewViewInner selectedIndex) ]
        (List.indexedMap each prototypes)
  in
    div
      [ style (Styles.prototypePreviewView stampMode) ]
      ( inner :: buttons )

temporaryStampView : Scale.Model -> Bool -> StampCandidate -> Html msg
temporaryStampView scale selected ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top)) =
    equipmentView'
      EquipmentView.noEvents
      False
      ("temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString deskWidth ++ "_" ++ toString deskHeight)
      (left, top, deskWidth, deskHeight)
      color
      name --name
      selected
      False -- alpha
      scale
      True -- disableTransition
      Nothing
      False -- personMatched

temporaryPenView : Model -> (Int, Int) -> Html msg
temporaryPenView model from =
  case temporaryPen model from of
    Just (color, name, (left, top, width, height)) ->
      equipmentView'
        EquipmentView.noEvents
        False
        ("temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString width ++ "_" ++ toString height)
        (left, top, width, height)
        color
        name --name
        False -- selected
        False -- alpha
        model.scale
        True -- disableTransition
        Nothing
        False -- personMatched
    Nothing ->
      text ""

temporaryStampsView : Model -> List (Html msg)
temporaryStampsView model =
  List.map
    (temporaryStampView model.scale False)
    (stampCandidates model)

colorPropertyView : Model -> Html Msg
colorPropertyView model =
  let
    match color =
      case colorProperty (selectedEquipments model) of
        Just c -> color == c
        Nothing -> False
    viewForEach color =
      li
        [ style (Styles.colorProperty color (match color))
        , onMouseDown' (SelectColor color)
        ]
        []
  in
    ul [ style (Styles.ul ++ [("display", "flex")]) ]
      (List.map viewForEach model.colorPalette)


view : Model -> Html Msg
view model =
  let
    header =
      case model.editMode of
        Viewing True ->
          Header.viewPrintMode (currentFloor model).name |> App.map HeaderMsg
        _ ->
          Header.view (Just (model.user, False)) |> App.map HeaderMsg
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
