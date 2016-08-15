module Header exposing (..)

import Task exposing (Task)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Model.Person exposing (..)
import Model.User as User exposing (..)
import Model.API as API

import View.Styles as S
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


update : String -> Msg -> (Cmd Msg, Event)
update accountServiceRoot action =
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
      (Task.perform (always LogoutSuccess) (always LogoutSuccess) (API.logout accountServiceRoot), None)

    LogoutSuccess ->
      (Cmd.none, LogoutDone)


view : String -> Maybe (User, Bool) -> Html Msg
view title maybeContext =
  header
    [ style S.header ]
    [ h1
        [ style S.h1 ]
        [ a [ style S.headerLink, href "/" ] [ text title ] ]
    , normalMenu maybeContext
    ]


viewPrintMode : String -> Html Msg
viewPrintMode title =
  header
    [ style S.header ]
    [ h1 [ style S.h1 ] [ text title ]
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
  div [ style S.headerMenu ] children


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
  div [ style S.login, onClick Login ] [ text "Sign in" ]


logout : Html Msg
logout =
  div [ style S.logout, onClick Logout ] [ text "Sign out" ]


printButtonView : Bool -> Html Msg
printButtonView showingPrint =
  -- iconView ToggleEditing (Icons.editingToggle False) "Print"
  hover S.hoverHeaderIconHover
  div
    [ onClick (TogglePrintView (not showingPrint))
    , style (S.editingToggleContainer False)
    ]
    [ div [ style S.editingToggleIcon ] [ Icons.printButton ]
    , div [ style (S.editingToggleText) ] [ text (if showingPrint then "Close" else "Print") ]
    ]


editingToggleView : Bool -> Html Msg
editingToggleView editing =
  -- iconView ToggleEditing (Icons.editingToggle editing) "Edit"
  hover
    S.hoverHeaderIconHover
    div
    [ onClick ToggleEditing
    , style (S.editingToggleContainer editing)
    ]
    [ div [ style S.editingToggleIcon ] [ Icons.editingToggle ]
    , div [ style (S.editingToggleText) ] [ text "Edit" ]
    ]

-- iconView : msg -> Html msg -> String -> Html msg
-- iconView onClickMessage icon text_ =
--   div
--     [ onClick onClickMessage
--     , style (S.editingToggleContainer)
--     ]
--     [ div [ style S.editingToggleIcon ] [ icon ]
--     , div [ style (S.editingToggleText editing) ] [ text text_ ]
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
          img [ style S.greetingImage, src url ] []
        Nothing ->
          text ""
  in
    div
      [ style S.greetingContainer ]
      [ image
      , div [ style S.greetingName ] [ text person.name ]
      ]


userName : User -> String
userName user =
  case user of
    Admin person -> person.name
    General person -> person.name
    Guest -> "Guest"
