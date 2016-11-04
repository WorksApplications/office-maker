module Page.Master.View exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.Prototype exposing (Prototype)

import View.Common exposing (..)
import View.MessageBar as MessageBar
import View.PrototypePreviewView as PrototypePreviewView
import View.CommonStyles as CS

import Page.Master.Model exposing (Model)
import Page.Master.PrototypeForm as PrototypeForm exposing (PrototypeForm)
import Page.Master.Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
  div
    []
    [ headerView model
    , messageBar model
    , card Nothing <| colorMasterView model
    , card Nothing <| prototypeMasterView model
    ]


headerView : Model -> Html Msg
headerView model =
  Header.view
    { onSignInClicked = NoOp
    , onSignOutClicked = NoOp
    , onToggleEditing = NoOp
    , onTogglePrintView = NoOp
    , onSelectLang = \_ -> NoOp
    , onUpdate = UpdateHeaderState
    , title = model.title
    , lang = EN
    , user = Nothing
    , editing = False
    , printMode = False
    }
    model.headerState


colorMasterView : Model -> List (Html Msg)
colorMasterView model =
  [ h2 [] [ text "Background Colors (for desks and labels)"]
  , div [] <| List.indexedMap (colorMasterRow True) model.colorPalette.backgroundColors
  , h2 [] [ text "Text Colors (for labels)"]
  , div [] <| List.indexedMap (colorMasterRow False) model.colorPalette.textColors
  ]


colorMasterRow : Bool -> Int -> String -> Html Msg
colorMasterRow isBackgroundColor index color =
  div [ style [("height", "30px"), ("display", "flex")] ]
    [ colorSample color
    , input [ onInput (InputColor isBackgroundColor index), value color ] []
    ]


prototypeMasterView : Model -> List (Html Msg)
prototypeMasterView model =
  [ h2 [] [ text "Prototypes"]
  , div [] <| List.indexedMap prototypeMasterRow model.prototypes
  ]


prototypeMasterRow : Int -> Prototype -> Html Msg
prototypeMasterRow index prototype =
  div [ style [ ("display", "flex")] ]
    [ PrototypePreviewView.singleView 300 238 prototype
    , prototypeParameters index prototype
    ]


prototypeParameters : Int -> Prototype -> Html Msg
prototypeParameters index prototype =
  div
    []
    [ App.map (\backgroundColor -> UpdatePrototype index { prototype | backgroundColor = backgroundColor} )
        <| prototypeParameter "Background Color" prototype.backgroundColor
    , App.map (\color -> UpdatePrototype index { prototype | color = color} )
        <| prototypeParameter "Text Color" prototype.color
    -- , App.map (\width -> UpdatePrototype index { prototype | width = width} )
    --     <| prototypeParameter "Width" (toString prototype.width)
    -- , App.map (\height -> UpdatePrototype index { prototype | height = height} )
    --     <| prototypeParameter "Height" (toString prototype.height)
    ]


prototypeParameter : String -> String -> Html String
prototypeParameter label value_ =
  div
    []
    [ span [] [ text label ]
    , input [ style CS.input, value value_, onInput identity ] []
    ]


colorSample : String -> Html Msg
colorSample color =
  div [ style [("background-color", color), ("width", "30px")] ] [ ]


messageBar : Model -> Html Msg
messageBar model =
  case model.error of
    Just s ->
      MessageBar.error s

    Nothing ->
      MessageBar.none
