module View.Icons exposing (..) -- where

import Svg exposing (Svg)
import Color exposing (white, black, gray)
import Material.Icons.Editor exposing (mode_edit, border_all)
import Material.Icons.Image exposing (crop_square)

selectMode : Bool -> Svg
selectMode selected =
  crop_square (if selected then white else Color.rgb 80 80 80) 24

penMode : Bool -> Svg
penMode selected =
  mode_edit (if selected then white else Color.rgb 80 80 80) 24

stampMode : Bool -> Svg
stampMode selected =
  border_all (if selected then white else Color.rgb 80 80 80) 24
