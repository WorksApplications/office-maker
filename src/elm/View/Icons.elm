module View.Icons exposing (..) -- where

import Svg exposing (Svg)
import Color exposing (white, black, gray)
-- import Material.Icons.Editor exposing (mode_edit, border_all)
-- import Material.Icons.Image exposing (crop_square)

selectMode : Bool -> Svg msg
selectMode selected =
  Svg.text "selectMode"
  -- crop_square (if selected then white else Color.rgb 80 80 80) 24

penMode : Bool -> Svg msg
penMode selected =
  Svg.text "penMode"
  -- mode_edit (if selected then white else Color.rgb 80 80 80) 24

stampMode : Bool -> Svg msg
stampMode selected =
  Svg.text "stampMode"
  -- border_all (if selected then white else Color.rgb 80 80 80) 24
