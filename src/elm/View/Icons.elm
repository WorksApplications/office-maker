module View.Icons exposing (..) -- where

import Svg exposing (Svg)
import Color exposing (Color, white, black, gray)
import Material.Icons.Navigation exposing (check)
-- import Material.Icons.Notification exposing (priority_high) -- TODO

import Material.Icons.Editor exposing (mode_edit, border_all)
import Material.Icons.Image exposing (crop_square)
import Material.Icons.Internal  exposing (icon)

selectMode : Bool -> Svg msg
selectMode selected =
  crop_square (if selected then white else Color.rgb 80 80 80) 24

penMode : Bool -> Svg msg
penMode selected =
  mode_edit (if selected then white else Color.rgb 80 80 80) 24

stampMode : Bool -> Svg msg
stampMode selected =
  border_all (if selected then white else Color.rgb 80 80 80) 24

personMatched : Svg msg
personMatched =
  check white 18

personNotMatched : Svg msg
personNotMatched =
  priority_high white 18

-- TODO PR to elm-material-icons

priority_high : Color -> Int -> Svg msg
priority_high =
  icon "M10 3h4v12h-4z"
