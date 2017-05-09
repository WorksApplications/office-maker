module Component.Header exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Model.Person exposing (..)
import Model.User as User exposing (..)
import Model.I18n as I18n exposing (Language(..))
import View.Styles as S
import View.Icons as Icons
import View.HeaderView as HeaderView


type alias Model =
    Bool


type Msg
    = ToggleUserMenu
    | CloseUserMenu


init : Model
init =
    False


update : Msg -> Model -> Model
update msg menuOpened =
    case msg of
        ToggleUserMenu ->
            not menuOpened

        CloseUserMenu ->
            False


subscriptions : Sub Msg
subscriptions =
    -- Mouse.clicks (\_ -> CloseUserMenu)
    Sub.none


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
    , searchInput : Maybe (Html msg)
    }


view : Context msg -> Model -> Html msg
view context state =
    if context.printMode then
        HeaderView.view
            context.printMode
            context.title
            Nothing
            (menu [ Lazy.lazy3 printButtonView context.onTogglePrintView context.lang True ])
    else
        HeaderView.view
            context.printMode
            context.title
            (Just ".")
            (normalMenu context state)


normalMenu : Context msg -> Model -> Html msg
normalMenu context menuOpened =
    let
        searchInput =
            context.searchInput |> Maybe.withDefault (text "")

        others =
            case context.user of
                Just user ->
                    editingToggle context.onToggleEditing context.lang user context.editing
                        :: Lazy.lazy2 printButton context.onTogglePrintView context.lang
                        :: helpView context.lang
                        :: (if user == Guest then
                                [ Lazy.lazy2 signIn context.onSignInClicked context.lang ]
                            else
                                [ Lazy.lazy3 userMenuToggle context.onUpdate user menuOpened
                                , if menuOpened then
                                    userMenuView context
                                  else
                                    text ""
                                ]
                           )

                Nothing ->
                    []
    in
        menu (searchInput :: others)


userMenuToggle : (Msg -> msg) -> User -> Bool -> Html msg
userMenuToggle onUpdate user menuOpened =
    div
        [ onClick (onUpdate ToggleUserMenu) ]
        [ Lazy.lazy2 greeting user menuOpened
        ]


userMenuView : Context msg -> Html msg
userMenuView context =
    div
        [ style S.userMenuView ]
        [ Lazy.lazy2 langSelectView context.onSelectLang context.lang
        , Lazy.lazy2 linkToMaster context.lang context.user
        , Lazy.lazy2 linkToManual context.lang context.user
        , Lazy.lazy2 signOut context.onSignOutClicked context.lang
        ]


langSelectView : (Language -> msg) -> Language -> Html msg
langSelectView onSelectLang lang =
    div
        [ style S.langSelectView ]
        [ div [ style (S.langSelectViewItem (lang == JA)), onClick (onSelectLang JA) ] [ text "日本語" ]
        , div [ style (S.langSelectViewItem (lang == EN)), onClick (onSelectLang EN) ] [ text "English" ]
        ]


linkToMaster : Language -> Maybe User -> Html msg
linkToMaster lang user =
    case user of
        Just (Admin _) ->
            div
                [ style S.userMenuItem ]
                [ a [ href "./master" ] [ text (I18n.goToMaster lang) ] ]

        _ ->
            text ""


linkToManual : Language -> Maybe User -> Html msg
linkToManual lang user =
    case user of
        Just (Admin _) ->
            div
                [ style S.userMenuItem ]
                [ a
                    [ href "./manual.pdf" -- TODO configuration
                    , target "_blank"
                    ]
                    [ text (I18n.goToManual lang) ]
                ]

        _ ->
            text ""


signOut : msg -> Language -> Html msg
signOut onSignOutClicked lang =
    div [ style S.userMenuItem, onClick onSignOutClicked ] [ text (I18n.signOut lang) ]


menu : List (Html msg) -> Html msg
menu children =
    div [ style S.headerMenu ] children


editingToggle : msg -> Language -> User -> Bool -> Html msg
editingToggle onToggleEditing lang user editing =
    if User.isGuest user then
        text ""
    else
        editingToggleView onToggleEditing lang editing


printButton : msg -> Language -> Html msg
printButton onTogglePrintView lang =
    Lazy.lazy3 printButtonView onTogglePrintView lang False


signIn : msg -> Language -> Html msg
signIn onSignInClicked lang =
    div [ style S.login, onClick onSignInClicked ] [ text (I18n.signIn lang) ]


printButtonView : msg -> Language -> Bool -> Html msg
printButtonView onTogglePrintView lang printMode =
    div
        [ onClick onTogglePrintView
        , style (S.editingToggleContainer False)
        , class "no-print"
        ]
        [ div [ style S.editingToggleIcon ] [ Icons.printButton printMode ]
        , div [ style (S.editingToggleText) ]
            [ text
                (if printMode then
                    I18n.close lang
                 else
                    I18n.print lang
                )
            ]
        ]


editingToggleView : msg -> Language -> Bool -> Html msg
editingToggleView onToggleEditing lang editing =
    div
        [ onClick onToggleEditing
        , style (S.editingToggleContainer editing)
        ]
        [ div [ style S.editingToggleIcon ] [ Icons.editingToggle ]
        , div [ style (S.editingToggleText) ] [ text (I18n.edit lang) ]
        ]


helpView : Language -> Html msg
helpView lang =
    a
        [ style (S.editingToggleContainer False)
        , target "_blank"
        , href "./doc" -- TODO configuration
        ]
        [ div [ style S.editingToggleIcon ] [ Icons.helpButton ]
        , div [ style (S.editingToggleText) ] [ text (I18n.help lang) ]
        ]


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
        Admin person ->
            person.name

        General person ->
            person.name

        Guest ->
            "Guest"
