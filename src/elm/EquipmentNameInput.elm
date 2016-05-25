module EquipmentNameInput exposing (..) -- where

import Util.ShortCut as ShortCut
import Html exposing (..)
import Html.Attributes exposing (..)
import Util.HtmlUtil exposing (..)

import View.Styles as Styles

type alias Model =
  { editingEquipment : Maybe (String, String)
  }
type alias Id = String

init : Model
init =
  { editingEquipment = Nothing
  }

type Msg =
    NoOp
  | InputName Id String
  | KeydownOnNameInput Int

type Event =
    OnInput Id String
  | OnFinish Id String
  | None

update : ShortCut.Model -> Msg -> Model -> (Model, Event)
update keys message model =
  case message of
    NoOp ->
      (model, None)
    InputName id name ->
      let
        newModel =
          { model |
            editingEquipment =
              case model.editingEquipment of
                Just (id', name') ->
                  if id == id' then
                    Just (id, name)
                  else
                    Just (id', name')
                Nothing -> Nothing
          }
      in
        (newModel, OnInput id name)
    KeydownOnNameInput keyCode ->
      let
        (newModel, event) =
          if keyCode == 13 && not keys.ctrl then
            case model.editingEquipment of
              Just (id, name) ->
                (model, OnFinish id name)
              Nothing ->
                (model, None)
          else if keyCode == 13 then
            let
              newModel =
                { model |
                  editingEquipment =
                    case model.editingEquipment of
                      Just (id, name) -> Just (id, name ++ "\n")
                      Nothing -> Nothing
                }
            in
              (newModel, None)
          else
            (model, None)
      in
        (newModel, event)

updateNewEdit : (Maybe (String, String)) -> Model -> Model
updateNewEdit editingEquipment model =
  { model | editingEquipment = editingEquipment }

start : (String, String) -> Model -> Model
start = updateNewEdit << Just

forceFinish : Model -> (Model, Event)
forceFinish model =
  case model.editingEquipment of
    Just (id, name) ->
      (updateNewEdit Nothing model, OnFinish id name)
    Nothing ->
      (model, None)

view : (String -> Maybe (Int, Int, Int, Int)) -> Bool -> Model -> Html Msg
view screenRectOf transitionDisabled model =
  case model.editingEquipment of
    Just (id, name) ->
      case screenRectOf id of
        Just screenRect ->
          let
            styles =
              Styles.deskInput screenRect ++
              Styles.transition transitionDisabled
          in
            textarea
              ([ Html.Attributes.id "name-input"
              , style styles
              ] ++ (inputAttributes (InputName id) KeydownOnNameInput name (Just NoOp)))
              [text name]
        Nothing -> text ""
    Nothing ->
      text ""

-- TODO duplicated
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
