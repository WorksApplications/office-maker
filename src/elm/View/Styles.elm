module View.Styles exposing (..) -- where

import Util.StyleUtil exposing (..)

type alias S = List (String, String)

zIndex :
  { selectedDesk : String
  , deskInput : String
  , selectorRect : String
  , floorInfo : String
  , personDetailPopup : String
  , subView : String
  , messageBar : String
  , contextMenu : String
  , modalBackground : String
  }
zIndex =
  { selectedDesk = "100"
  , deskInput = "200"
  , selectorRect = "300"
  , floorInfo = "500"
  , personDetailPopup = "550"
  , subView = "600"
  , messageBar = "700"
  , contextMenu = "800"
  , modalBackground = "900"
  }

selectColor : String
selectColor = "#69e"

errorTextColor : String
errorTextColor = "#d45"

noMargin : S
noMargin =
  [ ( "margin", "0") ]

noPadding : S
noPadding =
  [ ( "padding", "0") ]

flex : S
flex =
  [ ( "display", "flex") ]

h1 : S
h1 =
  noMargin ++
    [ ( "font-size", "1.4em")
    , ("font-weight", "normal")
    , ("line-height", px headerHeight)
    ]

ul : S
ul =
  noMargin ++
    [ ("list-style-type", "none")
    , ("padding-left", "0")
    ]

headerHeight : Int
headerHeight = 37

header : S
header =
  noMargin ++
    [ ( "background", "rgb(100,100,120)")
    , ("color", "#eee")
    , ("height", px headerHeight)
    , ("padding-left", "10px")
    , ("padding-right", "10px")
    , ("display", "flex")
    , ("justify-content", "space-between")
    ]

rect : (Int, Int, Int, Int) -> S
rect (x, y, w, h) =
  [ ("top", px y)
  , ("left", px x)
  , ("width", px w)
  , ("height", px h)
  ]

absoluteRect : (Int, Int, Int, Int) -> S
absoluteRect rect' =
  ("position", "absolute") :: (rect rect')

deskInput : (Int, Int, Int, Int) -> S
deskInput rect =
  (absoluteRect rect) ++ noPadding ++ [ ("z-index", zIndex.deskInput)
  , ("box-sizing", "border-box")
  ]

desk : (Int, Int, Int, Int) -> String -> Bool -> Bool -> S
desk rect color selected alpha =
  (absoluteRect rect) ++ [ ("opacity", if alpha then "0.5" else "1.0")
  , ("background-color", color)
  , ("box-sizing", "border-box")
  , ("z-index", if selected then zIndex.selectedDesk else "")
  , ("border-style", "solid")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then "#69e" else "#666")
  ]

selectorRect : (Int, Int, Int, Int) -> S
selectorRect rect =
  (absoluteRect rect) ++ [("z-index", zIndex.selectorRect)
  , ("border-style", "solid")
  , ("border-width", "2px")
  , ("border-color", selectColor)
  ]

colorProperty : String -> Bool -> S
colorProperty color selected =
  [ ("background-color", color)
  , ("cursor", "pointer")
  , ("width", "24px")
  , ("height", "24px")
  , ("box-sizing", "border-box")
  , ("border-style", "solid")
  , ("margin-right", "2px")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then "#69e" else "#666")
  ]

subView : S
subView =
    [ ("z-index", zIndex.subView)
    , ("width", "320px")
    -- , ("overflow", "hidden")
    , ("background", "#eee")
    , ("position", "relative")
    ]

contextMenu : (Int, Int) -> (Int, Int) -> Int -> S
contextMenu (x, y) (windowWidth, windowHeight) rows =
  let
    width = 200
    height = rows * 20 --TODO
    x' = min x (windowWidth - width)
    y' = min y (windowHeight - height)
  in
    [ ("width", px width)
    , ("left", px x')
    , ("top", px y')
    , ("position", "fixed")
    , ("z-index", zIndex.contextMenu)
    , ("background-color", "#fff")
    , ("box-sizing", "border-box")
    , ("border-style", "solid")
    , ("border-width", "1px")
    , ("border-color", "#eee")
    ]

contextMenuItem : S
contextMenuItem =
  [ ("padding", "5px")
  ]

canvasView : (Int, Int, Int, Int) -> S
canvasView rect =
  (absoluteRect rect) ++
    [ ("background-color", "#fff")
    , ("overflow", "hidden")
    , ("font-family", "default")
    ]

canvasContainer : S
canvasContainer =
  [ ("position", "relative")
  , ("overflow", "hidden")
  , ("background", "#000")
  , ("flex", "1")
  ]

nameLabel : Float -> S
nameLabel ratio =
  [ ("display", "table-cell")
  , ("vertical-align", "middle")
  , ("text-align", "center")
  , ("position", "absolute")
  , ("cursor", "default")
  , ("font-size", em ratio) --TODO
   -- TODO vertical align
  ]

shadow : S
shadow =
  [ ("box-shadow", "0 2px 2px 0 rgba(0,0,0,.14),0 3px 1px -2px rgba(0,0,0,.2),0 1px 5px 0 rgba(0,0,0,.12)") ]

card : S
card =
  [ ("margin", "5px")
  , ("padding", "5px")
  ] ++ shadow

selection : Bool -> S
selection selected =
  [ ("cursor", "pointer")
  , ("padding-top", "8px")
  , ("padding-bottom", "4px")
  , ("text-align", "center")
  , ("box-sizing", "border-box")
  , ("margin-right", "-1px")
  , ("border", "solid 1px #666")
  , ("background-color", if selected then selectColor else "inherit")
  , ("color", if selected then "#fff" else "inherit")
  -- , ("font-weight", if selected then "bold" else "inherit")
  ]

transition : Bool -> S
transition disabled =
  if disabled then [] else
    [ ("transition-property", "width, height, top, left")
    , ("transition-duration", "0.2s")
    ]

prototypePreviewView : Bool -> S
prototypePreviewView stampMode =
  [ ("width", "238px")
  , ("height", "238px")
  , ("position", "relative")
  , ("border-style", "solid")
  , ("border-width", if stampMode then "2px" else "1px")
  , ("border-color", if stampMode then selectColor else "#666")
  , ("box-sizing", "border-box")
  , ("margin-top", "10px")
  , ("background-color", "#fff")
  , ("overflow", "hidden")
  ]

prototypePreviewViewInner : Int -> S
prototypePreviewViewInner index =
  [ ("width", "238px")
  , ("height", "238px")
  , ("position", "relative")
  , ("top", "0")
  , ("left", px (index * -238))
  , ("transition-property", "left")
  , ("transition-duration", "0.2s")
  ]

prototypePreviewScroll : S
prototypePreviewScroll =
  [ ("width", "30px")
  , ("height", "30px")
  , ("font-size", "large")
  , ("font-weight", "bold")
  , ("line-height", "30px")
  , ("position", "absolute")
  , ("top", "104px")
  , ("border-radius", "15px")
  , ("text-align", "center")
  , ("color", "#fff")
  , ("background-color", "#ccc")
  , ("cursor", "pointer")
  ]

formControl : S
formControl =
  [ ("height", "34px")
  , ("width", "100%")
  , ("box-sizing", "border-box")
  , ("font-size", "14px")
  , ("line-height", "1.42857143")
  , ("padding", "6px 12px")
  , ("margin-bottom", "6px")
  ]

button : S
button =
  formControl ++
    [ ("display", "block")
    , ("text-align", "center")
    , ("background-color", "#eee")
    , ("width", "100%")
    -- , ("box-shadow", "0 1px 1.5px 0 rgba(0,0,0,.12),0 1px 1px 0 rgba(0,0,0,.24)")
    -- , ("box-shadow", "rgba(0, 0, 0, 0.12) 0px 0.1px 0.0px 0px, rgba(0, 0, 0, 0.24) 0px 0.5px 0.2px 0px")
    ]

buttons : S
buttons =
  []


defaultButton : S
defaultButton =
  button ++
  [ ("border", "solid 1px #aaa") ]

input : S
input =
  formControl ++
    [ ("color", "#333")
    , ("background-color", "#fff")
    , ("box-shadow", "inset 0 1px 2px rgba(0,0,0,0.075)")
    , ("border", "1px solid #ddd")
    ]

imageLoadButton : S
imageLoadButton =
  defaultButton ++
    [ ("width", "120px")
    ]

publishButton : S
publishButton =
  primaryButton

floorNameInput : S
floorNameInput =
  input ++ [ ("width", "177px")
  , ("margin-right", "12px")
  ]

realSizeInput : S
realSizeInput =
  input ++ [ ("width", "50px")
  , ("margin-right", "12px")
  ]

floorNameLabel : S
floorNameLabel =
  [ ("margin-right", "23px")
  ]

widthHeightLabel : S
widthHeightLabel =
  [ ("margin-right", "3px")
  ]

headerMenu : S
headerMenu =
  [ ("display", "flex")
  , ("justify-content", "flex-end")
  ]

headerMenuItem : S
headerMenuItem =
  noMargin ++
    [ ("text-align", "center")
    , ("justify-content", "flex-end")
    , ("line-height", "37px")
    ]

greeting : S
greeting = headerMenuItem ++
  [ ("margin-right", "50px")
  ]

greetingImage : S
greetingImage =
  [ ("height", "24px")
  , ("margin-top", "6px")
  , ("box-shadow", "0 0px 5px 3px rgba(255,255,255,0.5)")
  ]

login : S
login = headerMenuItem ++
  [ ("width", "80px")
  , ("cursor", "pointer")
  ]

logout : S
logout = headerMenuItem ++
  [ ("width", "80px")
  , ("cursor", "pointer")
  ]

loginContainer : S
loginContainer =
  [ ("margin-left", "auto")
  , ("margin-right", "auto")
  , ("margin-top", "40px")
  , ("margin-bottom", "auto")
  , ("width", "400px")
  , ("padding", "15px")
  , ("border", "solid 1px #aaa")
  ]

formInput : S
formInput =
  input ++ [ ("padding", "7px 8px")
  , ("vertical-align", "middle")
  , ("font-size", "13px")
  , ("margin-top", "5px")
  , ("margin-bottom", "15px")
  ]

primaryButton : S
primaryButton =
  button ++
    [ ("background-color", "rgb(100, 180, 85)")
    , ("color", "#fff")
    , ("border", "solid 1px rgb(100, 180, 85)")
    ]

loginCaption : S
loginCaption =
  []

loginError : S
loginError =
  [ ("color", errorTextColor)
  , ("margin-bottom", "15px")
  ]

searchBox : S
searchBox =
  input ++
    [ ("background-color", "white")
    , ("color", "#000")
    , ("border-radius", "17px")
    , ("outline", "none")
    ]

searchResultItem : S
searchResultItem =
    [ ("padding", "5px")
    , ("cursor", "pointer")
    ]

floorsInfoView : S
floorsInfoView =
    [ ("position", "absolute")
    , ("display", "flex")
    , ("z-index", zIndex.floorInfo)
    ]

floorsInfoViewItem : Bool -> Bool -> S
floorsInfoViewItem selected public =
    [ ("background-color", if public then "#fff" else "#aaa")
    , ("padding", "8px 12px")
    , ("border-right", if selected then "solid 2px " ++ selectColor else "solid 1px #ddd")
    , ("border-bottom", if selected then "solid 2px " ++ selectColor else "solid 1px #ddd")
    , ("border-top", if selected then "solid 2px " ++ selectColor else "none")
    , ("border-left", if selected then "solid 2px " ++ selectColor else "none")
    , ("min-width", "60px")
    , ("text-align", "center")
    , ("box-sizing", "border-box")
    ]

subViewTab : Int -> Bool -> S
subViewTab index active =
    [ ("position", "absolute")
    , ("top", px (10 + index * 130))
    , ("left", "-30px")
    , ("width", "30px")
    , ("height", "120px")
    , ("padding-left", "6px")
    , ("line-height", "135px")
    , ("background-color", if active then "#eee" else "#eee")
    , ("z-index", zIndex.subView)
    , ("cursor", "pointer")
    , ("border-radius", "8px 0 0 8px")
    , ("box-shadow", if active then "" else "inset -4px 0 4px rgba(0,0,0,0.03)")
    , ("box-sizing", "border-box")
    ]

personMatchingInfo : S
personMatchingInfo =
    [ ("border-radius", "10px")
    , ("width", "20px")
    , ("height", "20px")
    ]

personMatched : S
personMatched =
    personMatchingInfo ++ [ ("background-color", "#6a6") ]

personNotMatched : S
personNotMatched =
    personMatchingInfo ++ [ ("background-color", "#ccc") ]

popup : S
popup =
    [ ("box-sizing", "border-box")
    , ("padding", "20px")
    , ("background-color", "#fff")
    , ("position", "absolute")
    ]

modalBackground : S
modalBackground =
    [ ("background-color", "rgba(0,0,0,0.5)")
    , ("position", "fixed")
    , ("left", "0")
    , ("right", "0")
    , ("top", "0")
    , ("bottom", "0")
    , ("z-index", zIndex.modalBackground)
    ]


diffPopup : S
diffPopup =
  popup ++
    [ ("left", "20%")
    , ("right", "20%")
    , ("top", "10%")
    , ("bottom", "10%")
    ] ++ shadow

personDetailPopup : (Int, Int) -> S
personDetailPopup (x, y) =
  let
    width = 300
    height = 160
  in
    popup ++
      [ ("width", px width)
      , ("height", px height)
      , ("left", px (x - (width // 2)))
      , ("top", px (y - (height + 10)))
      , ("z-index", zIndex.personDetailPopup)
      ] ++ shadow

personDetailPopupClose : S
personDetailPopupClose =
  [ ("position", "absolute")
  , ("top", "5px")
  , ("right", "5px")
  ]


personDetailPopupPersonImage : S
personDetailPopupPersonImage =
  [ ("position", "absolute")
  , ("top", "15px")
  , ("right", "15px")
  , ("max-width", "60px")
  ]

personDetailPopupPersonNo : S
personDetailPopupPersonNo =
  [ ("position", "absolute")
  , ("fon-size", "small")
  , ("top", "5px")
  ]

personDetailPopupPersonName : S
personDetailPopupPersonName =
  [ ("position", "absolute")
  , ("fon-size", "larger")
  , ("font-weight", "bold")
  , ("top", "15px")
  ]

personDetailPopupPersonOrg : S
personDetailPopupPersonOrg =
  [ ("position", "absolute")
  , ("fon-size", "small")
  , ("top", "50px")
  ]

messageBar : S
messageBar =
    [ ("position", "absolute")
    , ("color", "#fff")
    , ("width", "100%")
    , ("z-index", zIndex.messageBar)
    , ("padding", "5px 10px")
    , ("height", "29px")
    , ("transition", "height")
    , ("box-sizing", "border-box")
    , ("transition", "opacity 0.8s linear")
    ]

successBar : S
successBar =
  messageBar ++
    [ ("background-color", "#4c5")
    , ("opacity", "1")
    ]

errorBar : S
errorBar =
  messageBar ++
    [ ("background-color", "#d45")
    , ("opacity", "1")
    ]

noneBar : S
noneBar =
  messageBar ++
    [ ("opacity", "0")
    , ("pointer-events", "none")
    , ("background-color", "#4c5")
    ]

mainView : Int -> S
mainView windowHeight =
  let
    height = windowHeight - headerHeight
  in
    (flex ++
      [ ("height", px height)
      , ("position", "relative")
      ]
    )

searchResultItemIcon : S
searchResultItemIcon =
  [ ("width", "30px")
  ]
