port module Component.ObjectNameInput exposing (..)

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
  , caretPosition : Int
  }


type alias ObjectId = String
type alias PersonId = String


port insertInput : (String, Int, ObjectId, String) -> Cmd msg
port receiveInputValue : ((ObjectId, String, Int) -> msg) -> Sub msg


init : ObjectNameInput
init =
  { editingObject = Nothing
  , ctrl = False
  , shift = False
  , candidateIndex = -1
  , caretPosition = 0
  }


type Msg
  = NoOp
  | CaretPosition Int
  | InputName ObjectId String Int
  | KeydownOnNameInput (List Person) (Int, Int)
  | KeyupOnNameInput Int
  | SelectCandidate ObjectId PersonId
  | UnsetPerson ObjectId


type Event
  = OnInput ObjectId String
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

    CaretPosition caretPosition ->
      ({ model
        | caretPosition = caretPosition
      }, None)

    InputName id name caretPosition ->
      case model.editingObject of
        Just (id_, name_) ->
          if id == id_ then
            ({ model
              | editingObject = Just (id, name)
              , caretPosition = caretPosition
            }, OnInput id name)
          else
            ({ model
              | editingObject = Just (id_, name_)
              , caretPosition = caretPosition
            }, None)

        Nothing ->
            ({ model
              | editingObject = Nothing
              , caretPosition = caretPosition
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

        newModel2 =
          if keyCode == 38 then
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
      in
        ( { newModel2 | caretPosition = selectionStart }, event )

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
   model.editingObject
     |> Maybe.map (\(objectId, name) ->
       insertInput ("name-input", model.caretPosition, objectId, text)
     )
     |> Maybe.withDefault Cmd.none


subscriptions : (Msg -> msg) -> Sub msg
subscriptions toMsg =
   receiveInputValue (\(objectId, value, caretPosition) -> InputName objectId value caretPosition)
     |> Sub.map toMsg


view : (String -> Maybe ((Int, Int, Int, Int), Maybe Person, Bool)) -> Bool -> List Person -> ObjectNameInput -> Html Msg
view deskInfoOf transitionDisabled candidates model =
  model.editingObject
    |> Maybe.andThen (\(objectId, name) -> deskInfoOf objectId
    |> Maybe.map (\(screenRect, maybePerson, showSuggestion) ->
      view_ showSuggestion objectId name maybePerson screenRect transitionDisabled candidates model
    ))
    |> Maybe.withDefault (text "")


view_ : Bool -> ObjectId -> String -> Maybe Person -> (Int, Int, Int, Int) -> Bool -> List Person -> ObjectNameInput -> Html Msg
view_ showSuggestion objectId name maybePerson screenRectOfDesk transitionDisabled candidates model =
  let
    candidates_ =
      candidates
        |> List.take 15
        |> List.filter (\candidate -> Just candidate /= maybePerson)
  in
    Keyed.node "div"
      [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
      , onWithOptions "mousemove" { stopPropagation = True, preventDefault = False } (Decode.succeed NoOp)
      ]
      ([ ("nameInput" ++ objectId, input
        ([ Html.Attributes.id "name-input"
        , style (Styles.nameInputTextArea transitionDisabled screenRectOfDesk)
        , onInput_ objectId
        , on "click" (Decode.map CaretPosition targetSelectionStart)
        , onWithOptions "keydown" { stopPropagation = True, preventDefault = False } (Decode.map (KeydownOnNameInput candidates_) decodeKeyCodeAndSelectionStart)
        , onWithOptions "keyup" { stopPropagation = True, preventDefault = False } (Decode.map KeyupOnNameInput decodeKeyCode)
        , defaultValue name
        ])
        [])
      ] ++ (if showSuggestion then viewSuggestion objectId maybePerson screenRectOfDesk candidates_ model else []))


viewSuggestion : String -> Maybe Person -> (Int, Int, Int, Int) -> List Person -> ObjectNameInput -> List (String, Html Msg)
viewSuggestion objectId maybePerson screenRectOfDesk candidates model =
  let
    (relatedPersonExists, reletedpersonView_) =
      maybePerson
        |> Maybe.map (\person ->
            (True, Lazy.lazy2 reletedpersonView objectId person)
        )
        |> Maybe.withDefault (False, text "")

    candidatesLength =
      List.length candidates

    viewExists =
      relatedPersonExists || candidatesLength > 0

    pointer =
      if viewExists then
        div [ style (Styles.candidateViewPointer screenRectOfDesk) ] []
      else
        text ""
  in
    [ ("name-input-suggestion"
      , div
        [ style (Styles.candidatesViewContainer screenRectOfDesk relatedPersonExists candidatesLength) ]
        [ reletedpersonView_
        , candidatesView model.candidateIndex objectId candidates
        ]
      )
    , ("pointer", pointer)
    ]


onInput_ : String -> Attribute Msg
onInput_ objectId =
  onWithOptions
    "input"
    { stopPropagation = True, preventDefault = True }
    decodeTargetValueAndSelectionStart
      |> Html.Attributes.map (\(value, pos) -> InputName objectId value pos)


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
