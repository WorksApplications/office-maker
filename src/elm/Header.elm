module Header exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Model.Person exposing (..)
import Model.User as User exposing (..)
import Model.I18n as I18n exposing (Language(..))

import View.Styles as S
import View.Icons as Icons

import InlineHover exposing (hover)

type alias State = Bool

type Msg
  = ToggleUserMenu


init : State
init = False


update : Msg -> State -> State
update action menuOpened =
  case action of
    ToggleUserMenu ->
      not menuOpened


type alias Context msg =
  { onSignInClicked : msg
  , onSignOutClicked : msg
  , onToggleEditing : msg
  , onTogglePrintView : msg
  , onSelectLang : Language -> msg
  , onUpdate : Msg -> msg
  , title : String
  , lang : Language
  , user : Maybe User
  , editing : Bool
  , printMode : Bool
  }


view : Context msg -> State -> Html msg
view context state =
  if context.printMode then
    viewPrintMode context
  else
    header
      [ style S.header ]
      [ h1
          [ style S.h1 ]
          [ a [ style S.headerLink, href "/" ] [ text context.title ] ]
      , normalMenu context state
      ]


viewPrintMode : Context msg -> Html msg
viewPrintMode context =
  header
    [ style S.header ]
    [ h1 [ style S.h1 ] [ text context.title ]
    , menu [ printButtonView context.onTogglePrintView context.lang True ]
    ]


normalMenu : Context msg -> State -> Html msg
normalMenu context menuOpened =
  menu <|
    case context.user of
      Just user ->
        editingToggle context.onToggleEditing context.lang user context.editing ::
        printButton context.onTogglePrintView context.lang user ::
        ( if user == Guest then
            [ signIn context.onSignInClicked context.lang ]
          else
            [ userMenuToggle context.onUpdate user menuOpened
            , if menuOpened then
                userMenuView context
              else
                text ""
            ]
        )

      Nothing ->
        []


userMenuToggle : (Msg -> msg) -> User -> Bool -> Html msg
userMenuToggle onUpdate user menuOpened =
  div
    [ onClick (onUpdate ToggleUserMenu) ]
    [ greeting user menuOpened
    ]


userMenuView : Context msg -> Html msg
userMenuView context =
  div
    [ style S.userMenuView ]
    [ langSelectView context.onSelectLang context.lang
    , signOut context.onSignOutClicked context.lang
    ]


langSelectView : (Language -> msg) -> Language -> Html msg
langSelectView onSelectLang lang =
  div
    [ style S.langSelectView ]
    [ div [ style (S.langSelectViewItem (lang == JA)), onClick (onSelectLang JA) ] [ text "日本語" ]
    , div [ style (S.langSelectViewItem (lang == EN)), onClick (onSelectLang EN) ] [ text "English" ]
    ]


menu : List (Html msg) -> Html msg
menu children =
  div [ style S.headerMenu ] children


editingToggle : msg -> Language -> User -> Bool -> Html msg
editingToggle onToggleEditing lang user editing =
  if User.isGuest user then
    text ""
  else
    editingToggleView onToggleEditing lang editing


printButton : msg -> Language -> User -> Html msg
printButton onTogglePrintView lang user =
  if User.isGuest user then
    text ""
  else
    printButtonView onTogglePrintView lang False


signIn : msg -> Language -> Html msg
signIn onSignInClicked lang =
  div [ style S.login, onClick onSignInClicked ] [ text (I18n.signIn lang) ]


signOut : msg -> Language -> Html msg
signOut onSignOutClicked lang =
  div [ style S.logout, onClick onSignOutClicked ] [ text (I18n.signOut lang) ]


printButtonView : msg -> Language -> Bool -> Html msg
printButtonView onTogglePrintView lang printMode =
  -- iconView ToggleEditing (Icons.editingToggle False) "Print"
  hover S.hoverHeaderIconHover
  div
    [ onClick onTogglePrintView
    , style (S.editingToggleContainer False)
    ]
    [ div [ style S.editingToggleIcon ] [ Icons.printButton ]
    , div [ style (S.editingToggleText) ] [ text (if printMode then I18n.close lang else I18n.print lang) ]
    ]


editingToggleView : msg -> Language -> Bool -> Html msg
editingToggleView onToggleEditing lang editing =
  -- iconView ToggleEditing (Icons.editingToggle editing) "Edit"
  hover
    S.hoverHeaderIconHover
    div
    [ onClick onToggleEditing
    , style (S.editingToggleContainer editing)
    ]
    [ div [ style S.editingToggleIcon ] [ Icons.editingToggle ]
    , div [ style (S.editingToggleText) ] [ text (I18n.edit lang) ]
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


greeting : User -> Bool -> Html msg
greeting user menuOpened =
  case user of
    Guest ->
      text ""

    Admin person ->
      greetingForPerson person menuOpened

    General person ->
      greetingForPerson person menuOpened


greetingForPerson : Person -> Bool -> Html msg
greetingForPerson person menuOpened =
  let
    image =
      case person.image of
        Just url ->
          img [ style S.greetingImage, src url ] []

        Nothing ->
          text ""
  in
    div
      [ style S.userMenuToggle ]
      [ image
      , div [ style S.greetingName ] [ text person.name ]
      , div [ style S.userMenuToggleIcon ] [ Icons.userMenuToggle menuOpened ]
      ]


userName : User -> String
userName user =
  case user of
    Admin person -> person.name
    General person -> person.name
    Guest -> "Guest"
