module Header exposing (..) -- where

import Task exposing (Task)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Model.Person exposing (..)
import Model.User as User exposing (..)
import Model.API as API

import View.Styles as Styles
import View.Icons as Icons

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
    , menu maybeContext
    ]

menu : Maybe (User, Bool) -> Html Msg
menu maybeContext =
  case maybeContext of
    Just (user, editing) ->
      let
        editingToggle =
          if User.isGuest user then
            text ""
          else
            editingToggleView editing
        printButton =
          if User.isGuest user then
            text ""
          else
            printButtonView
        login =
          div [ style Styles.login, onClick Login ] [ text "Sign in" ]
        logout =
          div [ style Styles.logout, onClick Logout ] [ text "Sign out" ]
        children =
          editingToggle :: printButton :: greeting user ::
            ( case user of
                Admin _ -> [ logout ]
                General _ -> [ logout ]
                Guest -> [ login ]
            )
      in
        div [ style Styles.headerMenu ] children
    Nothing -> text ""


printButtonView : Html Msg
printButtonView =
  -- iconView ToggleEditing (Icons.editingToggle False) "Print"
  div
    [ onClick (TogglePrintView True)
    , style (Styles.editingToggleContainer False)
    , class "hover-header-icon"
    ]
    [ div [ style Styles.editingToggleIcon ] [ Icons.printButton ]
    , div [ style (Styles.editingToggleText) ] [ text "Print" ]
    ]

editingToggleView : Bool -> Html Msg
editingToggleView editing =
  -- iconView ToggleEditing (Icons.editingToggle editing) "Edit"
  div
    [ onClick ToggleEditing
    , style (Styles.editingToggleContainer editing)
    , class "hover-header-icon"
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
