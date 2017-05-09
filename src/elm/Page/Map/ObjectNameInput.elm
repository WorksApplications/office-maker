port module Page.Map.ObjectNameInput exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Html.Keyed as Keyed
import Json.Decode as Decode
import Util.HtmlUtil exposing (..)
import Model.Person exposing (Person)
import View.Styles as Styles
import InlineHover exposing (hover)
import CoreType exposing (..)
import Page.Map.ProfilePopup as ProfilePopup
import Page.Map.Msg exposing (ObjectNameInputMsg(..))


type alias ObjectNameInput =
    { editingObject : Maybe ( String, String )
    , ctrl : Bool
    , shift : Bool
    , candidateIndex : Int
    , caretPosition : Int
    }


port insertInput : ( String, Int, ObjectId, String ) -> Cmd msg


port receiveInputValue : (( ObjectId, String, Int ) -> msg) -> Sub msg


init : ObjectNameInput
init =
    { editingObject = Nothing
    , ctrl = False
    , shift = False
    , candidateIndex = -1
    , caretPosition = 0
    }


type alias Msg =
    Page.Map.Msg.ObjectNameInputMsg


type Event
    = OnInput ObjectId String
    | OnFinish ObjectId String (Maybe PersonId)
    | OnSelectCandidate ObjectId PersonId
    | OnUnsetPerson ObjectId
    | None


isEditing : ObjectNameInput -> Bool
isEditing model =
    model.editingObject /= Nothing


update : Msg -> ObjectNameInput -> ( ObjectNameInput, Event )
update message model =
    case message of
        NoOperation ->
            ( model, None )

        CaretPosition caretPosition ->
            ( { model
                | caretPosition = caretPosition
              }
            , None
            )

        InputName id name caretPosition ->
            case model.editingObject of
                Just ( id_, name_ ) ->
                    if id == id_ then
                        ( { model
                            | editingObject = Just ( id, name )
                            , caretPosition = caretPosition
                          }
                        , OnInput id name
                        )
                    else
                        ( { model
                            | editingObject = Just ( id_, name_ )
                            , caretPosition = caretPosition
                          }
                        , None
                        )

                Nothing ->
                    ( { model
                        | editingObject = Nothing
                        , caretPosition = caretPosition
                      }
                    , None
                    )

        KeyupOnNameInput keyCode ->
            if keyCode == 16 then
                ( { model | shift = False }, None )
            else if keyCode == 17 then
                ( { model | ctrl = False }, None )
            else
                ( model, None )

        KeydownOnNameInput candidates ( keyCode, selectionStart ) ->
            let
                ( newModel, event ) =
                    if keyCode == 13 then
                        case model.editingObject of
                            Just ( objectId, name ) ->
                                ( updateNewEdit Nothing model
                                , OnFinish objectId name (selectedCandidateId model.candidateIndex candidates)
                                )

                            Nothing ->
                                ( model, None )
                    else if keyCode == 16 then
                        ( { model | shift = True }, None )
                    else if keyCode == 17 then
                        ( { model | ctrl = True }, None )
                    else
                        ( model, None )

                newModel2 =
                    if keyCode == 38 then
                        { newModel
                            | candidateIndex = Basics.max -1 (model.candidateIndex - 1)
                        }
                    else if keyCode == 40 then
                        { newModel
                            | candidateIndex = model.candidateIndex + 1
                        }
                    else
                        { newModel
                            | candidateIndex = -1
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


updateNewEdit : Maybe ( String, String ) -> ObjectNameInput -> ObjectNameInput
updateNewEdit editingObject model =
    { model | editingObject = editingObject }


start : ( String, String ) -> ObjectNameInput -> ObjectNameInput
start =
    updateNewEdit << Just


forceFinish : ObjectNameInput -> ( ObjectNameInput, Maybe ( ObjectId, String ) )
forceFinish model =
    case model.editingObject of
        Just ( objectId, name ) ->
            ( updateNewEdit Nothing model, Just ( objectId, name ) )

        Nothing ->
            ( model, Nothing )


insertText : (Msg -> msg) -> String -> ObjectNameInput -> Cmd msg
insertText toMsg text model =
    model.editingObject
        |> Maybe.map
            (\( objectId, name ) ->
                insertInput ( "name-input", model.caretPosition, objectId, text )
            )
        |> Maybe.withDefault Cmd.none


subscriptions : (Msg -> msg) -> Sub msg
subscriptions toMsg =
    receiveInputValue (\( objectId, value, caretPosition ) -> InputName objectId value caretPosition)
        |> Sub.map toMsg


view : (String -> Maybe ( Position, Size, Maybe Person, Bool )) -> List Person -> ObjectNameInput -> Html Page.Map.Msg.Msg
view deskInfoOf candidates model =
    model.editingObject
        |> Maybe.andThen
            (\( objectId, name ) ->
                deskInfoOf objectId
                    |> Maybe.map
                        (\( screenPosOfDesk, screenSizeOfDesk, maybePerson, showSuggestion ) ->
                            view_ showSuggestion objectId name maybePerson screenPosOfDesk screenSizeOfDesk candidates model
                        )
            )
        |> Maybe.withDefault (text "")


view_ : Bool -> ObjectId -> String -> Maybe Person -> Position -> Size -> List Person -> ObjectNameInput -> Html Page.Map.Msg.Msg
view_ showSuggestion objectId name maybePerson screenPosOfDesk screenSizeOfDesk candidates model =
    let
        candidates_ =
            candidates
                |> List.take 15
                |> List.filter (\candidate -> Just candidate /= maybePerson)
    in
        Keyed.node "div"
            [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed Page.Map.Msg.NoOp)
            , onWithOptions "mousemove" { stopPropagation = True, preventDefault = False } (Decode.succeed Page.Map.Msg.NoOp)
            ]
            (( "nameInput" ++ objectId
             , input
                [ Html.Attributes.id "name-input"
                , style (Styles.nameInputTextArea screenPosOfDesk screenSizeOfDesk)
                , onInput_ objectId
                , on "click" (Decode.map CaretPosition targetSelectionStart)
                , onWithOptions "keydown" { stopPropagation = True, preventDefault = False } (Decode.map (KeydownOnNameInput candidates_) decodeKeyCodeAndSelectionStart)
                , onWithOptions "keyup" { stopPropagation = True, preventDefault = False } (Decode.map KeyupOnNameInput decodeKeyCode)
                , defaultValue name
                ]
                []
                |> Html.map tagger
             )
                :: (if showSuggestion then
                        viewSuggestion objectId maybePerson screenPosOfDesk screenSizeOfDesk candidates_ model
                    else
                        []
                   )
            )


tagger =
    Page.Map.Msg.ObjectNameInputMsg


viewSuggestion : String -> Maybe Person -> Position -> Size -> List Person -> ObjectNameInput -> List ( String, Html Page.Map.Msg.Msg )
viewSuggestion objectId maybePerson screenPosOfDesk screenSizeOfDesk candidates model =
    let
        ( relatedPersonExists, reletedpersonView_ ) =
            maybePerson
                |> Maybe.map
                    (\person ->
                        ( True, Lazy.lazy3 reletedpersonView tagger objectId person )
                    )
                |> Maybe.withDefault ( False, text "" )

        candidatesLength =
            List.length candidates

        viewExists =
            relatedPersonExists || candidatesLength > 0

        pointer =
            if viewExists then
                div [ style (Styles.candidateViewPointer screenPosOfDesk screenSizeOfDesk) ] []
            else
                text ""
    in
        [ ( "name-input-suggestion"
          , div
                [ style (Styles.candidatesViewContainer screenPosOfDesk screenSizeOfDesk relatedPersonExists candidatesLength) ]
                [ reletedpersonView_
                , Html.map tagger (candidatesView model.candidateIndex objectId candidates)
                ]
          )
        , ( "pointer", pointer )
        ]


onInput_ : String -> Attribute Msg
onInput_ objectId =
    onWithOptions
        "input"
        { stopPropagation = True, preventDefault = True }
        decodeTargetValueAndSelectionStart
        |> Html.Attributes.map (\( value, pos ) -> InputName objectId value pos)


reletedpersonView : (Msg -> Page.Map.Msg.Msg) -> ObjectId -> Person -> Html Page.Map.Msg.Msg
reletedpersonView tagger objectId person =
    div
        [ style (Styles.candidatesViewRelatedPerson) ]
        (Html.map tagger (Lazy.lazy unsetButton objectId) :: ProfilePopup.personView Nothing objectId person)


unsetButton : ObjectId -> Html Msg
unsetButton objectId =
    hover Styles.unsetRelatedPersonButtonHover
        div
        [ onClick (UnsetPerson objectId)
        , style Styles.unsetRelatedPersonButton
        ]
        [ text "Unset" ]


candidatesView : Int -> ObjectId -> List Person -> Html Msg
candidatesView candidateIndex objectId people =
    if List.isEmpty people then
        text ""
    else
        Keyed.ul
            [ style (Styles.candidatesView) ]
            (List.indexedMap (candidatesViewEach candidateIndex objectId) people)


candidatesViewEach : Int -> ObjectId -> Int -> Person -> ( String, Html Msg )
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
