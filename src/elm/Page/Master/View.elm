module Page.Master.View exposing (..)

import Time exposing (second)
import Task
import Http
import Navigation

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Component.Header as Header

import Model.I18n as I18n exposing (Language(..))
import Model.User as User exposing (User)
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import View.Common exposing (..)
import View.Styles as Styles
import View.MessageBar as MessageBar

import Page.Master.Model exposing (Model)
import Page.Master.Msg exposing (Msg(..))

view : Model -> Html Msg
view model =
  div
    []
    [ headerView model
    , messageBar model
    , card <| colorMasterView model
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
  List.indexedMap row model.colorPalette.backgroundColors


row : Int -> String -> Html Msg
row index color =
  div [ style [("height", "30px"), ("display", "flex")] ]
    [ colorSample color
    , input [ onInput (InputColor True index), value color ] []
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
