module Page.Master.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Component.Header as Header
import Model.User as User exposing (User)
import Model.I18n as I18n exposing (Language(..))
import View.Common exposing (..)
import View.MessageBar as MessageBar
import View.PrototypePreviewView as PrototypePreviewView
import View.CommonStyles as CS
import Page.Master.Model exposing (Model)
import Page.Master.PrototypeForm as PrototypeForm exposing (PrototypeForm)
import Page.Master.Msg exposing (Msg(..))
import Page.Master.Styles as S


type alias Size =
    { width : Int, height : Int }


view : Model -> Html Msg
view model =
    div
        []
        [ headerView model
        , messageBar model
        , card False "" Nothing Nothing <| colorMasterView model
        , card False "" Nothing Nothing <| prototypeMasterView model
        , card False "" Nothing Nothing <| usersView model
        ]


headerView : Model -> Html Msg
headerView model =
    Header.view
        { onSignInClicked = NoOp
        , onSignOutClicked = NoOp
        , onToggleEditing = NoOp
        , onTogglePrintView = NoOp
        , onSelectLang = \_ -> NoOp
        , onUpdate = HeaderMsg
        , title = model.title
        , lang = EN
        , user = Nothing
        , editing = False
        , printMode = False
        , searchInput = Nothing
        }
        model.header


colorMasterView : Model -> List (Html Msg)
colorMasterView model =
    [ h2 [] [ text "Background Colors (for desks and labels)" ]
    , div [] <| List.indexedMap (colorMasterRow True) model.colorPalette.backgroundColors
    , button [ onClick (AddColor True) ] [ text "Add" ]
    , h2 [] [ text "Text Colors (for labels)" ]
    , div [] <| List.indexedMap (colorMasterRow False) model.colorPalette.textColors
    , button [ onClick (AddColor False) ] [ text "Add" ]
    ]


colorMasterRow : Bool -> Int -> String -> Html Msg
colorMasterRow isBackgroundColor index color =
    div [ style [ ( "height", "30px" ), ( "display", "flex" ) ] ]
        [ colorSample color
        , input [ onInput (InputColor isBackgroundColor index), value color ] []
        , button [ onClick (DeleteColor isBackgroundColor index) ] [ text "Delete" ]
        ]


colorSample : String -> Html Msg
colorSample color =
    div
        [ style [ ( "background-color", color ), ( "width", "30px" ), ( "border", "solid 1px #aaa" ) ] ]
        []


prototypeMasterView : Model -> List (Html Msg)
prototypeMasterView model =
    [ h2 [] [ text "Prototypes" ]
    , div [] <| List.indexedMap prototypeMasterRow model.prototypes
    ]


prototypeContainerSize : Size
prototypeContainerSize =
    { width = 300
    , height = 300
    }


prototypeMasterRow : Int -> PrototypeForm -> Html Msg
prototypeMasterRow index prototypeForm =
    div [ style [ ( "display", "flex" ) ] ]
        [ case PrototypeForm.toPrototype prototypeForm of
            Ok prototype ->
                Lazy.lazy2 PrototypePreviewView.singleView prototypeContainerSize prototype

            _ ->
                Lazy.lazy PrototypePreviewView.emptyView prototypeContainerSize
        , prototypeParameters index prototypeForm
        ]


prototypeParameters : Int -> PrototypeForm -> Html Msg
prototypeParameters index prototypeForm =
    div
        []
        [ Html.map (\backgroundColor -> UpdatePrototype index { prototypeForm | backgroundColor = backgroundColor }) <|
            prototypeParameter "Background Color" prototypeForm.backgroundColor PrototypeForm.validateBackgroundColor
        , Html.map (\color -> UpdatePrototype index { prototypeForm | color = color }) <|
            prototypeParameter "Text Color" prototypeForm.color PrototypeForm.validateColor
        , Html.map (\width -> UpdatePrototype index { prototypeForm | width = width }) <|
            prototypeParameter "Width" (prototypeForm.width) PrototypeForm.validateWidth
        , Html.map (\height -> UpdatePrototype index { prototypeForm | height = height }) <|
            prototypeParameter "Height" (prototypeForm.height) PrototypeForm.validateHeight
        , Html.map (\fontSize -> UpdatePrototype index { prototypeForm | fontSize = fontSize }) <|
            prototypeParameter "Font Size" (prototypeForm.fontSize) PrototypeForm.validateFontSize
        , Html.map (\name -> UpdatePrototype index { prototypeForm | name = name }) <|
            prototypeParameter "Name" (prototypeForm.name) PrototypeForm.validateName
        ]


prototypeParameter : String -> String -> (String -> Result String a) -> Html String
prototypeParameter label value_ validate =
    let
        errMessage =
            case validate value_ of
                Ok _ ->
                    Nothing

                Err s ->
                    Just s

        errHtml =
            errMessage
                |> Maybe.map (\s -> span [ style S.validationError ] [ text s ])
                |> Maybe.withDefault (text "")
    in
        div
            []
            [ span [] [ text label ]
            , errHtml
            , input [ style CS.input, value value_, onInput identity ] []
            ]


messageBar : Model -> Html Msg
messageBar model =
    case model.error of
        Just s ->
            MessageBar.error s

        Nothing ->
            MessageBar.none


usersView : Model -> List (Html Msg)
usersView model =
    [ h1 [] [ text "Admins" ]
    , model.allAdmins
        |> List.map userView
        |> div []
    ]


userView : User -> Html Msg
userView user =
    case user of
        User.Admin person ->
            div []
                [ text (person.name ++ " ( " ++ Maybe.withDefault "" person.mail ++ " )")
                ]

        _ ->
            text ""
