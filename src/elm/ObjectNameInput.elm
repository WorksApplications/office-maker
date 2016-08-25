module ObjectNameInput exposing (..)

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
  { editingObject : Maybe (String, String)
  , ctrl : Bool
  , shift : Bool
  , candidateIndex : Int
  }

type alias Id = String

init : Model
init =
  { editingObject = Nothing
  , ctrl = False
  , shift = False
  , candidateIndex = -1
  }

type Msg =
    NoOp
  | InputName Id String
  | KeydownOnNameInput (List Person) (Int, Int)
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
  model.editingObject /= Nothing


update : Msg -> Model -> (Model, Event)
update message model =
  case message of
    NoOp ->
      (model, None)

    InputName id name ->
      case model.editingObject of
        Just (id', name') ->
          if id == id' then
            ({ model |
              editingObject = Just (id, name)
            }, OnInput id name)
          else
            ({ model |
              editingObject = Just (id', name')
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
              Just (id, name) ->
                ( updateNewEdit Nothing model
                , OnFinish id name (selectedCandidateId model.candidateIndex candidates)
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


selectedCandidateId : Int -> List Person -> Maybe Id
selectedCandidateId candidateIndex candidates =
  if candidateIndex < 0 then
    Nothing
  else
    Maybe.map (.id) <|
      List.head (List.drop candidateIndex candidates)


updateNewEdit : (Maybe (String, String)) -> Model -> Model
updateNewEdit editingObject model =
  { model | editingObject = editingObject }


start : (String, String) -> Model -> Model
start =
  updateNewEdit << Just


forceFinish : Model -> (Model, Maybe (Id, String))
forceFinish model =
  case model.editingObject of
    Just (id, name) ->
      (updateNewEdit Nothing model, Just (id, name))

    Nothing ->
      (model, Nothing)


view : (String -> Maybe ((Int, Int, Int, Int), Maybe Person)) -> Bool -> List Person -> Model -> Html Msg
view deskInfoOf transitionDisabled candidates model =
  case model.editingObject of
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
      List.filter (\candidate -> Just candidate /= maybePerson) (List.take 15 candidates)

    (relatedPersonExists, reletedpersonView') =
      case maybePerson of
        Just person ->
          (True, reletedpersonView id person)
        Nothing ->
          (False, text "")

    candidatesLength =
      List.length candidates'

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
      [ ("nameInput" ++ id, input
        ([ Html.Attributes.id "name-input"
        -- , Html.Attributes.property "selectionStart" (Encode.int 9999)
        -- , Html.Attributes.attribute "selection-start" "9999"
        , style (Styles.nameInputTextArea transitionDisabled screenRectOfDesk)
        ] ++ (inputAttributes (InputName id) (KeydownOnNameInput candidates') KeyupOnNameInput name))
        [ ])
      , ("candidatesViewContainer", div
          [ style (Styles.candidatesViewContainer screenRectOfDesk relatedPersonExists candidatesLength) ]
          [ reletedpersonView'
          , candidatesView model.candidateIndex id candidates'
          ])
      , ("pointer", pointer)
      ]


reletedpersonView : Id -> Person -> Html Msg
reletedpersonView objectId person =
  div
    [ style (Styles.candidatesViewRelatedPerson) ]
    ( unsetButton objectId :: ProfilePopup.innerView Nothing person )


unsetButton : Id -> Html Msg
unsetButton objectId =
  -- hover Styles.unsetRelatedPersonButtonHover
  div
    [ onClick (UnsetPerson objectId)
    , style Styles.unsetRelatedPersonButton
    ]
    [ text "Unset"]


candidatesView : Int -> Id -> List Person -> Html Msg
candidatesView candidateIndex objectId people =
  case people of
    [] -> text ""
    _ ->
      Keyed.ul
        [ style (Styles.candidatesView) ]
        (List.indexedMap (candidatesViewEach candidateIndex objectId) people)


candidatesViewEach : Int -> Id -> Int -> Person -> (String, Html Msg)
candidatesViewEach candidateIndex objectId index person =
  ( person.id
  ,
  -- hover Styles.candidateItemHover
    li
      [ style (Styles.candidateItem (candidateIndex == index))
      , onMouseDown' (SelectCandidate objectId person.id)
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
inputAttributes : (String -> msg) -> ((Int, Int) -> msg) -> (Int -> msg) -> String -> List (Attribute msg)
inputAttributes toInputMsg toKeydownMsg toKeyupMsg value' =
  [ onInput' toInputMsg
  -- , autofocus True
  , onWithOptions "keydown" { stopPropagation = True, preventDefault = False } (Decode.map toKeydownMsg decodeKeyCodeAndSelectionStart)
  , onWithOptions "keyup" { stopPropagation = True, preventDefault = False } (Decode.map toKeyupMsg decodeKeyCode)
  , defaultValue value'
  -- , value value'
  ]
