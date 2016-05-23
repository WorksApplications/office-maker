module Header exposing (..) -- where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
-- import Util.HtmlUtil exposing (..)
import Model.User as User exposing (..)
import Model.API as API
import Task exposing (Task)

import View.Styles as Styles
-- import View.Icons as Icons

type Msg = Login | Logout | LogoutSuccess | NoOp
type Event = LogoutDone | None

update : Msg -> (Cmd Msg, Event)
update action =
  case action of
    NoOp ->
      (Cmd.none, None)
    Login ->
      (Task.perform (always NoOp) (always NoOp) API.goToLogin, None)
    Logout ->
      (Task.perform (always LogoutSuccess) (always LogoutSuccess) API.logout, None)--TODO
    LogoutSuccess ->
      (Cmd.none, LogoutDone)

view : Maybe User -> Html Msg
view maybeContext =
  let
    menu =
      case maybeContext of
        Just user ->
          let
            greetingView =
              div [ style Styles.greeting ] [ greeting user ]
            login =
              div [ style Styles.login, onClick Login ] [ text "Sign in" ]
            logout =
              div [ style Styles.logout, onClick Logout ] [ text "Sign out" ]
            children =
              greetingView ::
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

greeting : User -> Html msg
greeting user =
  case user of
    Guest ->
      text ""
    _ ->
      img [ style Styles.greetingImage, src "/images/users/default.png" ] []


userName : User -> String
userName user =
  case user of
    Admin person -> person.name
    General person -> person.name
    Guest -> "Guest"
