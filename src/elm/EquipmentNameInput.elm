module EquipmentNameInput exposing (..)

import Util.ShortCut as ShortCut
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Util.HtmlUtil exposing (..)
import Model.Person exposing (Person)

import View.Styles as Styles
import View.ProfilePopup as ProfilePopup

import InlineHover exposing (hover)

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
  | SelectCandidate Id Id

type Event =
    OnInput Id String
  | OnFinish Id String
  | OnSelectCandidate Id Id
  | None

isEditing : Model -> Bool
isEditing model =
  model.editingEquipment /= Nothing

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
    SelectCandidate equipmentId personId ->
      ( { model | editingEquipment = Nothing }
      , OnSelectCandidate equipmentId personId
      )

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

view : (String -> Maybe (Int, Int, Int, Int)) -> Bool -> List Person -> Model -> Html Msg
view screenRectOf transitionDisabled candidates model =
  case model.editingEquipment of
    Just (id, name) ->
      case screenRectOf id of
        Just screenRect ->
          let
            styles =
              Styles.deskInput screenRect ++
              Styles.transition transitionDisabled
          in
            div
              [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
              , onWithOptions "mousemove" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
              ]
              [ textarea
                ([ Html.Attributes.id "name-input"
                , style styles
                ] ++ (inputAttributes (InputName id) KeydownOnNameInput name))
                [ text name ]
              , candidatesView id screenRect candidates
              -- TODO popup pointer here
              ]
        Nothing -> text ""
    Nothing ->
      text ""

candidatesView : Id -> (Int, Int, Int, Int) -> List Person -> Html Msg
candidatesView equipmentId screenRectOfDesk people =
  case people of
    [] -> text ""
    _ ->
      let
        (x, y, w, h) = screenRectOfDesk
        left = x + w + 10
        top = Basics.max 10 <| y - (160 * List.length people) // 2
        each person =
          hover Styles.hovarableHover
          li
            [ style Styles.candidateItem
            , onMouseDown' (SelectCandidate equipmentId person.id)
            ]
            (ProfilePopup.innerView Nothing person)
      in
        ul
          [ style (Styles.ul ++ Styles.candidatesView (left, top))
          ]
          (List.map each people)

-- TODO duplicated
inputAttributes : (String -> msg) -> (Int -> msg) -> String -> List (Attribute msg)
inputAttributes toInputMsg toKeydownMsg value' =
  [ onInput' toInputMsg
  , onKeyDown'' toKeydownMsg
  , value value'
  ]
