module Header exposing (..)

import Task exposing (Task)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Model.Person exposing (..)
import Model.User as User exposing (..)
import Model.API as API

import View.Styles as Styles
import View.Icons as Icons

import InlineHover exposing (hover)

type Msg =
    Login
  | Logout
  | LogoutSuccess
  | ToggleEditing
  | TogglePrintView Bool
  | NoOp

type Event =
    LogoutDone
  | None
  | OnToggleEditing
  | OnTogglePrintView Bool

update : Msg -> (Cmd Msg, Event)
update action =
  case action of
    NoOp ->
      (Cmd.none, None)
    ToggleEditing ->
      (Cmd.none, OnToggleEditing)
    TogglePrintView opened ->
      (Cmd.none, OnTogglePrintView opened)
    Login ->
      (Task.perform (always NoOp) (always NoOp) API.goToLogin, None)
    Logout ->
      (Task.perform (always LogoutSuccess) (always LogoutSuccess) API.logout, None)--TODO
    LogoutSuccess ->
      (Cmd.none, LogoutDone)

view : Maybe (User, Bool) -> Html Msg
view maybeContext =
  header
    [ style Styles.header ]
    [ h1 [ style Styles.h1 ] [text "Office Maker" ]
    , normalMenu maybeContext
    ]

viewPrintMode : String -> Html Msg
viewPrintMode title =
  header
    [ style Styles.header ]
    [ h1 [ style Styles.h1 ] [text title ]
    , menu [ printButtonView True ]
    ]

normalMenu : Maybe (User, Bool) -> Html Msg
normalMenu maybeContext =
  menu <|
    case maybeContext of
      Just (user, editing) ->
        editingToggle user editing ::
        printButton user ::
        greeting user ::
        (if user == Guest then login else logout) ::
        []
      Nothing ->
        []

menu : List (Html Msg) -> Html Msg
menu children =
  div [ style Styles.headerMenu ] children

editingToggle : User -> Bool -> Html Msg
editingToggle user editing =
  if User.isGuest user then
    text ""
  else
    editingToggleView editing

printButton : User -> Html Msg
printButton user =
  if User.isGuest user then
    text ""
  else
    printButtonView False


login : Html Msg
login =
  div [ style Styles.login, onClick Login ] [ text "Sign in" ]

logout : Html Msg
logout =
  div [ style Styles.logout, onClick Logout ] [ text "Sign out" ]


printButtonView : Bool -> Html Msg
printButtonView showingPrint =
  -- iconView ToggleEditing (Icons.editingToggle False) "Print"
  hover Styles.hoverHeaderIconHover
  div
    [ onClick (TogglePrintView (not showingPrint))
    , style (Styles.editingToggleContainer False)
    ]
    [ div [ style Styles.editingToggleIcon ] [ Icons.printButton ]
    , div [ style (Styles.editingToggleText) ] [ text (if showingPrint then "Close" else "Print") ]
    ]

editingToggleView : Bool -> Html Msg
editingToggleView editing =
  -- iconView ToggleEditing (Icons.editingToggle editing) "Edit"
  hover Styles.hoverHeaderIconHover
  div
    [ onClick ToggleEditing
    , style (Styles.editingToggleContainer editing)
    ]
    [ div [ style Styles.editingToggleIcon ] [ Icons.editingToggle ]
    , div [ style (Styles.editingToggleText) ] [ text "Edit" ]
    ]

-- iconView : msg -> Html msg -> String -> Html msg
-- iconView onClickMessage icon text_ =
--   div
--     [ onClick onClickMessage
--     , style (Styles.editingToggleContainer)
--     ]
--     [ div [ style Styles.editingToggleIcon ] [ icon ]
--     , div [ style (Styles.editingToggleText editing) ] [ text text_ ]
--     ]


greeting : User -> Html msg
greeting user =
  case user of
    Guest ->
      text ""
    Admin person ->
      greetingForPerson person
    General person ->
      greetingForPerson person

greetingForPerson : Person -> Html msg
greetingForPerson person =
  let
    image =
      case person.image of
        Just url ->
          img [ style Styles.greetingImage, src url ] []
        Nothing ->
          text ""
  in
    div
      [ style Styles.greetingContainer ]
      [ image
      , div [ style Styles.greetingName ] [ text person.name ]
      ]

userName : User -> String
userName user =
  case user of
    Admin person -> person.name
    General person -> person.name
    Guest -> "Guest"
