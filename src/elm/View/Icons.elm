module View.Icons exposing (..) -- where

import Svg exposing (Svg)
import Color exposing (Color, white, black, gray)
import Material.Icons.Navigation exposing (check, close)
import Material.Icons.Action exposing (search)
import Material.Icons.Editor exposing (mode_edit, border_all)
import Material.Icons.Image exposing (crop_square)
import Material.Icons.Social exposing (person)
import Material.Icons.Communication exposing (phone, email)
import Material.Icons.Maps exposing (local_printshop)

-- import Material.Icons.Notification exposing (priority_high) -- TODO
-- import Material.Icons.Internal exposing (icon)

defaultColor : Color
defaultColor =
  Color.rgb 140 140 140

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
  check white 18
  -- priority_high white 18

popupClose : Svg msg
popupClose =
  close defaultColor 18

searchTab : Svg msg
searchTab =
  search defaultColor 20

editTab : Svg msg
editTab =
  mode_edit defaultColor 20

searchResultItemPerson : Svg msg
searchResultItemPerson =
  person defaultColor 20

personDetailPopupPersonTel : Svg msg
personDetailPopupPersonTel =
  phone defaultColor 16

personDetailPopupPersonMail : Svg msg
personDetailPopupPersonMail =
  email defaultColor 16

headerIconColor : Color
headerIconColor =
  white

editingToggle : Svg msg
editingToggle =
  mode_edit headerIconColor 22

printButton : Svg msg
printButton =
  local_printshop headerIconColor 22


-- TODO PR to elm-material-icons

-- priority_high : Color -> Int -> Svg msg
-- priority_high =
--   icon "M10 3h4v12h-4z"
