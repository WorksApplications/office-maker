module View.Icons exposing (..)

import Svg exposing (Svg)
import Color exposing (Color, white, black, gray)
import FontAwesome exposing (..)


defaultColor : Color
defaultColor =
  Color.rgb 140 140 140


modeColor : Color
modeColor =
  Color.rgb 90 90 90


mode : (Color -> Int -> Svg msg) -> (Bool -> Svg msg)
mode f = \selected ->
  f (if selected then white else modeColor) 24


selectMode : Bool -> Svg msg
selectMode =
  mode mouse_pointer


penMode : Bool -> Svg msg
penMode =
  mode pencil


stampMode : Bool -> Svg msg
stampMode =
  mode th_large


labelMode : Bool -> Svg msg
labelMode =
  mode font


personMatched : Float -> Svg msg
personMatched ratio =
  check white (Basics.floor (18 * ratio))


personNotMatched : Float -> Svg msg
personNotMatched ratio =
  question white (Basics.floor (18 * ratio))


popupClose : Svg msg
popupClose =
  close defaultColor 18


searchTab : Svg msg
searchTab =
  search defaultColor 20


editTab : Svg msg
editTab =
  pencil defaultColor 20


proplabelColor : Color
proplabelColor =
  defaultColor


backgroundColorPropLabel : Svg msg
backgroundColorPropLabel =
  th_large proplabelColor 12


colorPropLabel : Svg msg
colorPropLabel =
  font proplabelColor 12


shapePropLabel : Svg msg
shapePropLabel =
  star_o proplabelColor 12


shapeRectangle : Svg msg
shapeRectangle =
  square defaultColor 20


shapeEllipse : Svg msg
shapeEllipse =
  circle defaultColor 20


searchResultItemPerson : Svg msg
searchResultItemPerson =
  user defaultColor 20


personDetailPopupPersonTel : Svg msg
personDetailPopupPersonTel =
  phone defaultColor 16


personDetailPopupPersonMail : Svg msg
personDetailPopupPersonMail =
  envelope defaultColor 16


headerIconColor : Color
headerIconColor =
  white


editingToggle : Svg msg
editingToggle =
  pencil headerIconColor 22


printButton : Svg msg
printButton =
  print headerIconColor 22
