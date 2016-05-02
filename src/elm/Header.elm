module Header where

import Signal exposing (Address, forwardTo)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
-- import Util.HtmlUtil exposing (..)
import User exposing (..)
import API
import Task exposing (Task)
import Effects exposing (Effects)

import View.Styles as Styles
-- import View.Icons as Icons

type Action = Login | Logout | NoOp

update : Action -> Effects Action
update action =
  case action of
    NoOp ->
      Effects.none
    Login ->
      Effects.task (Task.map (always NoOp) API.goToLogin)
    Logout ->
      Effects.task (Task.map (always NoOp) API.goToLogout)


view : Maybe (Address Action, User) -> Html
view maybeContext =
  let
    menu =
      case maybeContext of
        Just (address, user) ->
          let
            greetingView =
              div [ style Styles.greeting ] [ greeting user ]
            login =
              div [ style Styles.login, onClick address Login ] [ text "Sign in"]
            logout =
              div [ style Styles.logout, onClick address Logout ] [ text "Sign out"]
            children =
              case user of
                Admin _ -> [ greetingView, logout ]
                General _ -> [ greetingView, logout ]
                Guest -> [ greetingView, login, logout ]
          in
            div [ style Styles.headerMenu ] children
        Nothing -> text ""
  in
    header
      [ style Styles.header ]
      [ h1 [ style Styles.h1 ] [text "Office Maker"]
      , menu
      ]

greeting : User -> Html
greeting user =
  text ("Hello, " ++ userName user ++ ".")


userName : User -> String
userName user =
  case user of
    Admin name -> name
    General name -> name
    Guest -> "Guest"
