module Header exposing (..) -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model.User as User exposing (..)
import Model.API as API
import Task exposing (Task)

import View.Styles as Styles
import View.Icons as Icons

type Msg =
    Login
  | Logout
  | LogoutSuccess
  | ToggleEditing
  | NoOp

type Event =
    LogoutDone
  | None
  | OnToggleEditing

update : Msg -> (Cmd Msg, Event)
update action =
  case action of
    NoOp ->
      (Cmd.none, None)
    ToggleEditing ->
      (Cmd.none, OnToggleEditing)
    Login ->
      (Task.perform (always NoOp) (always NoOp) API.goToLogin, None)
    Logout ->
      (Task.perform (always LogoutSuccess) (always LogoutSuccess) API.logout, None)--TODO
    LogoutSuccess ->
      (Cmd.none, LogoutDone)

view : Maybe (User, Bool) -> Html Msg
view maybeContext =
  let
    menu =
      case maybeContext of
        Just (user, editing) ->
          let
            editingToggle =
              if User.isGuest user then
                text ""
              else
                editingToggleView editing
            login =
              div [ style Styles.login, onClick Login ] [ text "Sign in" ]
            logout =
              div [ style Styles.logout, onClick Logout ] [ text "Sign out" ]
            children =
              editingToggle :: greeting user ::
                ( case user of
                    Admin _ -> [ logout ]
                    General _ -> [ logout ]
                    Guest -> [ login ]
                )
          in
            div [ style Styles.headerMenu ] children
        Nothing -> text ""
  in
    header
      [ style Styles.header ]
      [ h1 [ style Styles.h1 ] [text "Office Maker" ]
      , menu
      ]


editingToggleView : Bool -> Html Msg
editingToggleView editing =
  div
    [ onClick ToggleEditing
    , style (Styles.editingToggleContainer)
    ]
    [ div [ style Styles.editingToggleIcon ] [ Icons.editingToggle editing ]
    , div [ style (Styles.editingToggleText editing) ] [ text "Edit" ]
    ]

greeting : User -> Html msg
greeting user =
  case user of
    Guest ->
      text ""
    Admin person ->
      div
        [ style Styles.greetingContainer ]
        [ img [ style Styles.greetingImage, src "/images/users/default.png" ] []
        , div [ style Styles.greetingName ] [ text person.name ]
        ]
    General person ->
      div
        [ style Styles.greetingContainer ]
        [ img [ style Styles.greetingImage, src "/images/users/default.png" ] []
        , div [ style Styles.greetingName ] [ text person.name ]
        ]



userName : User -> String
userName user =
  case user of
    Admin person -> person.name
    General person -> person.name
    Guest -> "Guest"
