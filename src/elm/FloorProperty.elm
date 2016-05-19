module FloorProperty exposing(..) -- where

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
import Model.Floor

type alias Floor = Model.Floor.Model

type Msg =
    NoOp
  | InputFloorName String
  | InputFloorRealWidth String
  | InputFloorRealHeight String
  | LoadFile FileList
  | GotDataURL File String
  | PreparePublish
  | FileError File.Error

type Event =
    OnNameChange String
  | OnRealSizeChange (Int, Int)
  | OnFileWithDataURL File String
  | OnPreparePublish
  | OnFileLoadFailed File.Error
  | None

type alias Model =
  { nameInput : String
  , realWidthInput : String
  , realHeightInput : String
  }

init : String -> Int -> Int -> Model
init name realWidth realHeight =
  { nameInput = name
  , realWidthInput = toString realWidth
  , realHeightInput = toString realHeight
  }


validName : String -> Bool
validName s = True -- TODO

update : Msg -> Model -> (Model, Cmd Msg, Event)
update message model =
  case message of
    NoOp ->
        (model, Cmd.none, None)
    InputFloorName name ->
      let
        newModel = { model | nameInput = name }
        event =
          if validName name then OnNameChange name else None
      in
        (newModel, Cmd.none, event)
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
    FileError err ->
        (model, Cmd.none, OnFileLoadFailed err)

sizeEvent : Model -> Event
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

floorNameInputView : Model -> Html Msg
floorNameInputView model =
  let
    floorNameLabel = label [ style Styles.floorNameLabel ] [ text "Name" ]
    nameInput =
      input
      ([ Html.Attributes.id "floor-name-input"
      , type' "text"
      , style Styles.floorNameInput
      ] ++ (inputAttributes InputFloorName (always NoOp) model.nameInput Nothing))
      []
  in
    div [] [ floorNameLabel, nameInput ]

floorRealSizeInputView : Model -> Html Msg
floorRealSizeInputView model =
  let
    useReal = True--TODO
    widthInput =
      input
      ([ Html.Attributes.id "floor-real-width-input"
      , type' "text"
      , disabled (not useReal)
      , style Styles.realSizeInput
      ] ++ (inputAttributes InputFloorRealWidth (always NoOp) (model.realWidthInput) Nothing))
      []
    heightInput =
      input
      ([ Html.Attributes.id "floor-real-height-input"
      , type' "text"
      , disabled (not useReal)
      , style Styles.realSizeInput
      ] ++ (inputAttributes InputFloorRealHeight (always NoOp) (model.realHeightInput) Nothing))
      []
    widthLabel = label [ style Styles.widthHeightLabel ] [ text "Width(m)" ]
    heightLabel = label [ style Styles.widthHeightLabel ] [ text "Height(m)" ]
  in
    div [] [widthLabel, widthInput, heightLabel, heightInput ]


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


publishButtonView : User -> Html Msg
publishButtonView user =
  if User.isAdmin user then
    button
      [ onClick' PreparePublish
      , style Styles.publishButton ]
      [ text "Publish" ]
  else
    text ""

floorUpdateInfoView : Date -> Floor -> Html Msg
floorUpdateInfoView visitDate floor =
  let
    date at =
      formatDateOrTime visitDate at
  in
    case floor.update of
      Just { by, at } ->
        div [] [ text ("Last Update by " ++ by ++ " at " ++ date at) ]
      Nothing ->
        text ""

view : Date -> User -> Floor -> Model -> List (Html Msg)
view visitDate user floor model =
    [ fileLoadButton LoadFile Styles.imageLoadButton "Load Image"
    , floorNameInputView model
    , floorRealSizeInputView model
    , publishButtonView user
    , floorUpdateInfoView visitDate floor
    ]
