module Util.HoverUtil exposing (Model, Msg, init, onHover, update, isHovered) -- where

import Html exposing (Attribute, div, button, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Set exposing (Set)


type Msg = Enter String | Leave String


type alias Model = Set String


init : Set String
init = Set.empty


onHover : (Msg -> msg) -> String -> List (Attribute msg)
onHover transformMsg id =
  [ onMouseEnter <| transformMsg <| Enter id
  , onMouseLeave <| transformMsg <| Leave id
  ]


update : Msg -> Model -> Model
update msg set =
  case msg of
    Enter id ->
      Set.insert id set
    Leave id ->
      Set.remove id set


isHovered : String -> Model -> Bool
isHovered = Set.member
