module EquipmentNameInput exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed

import Json.Decode as Decode
import Util.HtmlUtil exposing (..)
import Model.Person exposing (Person)

import View.Styles as Styles
import View.ProfilePopup as ProfilePopup

import InlineHover exposing (hover)

type alias Model =
  { editingEquipment : Maybe (String, String)
  , ctrl : Bool
  , shift : Bool
  , candidateIndex : Int
  }
type alias Id = String

init : Model
init =
  { editingEquipment = Nothing
  , ctrl = False
  , shift = False
  , candidateIndex = -1
  }

type Msg =
    NoOp
  | InputName Id String
  | KeydownOnNameInput (List Person) Int
  | KeyupOnNameInput Int
  | SelectCandidate Id Id
  | UnsetPerson Id

type Event =
    OnInput Id String
  | OnFinish Id String (Maybe Id)
  | OnSelectCandidate Id Id
  | OnUnsetPerson Id
  | None

isEditing : Model -> Bool
isEditing model =
  model.editingEquipment /= Nothing

update : Msg -> Model -> (Model, Event)
update message model =
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
    KeyupOnNameInput keyCode ->
      if keyCode == 16 then
        ({ model | shift = False }, None)
      else if keyCode == 17 then
        ({ model | ctrl = False }, None)
      else
        (model, None)
    KeydownOnNameInput candidates keyCode ->
      let
        -- _ = Debug.log "keyCode" keyCode
        (newModel, event) =
          if keyCode == 13 && not model.ctrl then
            case model.editingEquipment of
              Just (id, name) ->
                ( updateNewEdit Nothing model
                , OnFinish id name (selectedCandidateId model.candidateIndex candidates)
                )
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
          else if keyCode == 16 then
            ({ model | shift = True }, None)
          else if keyCode == 17 then
            ({ model | ctrl = True }, None)
          else
            (model, None)
      in
        ( if keyCode == 38 then
            { newModel |
              candidateIndex = Basics.max -1 (model.candidateIndex - 1)
            }
          else if keyCode == 40 then
            { newModel |
              candidateIndex = model.candidateIndex + 1
            }
          else
            { newModel |
              candidateIndex = -1
            }
        , event )
    SelectCandidate equipmentId personId ->
      ( { model | editingEquipment = Nothing }
      , OnSelectCandidate equipmentId personId
      )
    UnsetPerson equipmentId ->
      ( model, OnUnsetPerson equipmentId )

selectedCandidateId : Int -> List Person -> Maybe Id
selectedCandidateId candidateIndex candidates =
  if candidateIndex < 0 then
    Nothing
  else
    Maybe.map (.id) <|
      List.head (List.drop candidateIndex candidates)


updateNewEdit : (Maybe (String, String)) -> Model -> Model
updateNewEdit editingEquipment model =
  { model | editingEquipment = editingEquipment }

start : (String, String) -> Model -> Model
start = updateNewEdit << Just

forceFinish : Model -> (Model, Maybe (Id, String))
forceFinish model =
  case model.editingEquipment of
    Just (id, name) ->
      (updateNewEdit Nothing model, Just (id, name))
    Nothing ->
      (model, Nothing)

view : (String -> Maybe ((Int, Int, Int, Int), Maybe Person)) -> Bool -> List Person -> Model -> Html Msg
view deskInfoOf transitionDisabled candidates model =
  case model.editingEquipment of
    Just (id, name) ->
      case deskInfoOf id of
        Just (screenRect, maybePerson) ->
          view' id name maybePerson screenRect transitionDisabled candidates model
        Nothing -> text ""
    Nothing ->
      text ""

view' : Id -> String -> Maybe Person -> (Int, Int, Int, Int) -> Bool -> List Person -> Model -> Html Msg
view' id name maybePerson screenRectOfDesk transitionDisabled candidates model =
  let
    candidates' =
      List.filter (\candidate -> Just candidate /= maybePerson) (List.take 20 candidates)
    reletedpersonView' =
      case maybePerson of
        Just person ->
          reletedpersonView id person
        Nothing ->
          text ""
    (x, y, w, h) = screenRectOfDesk
    left = x + w + 10
    top = Basics.max 10 <| y - (160 * List.length candidates') // 2
  in
    div
      [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
      , onWithOptions "mousemove" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
      ]
      [ textarea
        ([ Html.Attributes.id "name-input"
        , style (Styles.nameInputTextArea transitionDisabled screenRectOfDesk)
        ] ++ (inputAttributes (InputName id) (KeydownOnNameInput candidates') KeyupOnNameInput name))
        [ text name ]
      , div
          [ style (Styles.candidatesViewContainer (left, top)) ]
          [ reletedpersonView'
          , candidatesView model.candidateIndex id candidates'
          ]
      -- TODO popup pointer here
      ]


reletedpersonView : Id -> Person -> Html Msg
reletedpersonView equipmentId person =
  div
    [ style (Styles.candidatesViewRelatedPerson) ]
    ( unsetButton equipmentId :: ProfilePopup.innerView Nothing person )


unsetButton : Id -> Html Msg
unsetButton equipmentId =
  hover Styles.unsetRelatedPersonButtonHover div
    [ onClick (UnsetPerson equipmentId)
    , style Styles.unsetRelatedPersonButton
    ]
    [ text "Unset"]


candidatesView : Int -> Id -> List Person -> Html Msg
candidatesView candidateIndex equipmentId people =
  case people of
    [] -> text ""
    _ ->
      Keyed.ul
        [ style (Styles.ul ++ Styles.candidatesView)
        ]
        (List.indexedMap (candidatesViewEach candidateIndex equipmentId) people)


candidatesViewEach : Int -> Id -> Int -> Person -> (String, Html Msg)
candidatesViewEach candidateIndex equipmentId index person =
  ( person.id
  , hover Styles.candidateItemHover li
      [ style (Styles.candidateItem (candidateIndex == index))
      , onMouseDown' (SelectCandidate equipmentId person.id)
      ]
      [ div [ style Styles.candidateItemPersonName ] [ text person.name ]
      , mail person
      , div [ style Styles.candidateItemPersonOrg ] [ text person.org ]
      ]
  )


mail : Person -> Html msg
mail person =
  div
    [ style Styles.candidateItemPersonMail ]
    [ div
        [ style Styles.personDetailPopupPersonIconText ]
        [ text (Maybe.withDefault "" person.mail) ]
    ]


-- TODO duplicated
inputAttributes : (String -> msg) -> (Int -> msg) -> (Int -> msg) -> String -> List (Attribute msg)
inputAttributes toInputMsg toKeydownMsg toKeyupMsg value' =
  [ onInput' toInputMsg
  , onWithOptions "keydown" { stopPropagation = True, preventDefault = False } (Decode.map toKeydownMsg decodeKeyCode)
  , onWithOptions "keyup" { stopPropagation = True, preventDefault = False } (Decode.map toKeyupMsg decodeKeyCode)
  , value value'
  ]
