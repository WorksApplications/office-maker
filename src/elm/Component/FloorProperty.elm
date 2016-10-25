module Component.FloorProperty exposing(..)

import String
import Date exposing (Date)
import Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Task

import Util.File as File exposing (..)
import Util.HtmlUtil exposing (..)
import Util.DateUtil exposing (..)

import View.Styles as Styles

import Model.User as User exposing (User)
import Model.Floor exposing (Floor)
import Model.I18n as I18n exposing (Language)

import Component.Dialog as Dialog exposing (Dialog)

import InlineHover exposing (hover)


type Msg
  = NoOp
  | InputFloorName String
  | InputFloorOrd String
  | InputFloorRealWidth String
  | InputFloorRealHeight String
  | LoadFile FileList
  | GotDataURL File String
  | PreparePublish
  | SelectDeleteFloor
  | DeleteDialogMsg (Dialog.Msg Msg)
  | DeleteFloor
  | FileError File.Error


type Event
  = OnNameChange String
  | OnOrdChange Int
  | OnRealSizeChange (Int, Int)
  | OnFileWithDataURL File String
  | OnPreparePublish
  | OnDeleteFloor
  | OnFileLoadFailed File.Error
  | None


type alias FloorProperty =
  { nameInput : String
  , realWidthInput : String
  , realHeightInput : String
  , ordInput : String
  , deleteFloorDialog : Dialog
  }


init : String -> Int -> Int -> Int -> FloorProperty
init name realWidth realHeight ord =
  { nameInput = name
  , realWidthInput = toString realWidth
  , realHeightInput = toString realHeight
  , ordInput = toString ord
  , deleteFloorDialog = Dialog.init
  }


validName : String -> Bool
validName s =
  String.length s > 0


update : Msg -> FloorProperty -> (FloorProperty, Cmd Msg, Event)
update message model =
  case message of
    NoOp ->
        (model, Cmd.none, None)

    InputFloorName name ->
      let
        newModel =
          { model | nameInput = name }

        event =
          if validName name then OnNameChange name else None
      in
        (newModel, Cmd.none, event)

    InputFloorOrd ord ->
      let
        newModel = { model | ordInput = ord }
      in
        (newModel, Cmd.none, ordEvent ord)

    InputFloorRealWidth width ->
      let
        newModel = { model | realWidthInput = width }
      in
        (newModel, Cmd.none, sizeEvent newModel)

    InputFloorRealHeight height ->
      let
        newModel = { model | realHeightInput = height }
      in
        (newModel, Cmd.none, sizeEvent newModel)

    LoadFile fileList ->
      case File.getAt 0 fileList of
        Just file ->
          let
            cmd =
              Task.perform FileError (GotDataURL file) (readAsDataURL file)
          in
            (model, cmd, None)

        Nothing ->
          (model, Cmd.none, None)

    GotDataURL file url ->
        (model, Cmd.none, OnFileWithDataURL file url)

    PreparePublish ->
        (model, Cmd.none, OnPreparePublish)

    SelectDeleteFloor ->
      (model, Dialog.open DeleteDialogMsg, None)

    DeleteDialogMsg msg ->
      let
        (deleteFloorDialog, newMsg) =
          Dialog.update msg model.deleteFloorDialog
      in
        ({ model | deleteFloorDialog = deleteFloorDialog }, newMsg, None)

    DeleteFloor ->
        (model, Cmd.none, OnDeleteFloor)

    FileError err ->
        (model, Cmd.none, OnFileLoadFailed err)


ordEvent : String -> Event
ordEvent ord =
  case String.toInt ord of
    Ok ord ->
      OnOrdChange ord

    Err s ->
      None


sizeEvent : FloorProperty -> Event
sizeEvent newModel =
  case ( parsePositiveInt newModel.realWidthInput
       , parsePositiveInt newModel.realHeightInput
       ) of
    (Just width, Just height) ->
      OnRealSizeChange (width, height)

    _ ->
      None


parsePositiveInt : String -> Maybe Int
parsePositiveInt s =
  case String.toInt s of
    Err s -> Nothing
    Ok i ->
      if i > 0 then Just i else Nothing


-- VIEW


floorNameInputView : Language -> User -> FloorProperty -> Html Msg
floorNameInputView lang user model =
  let
    floorNameLabel =
      label [ style Styles.floorNameLabel ] [ text (I18n.name lang) ]
  in
    div
      [ style Styles.floorNameInputContainer ]
      [ floorNameLabel
      , nameInput user model.nameInput
      ]


nameInput : User -> String -> Html Msg
nameInput user value =
  if User.isAdmin user then
    input
    ([ Html.Attributes.id "floor-name-input"
    , type' "text"
    , style Styles.floorNameInput
    ] ++ (inputAttributes InputFloorName (always NoOp) value Nothing))
    []
  else
    div [ style Styles.floorNameText ] [ text value ]


floorOrdInputView : Language -> User -> FloorProperty -> Html Msg
floorOrdInputView lang user model =
  let
    floorOrdLabel = label [ style Styles.floorOrdLabel ] [ text (I18n.order lang) ]
  in
    div [ style Styles.floorOrdInputContainer ] [ floorOrdLabel, ordInput user model.ordInput ]


ordInput : User -> String -> Html Msg
ordInput user value =
  if User.isAdmin user then
    input
    ([ Html.Attributes.id "floor-ord-input"
    , type' "text"
    , style Styles.floorOrdInput
    ] ++ (inputAttributes InputFloorOrd (always NoOp) value Nothing))
    []
  else
    div [ style Styles.floorOrdText ] [ text value ]


floorRealSizeInputView : Language -> User -> FloorProperty -> Html Msg
floorRealSizeInputView lang user model =
  let
    useReal = True--TODO
    widthLabel = label [ style Styles.widthHeightLabel ] [ text (I18n.widthMeter lang) ]
    heightLabel = label [ style Styles.widthHeightLabel ] [ text (I18n.heightMeter lang) ]
  in
    div [ style Styles.floorSizeInputContainer ]
      [ widthLabel
      , widthValueView user useReal model.realWidthInput
      , heightLabel
      , heightValueView user useReal model.realHeightInput
      ]


inputAttributes : (String -> msg) -> (Int -> msg) -> String -> Maybe msg -> List (Attribute msg)
inputAttributes toInputMsg toKeydownMsg value' defence =
  [ onInput' toInputMsg -- TODO cannot input japanese
  , onKeyDown'' toKeydownMsg
  , value value'
  ] ++
    ( case defence of
        Just message -> [onMouseDown' message]
        Nothing -> []
    )


widthValueView : User -> Bool -> String -> Html Msg
widthValueView user useReal value =
  if User.isAdmin user then
    input
    ([ Html.Attributes.id "floor-real-width-input"
    , type' "text"
    , disabled (not useReal)
    , style Styles.realSizeInput
    ] ++ (inputAttributes InputFloorRealWidth (always NoOp) value Nothing))
    []
  else
    div [ style Styles.floorWidthText ] [text value]


heightValueView : User -> Bool -> String -> Html Msg
heightValueView user useReal value =
  if User.isAdmin user then
    input
    ([ Html.Attributes.id "floor-real-height-input"
    , type' "text"
    , disabled (not useReal)
    , style Styles.realSizeInput
    ] ++ (inputAttributes InputFloorRealHeight (always NoOp) value Nothing))
    []
  else
    div [ style Styles.floorHeightText ] [text value]


publishButtonView : Language -> User -> Html Msg
publishButtonView lang user =
  if User.isAdmin user then
    button
      [ onClick' PreparePublish
      , style Styles.publishButton ]
      [ text (I18n.publish lang) ]
  else
    text ""


deleteButtonView : Language -> User -> Floor -> Html Msg
deleteButtonView lang user floor =
  if User.isAdmin user && List.isEmpty floor.objects then
    hover Styles.deleteFloorButtonHover
    button
      [ onClick' SelectDeleteFloor
      , style Styles.deleteFloorButton
      ]
      [ text (I18n.deleteFloor lang) ]
  else
    text ""


floorUpdateInfoView : Language -> Date -> Floor -> Html Msg
floorUpdateInfoView lang visitDate floor =
  let
    date at =
      formatDateOrTime visitDate at
  in
    case floor.update of
      Just { by, at } ->
        div
          [ style Styles.floorPropertyLastUpdate ]
          [ text (I18n.lastUpdateByAt lang by (date at)) ]

      Nothing ->
        text ""


view : Language -> Date -> User -> Floor -> FloorProperty -> List (Html Msg)
view lang visitDate user floor model =
    [ if User.isAdmin user then
        fileLoadButton LoadFile Styles.imageLoadButton (I18n.loadImage lang)
      else
        text ""
    , floorNameInputView lang user model
    , floorOrdInputView lang user model
    , floorRealSizeInputView lang user model
    , publishButtonView lang user
    , deleteButtonView lang user floor
    , floorUpdateInfoView lang visitDate floor
    , Dialog.view
        { strategy = Dialog.ConfirmOrClose ("delete", DeleteFloor) ("cancel", NoOp)
        , transform = DeleteDialogMsg
        }
        "delete this floor?"
        model.deleteFloorDialog
    ]
    
