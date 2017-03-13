module Component.ObjectNameInput exposing (..)

import Task

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Html.Keyed as Keyed

import Json.Decode as Decode
import Util.HtmlUtil exposing (..)

import Model.Person exposing (Person)

import View.Styles as Styles
import View.ProfilePopup as ProfilePopup

import InlineHover exposing (hover)

type alias ObjectNameInput =
  { editingObject : Maybe (String, String)
  , ctrl : Bool
  , shift : Bool
  , candidateIndex : Int
  }


type alias ObjectId = String
type alias PersonId = String


init : ObjectNameInput
init =
  { editingObject = Nothing
  , ctrl = False
  , shift = False
  , candidateIndex = -1
  }


type Msg =
    NoOp
  | InputName ObjectId String
  | KeydownOnNameInput (List Person) (Int, Int)
  | KeyupOnNameInput Int
  | SelectCandidate ObjectId PersonId
  | UnsetPerson ObjectId


type Event =
    OnInput ObjectId String
  | OnFinish ObjectId String (Maybe PersonId)
  | OnSelectCandidate ObjectId PersonId
  | OnUnsetPerson ObjectId
  | None


isEditing : ObjectNameInput -> Bool
isEditing model =
  model.editingObject /= Nothing


update : Msg -> ObjectNameInput -> (ObjectNameInput, Event)
update message model =
  case message of
    NoOp ->
      (model, None)

    InputName id name ->
      case model.editingObject of
        Just (id_, name_) ->
          if id == id_ then
            ({ model |
              editingObject = Just (id, name)
            }, OnInput id name)
          else
            ({ model |
              editingObject = Just (id_, name_)
            }, None)

        Nothing ->
            ({ model |
              editingObject = Nothing
            }, None)

    KeyupOnNameInput keyCode ->
      if keyCode == 16 then
        ({ model | shift = False }, None)
      else if keyCode == 17 then
        ({ model | ctrl = False }, None)
      else
        (model, None)

    KeydownOnNameInput candidates (keyCode, selectionStart) ->
      let
        (newModel, event) =
          if keyCode == 13 then
            case model.editingObject of
              Just (objectId, name) ->
                ( updateNewEdit Nothing model
                , OnFinish objectId name (selectedCandidateId model.candidateIndex candidates)
                )

              Nothing ->
                (model, None)
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

    SelectCandidate objectId personId ->
      ( { model | editingObject = Nothing }
      , OnSelectCandidate objectId personId
      )

    UnsetPerson objectId ->
      ( model, OnUnsetPerson objectId )


selectedCandidateId : Int -> List Person -> Maybe PersonId
selectedCandidateId candidateIndex candidates =
  if candidateIndex < 0 then
    Nothing
  else
    candidates
      |> List.drop candidateIndex
      |> List.head
      |> Maybe.map .id


updateNewEdit : (Maybe (String, String)) -> ObjectNameInput -> ObjectNameInput
updateNewEdit editingObject model =
  { model | editingObject = editingObject }


start : (String, String) -> ObjectNameInput -> ObjectNameInput
start =
  updateNewEdit << Just


forceFinish : ObjectNameInput -> (ObjectNameInput, Maybe (ObjectId, String))
forceFinish model =
  case model.editingObject of
    Just (objectId, name) ->
      (updateNewEdit Nothing model, Just (objectId, name))

    Nothing ->
      (model, Nothing)


insertText : (Msg -> msg) -> String -> ObjectNameInput -> Cmd msg
insertText toMsg text model =
  case model.editingObject of
    Just (objectId, name) ->
      InputName objectId (name ++ text)
        |> Task.succeed
        |> Task.perform toMsg

    Nothing ->
      Cmd.none


view : (String -> Maybe ((Int, Int, Int, Int), Maybe Person)) -> Bool -> List Person -> ObjectNameInput -> Html Msg
view deskInfoOf transitionDisabled candidates model =
  case model.editingObject of
    Just (objectId, name) ->
      case deskInfoOf objectId of
        Just (screenRect, maybePerson) ->
          view_ objectId name maybePerson screenRect transitionDisabled candidates model

        Nothing -> text ""

    Nothing ->
      text ""


view_ : ObjectId -> String -> Maybe Person -> (Int, Int, Int, Int) -> Bool -> List Person -> ObjectNameInput -> Html Msg
view_ objectId name maybePerson screenRectOfDesk transitionDisabled candidates model =
  let
    candidates_ =
      List.filter (\candidate -> Just candidate /= maybePerson) (List.take 15 candidates)

    (relatedPersonExists, reletedpersonView_) =
      case maybePerson of
        Just person ->
          (True, Lazy.lazy2 reletedpersonView objectId person)

        Nothing ->
          (False, text "")

    candidatesLength =
      List.length candidates_

    viewExists =
      relatedPersonExists || candidatesLength > 0

    pointer =
      if viewExists then
        div [ style (Styles.candidateViewPointer screenRectOfDesk) ] []
      else
        text ""
  in
    -- this is a workaround for unexpectedly remaining input.defaultValue
    Keyed.node "div"
      [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
      , onWithOptions "mousemove" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
      ]
      [ ("nameInput" ++ objectId, input
        ([ Html.Attributes.id "name-input"
        -- , Html.Attributes.property "selectionStart" (Encode.int 9999)
        -- , Html.Attributes.attribute "selection-start" "9999"
        , style (Styles.nameInputTextArea transitionDisabled screenRectOfDesk)
        ] ++ (inputAttributes (InputName objectId) (KeydownOnNameInput candidates_) KeyupOnNameInput name))
        [ ])
      , ("candidatesViewContainer", div
          [ style (Styles.candidatesViewContainer screenRectOfDesk relatedPersonExists candidatesLength) ]
          [ reletedpersonView_
          , candidatesView model.candidateIndex objectId candidates_
          ])
      , ("pointer", pointer)
      ]


reletedpersonView : ObjectId -> Person -> Html Msg
reletedpersonView objectId person =
  div
    [ style (Styles.candidatesViewRelatedPerson) ]
    ( Lazy.lazy unsetButton objectId :: ProfilePopup.innerView Nothing person )


unsetButton : ObjectId -> Html Msg
unsetButton objectId =
  hover Styles.unsetRelatedPersonButtonHover
  div
    [ onClick (UnsetPerson objectId)
    , style Styles.unsetRelatedPersonButton
    ]
    [ text "Unset"]


candidatesView : Int -> ObjectId -> List Person -> Html Msg
candidatesView candidateIndex objectId people =
  if List.isEmpty people then
    text ""
  else
    Keyed.ul
      [ style (Styles.candidatesView) ]
      (List.indexedMap (candidatesViewEach candidateIndex objectId) people)


candidatesViewEach : Int -> ObjectId -> Int -> Person -> (String, Html Msg)
candidatesViewEach candidateIndex objectId index person =
  ( person.id
  , hover Styles.candidateItemHover
      li
        [ style (Styles.candidateItem (candidateIndex == index))
        , onMouseDown_ (SelectCandidate objectId person.id)
        ]
        [ div [ style Styles.candidateItemPersonName ] [ text person.name ]
        , mail person
        , div [ style Styles.candidateItemPersonPost ] [ text person.post ]
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
inputAttributes : (String -> msg) -> ((Int, Int) -> msg) -> (Int -> msg) -> String -> List (Attribute msg)
inputAttributes toInputMsg toKeydownMsg toKeyupMsg value_ =
  [ onInput_ toInputMsg
  -- , autofocus True
  , onWithOptions "keydown" { stopPropagation = True, preventDefault = False } (Decode.map toKeydownMsg decodeKeyCodeAndSelectionStart)
  , onWithOptions "keyup" { stopPropagation = True, preventDefault = False } (Decode.map toKeyupMsg decodeKeyCode)
  , defaultValue value_
  -- , value value_
  ]
