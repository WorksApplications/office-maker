module View.Styles exposing (..)

import Model.ProfilePopupLogic as ProfilePopupLogic
import Util.StyleUtil exposing (..)

type alias S = List (String, String)

zIndex :
  { selectedDesk : String
  , deskInput : String
  , selectorRect : String
  , floorInfo : String
  , personDetailPopup : String
  , candidatesView : String
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
  , candidatesView = "660"
  , messageBar = "700"
  , contextMenu = "800"
  , modalBackground = "900"
  }

selectColor : String
selectColor = "#69e"

errorTextColor : String
errorTextColor = "#d45"

hoverBackgroundColor : String
hoverBackgroundColor = "#9ce"

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

-- TODO better name
headerIconHover : S
headerIconHover =
  [ ("opacity", "0.5")
  ]

-- TODO better name
hoverHeaderIconHover : S
hoverHeaderIconHover =
  [ ("opacity", "0.7")
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

nameInputTextArea : Bool -> (Int, Int, Int, Int) -> S
nameInputTextArea transitionDisabled screenRect =
  deskInput screenRect ++ transition transitionDisabled

desk : (Int, Int, Int, Int) -> String -> Bool -> Bool -> Bool -> S
desk rect color selected alpha disableTransition =
  (absoluteRect rect) ++
  [ ("opacity", if alpha then "0.5" else "1.0")
  , ("display", "table")
  , ("background-color", color)
  , ("box-sizing", "border-box")
  , ("z-index", if selected then zIndex.selectedDesk else "")
  , ("border-style", "solid")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then "#69e" else "#666")
  ] ++ transition disableTransition

selectorRect : (Int, Int, Int, Int) -> S
selectorRect rect =
  (absoluteRect rect) ++ [("z-index", zIndex.selectorRect)
  , ("border-style", "solid")
  , ("border-width", "2px")
  , ("border-color", selectColor)
  ]

colorProperties : S
colorProperties =
  [("display", "flex")]

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
  , ("cursor", "pointer")
  ]

contextMenuItemHover : S
contextMenuItemHover =
  [ ("background-color", "#9ce")
  ]

canvasView : Bool -> (Int, Int, Int, Int) -> S
canvasView isViewing rect =
  (absoluteRect rect) ++
    [ ("background-color", "#fff")
    , ("font-family", "default")
    -- TODO on select person
    -- , ("transition-property", "top, left")
    -- , ("transition-duration", "0.2s")
    ] ++ (if isViewing then [("overflow", "hidden")] else [])

canvasContainer : Bool -> S
canvasContainer printMode =
  [ ("position", "relative")
  , ("background", if printMode then "#fff" else "#000")
  , ("flex", "1")
  ]

nameLabel : Float -> Bool -> S
nameLabel ratio disableTransition =
  [ ("display", "table-cell")
  , ("vertical-align", "middle")
  , ("text-align", "center")
  , ("position", "absolute")
  , ("cursor", "default")
  , ("font-size", em ratio) --TODO
   -- TODO vertical align
  ] ++ transition disableTransition


shadow : S
shadow =
  [ ("box-shadow", "0 2px 2px 0 rgba(0,0,0,.14),0 3px 1px -2px rgba(0,0,0,.2),0 1px 5px 0 rgba(0,0,0,.12)") ]


card : S
card =
  [("padding", "20px")]


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
  [ ("margin-bottom", "6px")
  ]

button : S
button =
    [ ("display", "block")
    , ("height", "30px")
    , ("text-align", "center")
    , ("background-color", "#eee")
    , ("width", "100%")
    , ("padding", "6px 12px")
    , ("box-sizing", "border-box")
    , ("font-size", "14px")
    ]


defaultButton : S
defaultButton =
  button ++
  [ ("border", "solid 1px #aaa") ]

input : S
input =
    [ ("color", "#333")
    , ("width", "100%")
    , ("height", "30px")
    , ("background-color", "#fff")
    , ("box-shadow", "inset 0 1px 2px rgba(0,0,0,0.075)")
    , ("border", "1px solid #ddd")
    , ("padding", "6px 12px")
    , ("box-sizing", "border-box")
    , ("font-size", "14px")
    ]


floorPropertyLabel : S
floorPropertyLabel =
  [ ("display", "block")
  , ("line-height", "30px")
  , ("text-align", "right")
  , ("margin-right", "10px")
  ]

floorPropertyText : S
floorPropertyText =
  [ ("width", "100%")
  , ("height", "30px")
  , ("padding", "6px 12px")
  , ("box-sizing", "border-box")
  , ("font-size", "14px")
  , ("border-bottom", "1px dotted #aaa")
  ]

imageLoadButton : S
imageLoadButton =
  formControl ++ defaultButton ++
    [ ("width", "120px")
    ]

publishButton : S
publishButton =
  formControl ++ primaryButton

floorNameInputContainer : S
floorNameInputContainer =
  formControl ++ flex

floorNameInput : S
floorNameInput =
  input ++
    [ ("display", "block")
    , ("line-height", "30px")
    ]

floorNameText : S
floorNameText =
  floorPropertyText

floorNameLabel : S
floorNameLabel =
  [ ("width", "124px") ] ++ floorPropertyLabel

floorOrdInputContainer : S
floorOrdInputContainer =
  floorNameInputContainer

floorOrdInput : S
floorOrdInput =
  floorNameInput

floorOrdLabel : S
floorOrdLabel =
  floorNameLabel

floorOrdText : S
floorOrdText =
  floorPropertyText

floorSizeInputContainer : S
floorSizeInputContainer =
  formControl ++ flex

realSizeInput : S
realSizeInput =
  input ++
    [ ("width", "50px")
    ]

widthHeightLabel : S
widthHeightLabel =
  [ ("width", "80px") ] ++ floorPropertyLabel

floorWidthText : S
floorWidthText =
  floorPropertyText

floorHeightText : S
floorHeightText =
  floorPropertyText

floorPropertyLastUpdate : S
floorPropertyLastUpdate =
  formControl


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

editingToggleContainer : Bool -> S
editingToggleContainer editing =
  flex ++
    [ ("width", "100px")
    , ("cursor", "pointer")
    , ("opacity", if editing then "1" else "")
    ]

editingToggleIcon : S
editingToggleIcon =
  [ ("padding-top", "7px")
  ]

editingToggleText : S
editingToggleText =
  [ ("margin-left", "5px")
  , ("margin-top", "5px")
  , ("line-height", "30px")
  , ("width", "150px")
  , ("user-select", "none")
  ]

greetingContainer : S
greetingContainer =
  flex ++
    [ ("width", "150px")
    ]

greetingImage : S
greetingImage =
  [ ("width", "24px")
  , ("height", "24px")
  , ("margin-top", "6px")
  , ("border", "solid 1px #888")
  ]

greetingName : S
greetingName =
  [ ("margin-left", "10px")
  , ("margin-top", "5px")
  , ("line-height", "30px")
  ]

closePrint : S
closePrint =
  [ ("width", "80px")
  , ("cursor", "pointer")
  ] ++ headerMenuItem

login : S
login =
  [ ("width", "80px")
  , ("cursor", "pointer")
  ] ++ headerMenuItem

logout : S
logout =
  [ ("width", "80px")
  , ("cursor", "pointer")
  ] ++ headerMenuItem

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
    ]

searchResultItemInner : Bool -> Bool -> S
searchResultItemInner selectable selected =
  -- [("background-color", if selected then hoverBackgroundColor else "")]
  [ ("text-decoration", if selectable then "underline" else "")
  , ("cursor", if selectable then "pointer" else "")
  , ("font-weight", if selected then "bold" else "")
  ]
  ++ flex


floorsInfoView : S
floorsInfoView =
    [ ("position", "absolute")
    , ("display", "flex")
    , ("z-index", zIndex.floorInfo)
    ]

floorsInfoViewItem : Bool -> Bool -> S
floorsInfoViewItem selected private =
    [ ("background-color", if private then "#dbdbdb" else "#fff")
    , ("border-right", if selected then "solid 2px " ++ selectColor else "solid 1px #d0d0d0")
    , ("border-bottom", if selected then "solid 2px " ++ selectColor else "solid 1px #d0d0d0")
    , ("border-top", if selected then "solid 2px " ++ selectColor else "none")
    , ("border-left", if selected then "solid 2px " ++ selectColor else "none")
    , ("min-width", "60px")
    , ("box-sizing", "border-box")
    , ("height", "37px")
    , ("position", "relative")
    ]

floorsInfoViewItemLink : S
floorsInfoViewItemLink =
    [ ("text-decoration", "none")
    , ("display", "block")
    , ("left", "0")
    , ("right", "0")
    , ("position", "absolute")
    , ("text-align", "center")
    , ("vertical-align", "middle")
    , ("line-height", "37px")
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

popup : Int -> S
popup padding =
    [ ("box-sizing", "border-box")
    , ("padding", px padding)
    , ("background-color", "#fff")
    , ("position", "absolute")
    ]

defaultPopup : S
defaultPopup =
  popup 20

smallPopup : S
smallPopup =
  popup 10

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
  defaultPopup ++
    [ ("left", "20%")
    , ("right", "20%")
    , ("top", "10%")
    , ("bottom", "10%")
    ] ++ shadow

diffPopupHeader : S
diffPopupHeader =
  [ ("margin", "0")
  , ("position", "absolute")
  , ("height", "60px")
  , ("line-height", "60px")
  , ("right", "0")
  , ("left", "0")
  ]

diffPopupBody : S
diffPopupBody =
  [ ("overflow-y", "scroll")
  , ("position", "absolute")
  , ("top", "60px")
  , ("bottom", "50px")
  , ("right", "0")
  , ("left", "0")
  ]

diffPopupFooter : S
diffPopupFooter =
  [ ("bottom", "0")
  , ("position", "absolute")
  , ("right", "0")
  , ("left", "0")
  ] ++ flex

diffPopupCancelButton : S
diffPopupCancelButton =
  defaultButton

diffPopupConfirmButton : S
diffPopupConfirmButton =
  primaryButton ++ [ ("margin-left", "20px") ]

diffPopupInnerContainer : S
diffPopupInnerContainer =
  [ ("position", "relative")
  , ("height", "100%")
  ]


personDetailPopup : Int -> Int -> (Int, Int) -> S
personDetailPopup width height (x, y) =
  shadow ++
    [ ("width", px width)
    , ("height", px height)
    , ("left", px (ProfilePopupLogic.calcPopupLeftFromEquipmentCenter width x))
    , ("top", px (ProfilePopupLogic.calcPopupTopFromEquipmentTop height y))
    , ("z-index", zIndex.personDetailPopup)
    ]


personDetailPopupDefault : Int -> Int -> (Int, Int) -> S
personDetailPopupDefault width height (x, y) =
  defaultPopup ++ personDetailPopup width height (x, y)


personDetailPopupSmall : (Int, Int) -> S
personDetailPopupSmall (x, y) =
  smallPopup ++ personDetailPopup 80 40 (x, y)


personDetailPopupNoPerson : S
personDetailPopupNoPerson =
  [ ("text-align", "center")
  , ("overflow", "hidden")
  , ("text-overflow", "ellipsis")
  ]


popupPointerBase : S
popupPointerBase =
    [ ("width", "20px")
    , ("height", "20px")
    , ("position", "absolute")
    , ("background-color", "#fff")
    ]

popupPointerButtom : S
popupPointerButtom =
    popupPointerBase ++
      [ ("transform", "rotate(45deg)")
      , ("box-shadow", "rgba(0, 0, 0, 0.237255) 2px 2px 5px 0px")
      ]

popupPointerLeft : S
popupPointerLeft =
    popupPointerBase ++
      [ ("transform", "rotate(45deg)")
      , ("box-shadow", "rgba(0, 0, 0, 0.237255) -1.5px 1.5px 4.5px 0px")
      ]


personDetailPopupPointer : Int -> S
personDetailPopupPointer width =
  popupPointerButtom ++
    [ ("bottom", "-10px")
    , ("left", px (width // 2 - 20 // 2))
    ]


personDetailPopupPointerDefault : Int -> S
personDetailPopupPointerDefault width =
  personDetailPopupPointer width


personDetailPopupPointerSmall : S
personDetailPopupPointerSmall =
  personDetailPopupPointer 80


personDetailPopupClose : S
personDetailPopupClose =
  [ ("position", "absolute")
  , ("top", "10px")
  , ("right", "10px")
  ]

personDetailPopupPersonImage : S
personDetailPopupPersonImage =
  [ ("position", "absolute")
  , ("top", "15px")
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
  , ("left", "100px")
  ]

personDetailPopupPersonOrg : S
personDetailPopupPersonOrg =
  [ ("position", "absolute")
  , ("font-size", "small")
  , ("top", "105px")
  ]

personDetailPopupPersonTel : S
personDetailPopupPersonTel =
  flex ++
    [ ("position", "absolute")
    , ("top", "50px")
    , ("left", "100px")
    ]

personDetailPopupPersonMail : S
personDetailPopupPersonMail =
  flex ++
    [ ("position", "absolute")
    , ("top", "70px")
    , ("left", "100px")
    ]

personDetailPopupPersonIconText : S
personDetailPopupPersonIconText =
  [ ("margin-left", "5px")
  , ("font-size", "small")
  ]


candidateItemHeight : Int
candidateItemHeight = 55


candidatesViewContainer : (Int, Int, Int, Int) -> Bool -> Int -> S
candidatesViewContainer screenRectOfDesk relatedPersonExists candidateLength =
  let
    (x, y, w, h) = screenRectOfDesk
    totalHeight =
      (if relatedPersonExists then 160 else 0) +
      (candidateItemHeight * candidateLength)
    left = x + w + 15
    top = Basics.max 10 (y - totalHeight // 2)
  in
    [ ("position", "absolute")
    , ("top", px top)
    , ("left", px left)
    , ("z-index", zIndex.candidatesView)
    ] ++ shadow


candidateViewPointer : (Int, Int, Int, Int) -> S
candidateViewPointer screenRectOfDesk =
  let
    (x, y, w, h) = screenRectOfDesk
    left = x + w + 5
    top = y + 10
  in
    popupPointerLeft ++
      [ ("top", px top)
      , ("left", px left)
      -- , ("z-index", zIndex.candidatesView)
      ]

candidatesView : S
candidatesView =
  []


candidatesViewRelatedPerson : S
candidatesViewRelatedPerson =
  [ ("width", "300px")
  , ("height", "160px")
  , ("position", "relative")
  , ("padding", "15px")
  , ("background-color", "#fff")
  , ("border-bottom", "solid 1px #ddd")
  ]

candidateItem : Bool -> S
candidateItem selected =
  [ ("width", "300px")
  , ("height", px candidateItemHeight)
  , ("position", "relative")
  , ("padding", "15px")
  , ("border-bottom", "solid 1px #ddd")
  , ("background-color", if selected then hoverBackgroundColor else "#fff")
  , ("cursor", "pointer")
  ]


candidateItemHover : S
candidateItemHover =
  [ ("background-color", hoverBackgroundColor)
  ]


candidateItemPersonName : S
candidateItemPersonName =
  [ ("position", "absolute")
  , ("fon-size", "larger")
  , ("font-weight", "bold")
  , ("top", "15px")
  ]

candidateItemPersonMail : S
candidateItemPersonMail =
  flex ++
    [ ("position", "absolute")
    , ("left", "100px")
    ]

candidateItemPersonOrg : S
candidateItemPersonOrg =
  [ ("position", "absolute")
  , ("font-size", "small")
  , ("top", "40px")
  ]

unsetRelatedPersonButton : S
unsetRelatedPersonButton =
  [ ("top", "15px")
  , ("right", "15px")
  , ("padding", "5px")
  , ("background-color", "#fff")
  , ("color", "#ddd")
  , ("border", "solid 1px #ddd")
  , ("cursor", "pointer")
  , ("display", "inline-block")
  , ("position", "absolute")
  ]

unsetRelatedPersonButtonHover : S
unsetRelatedPersonButtonHover =
  [ ("background-color", "#a66")
  , ("color", "#fff")
  ]

messageBar : S
messageBar =
    [ ("position", "absolute")
    , ("color", "#fff")
    , ("width", "100%")
    , ("z-index", zIndex.messageBar)
    , ("padding", "5px 10px")
    -- , ("height", "29px")
    , ("transition", "height") -- TODO ?
    , ("box-sizing", "border-box")
    , ("transition", "opacity 0.8s linear") -- TODO ?
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
  , ("height", "20px")
  , ("margin-top", "-2px")
  ]


nameInputContainer : S
nameInputContainer =
  [ ("position", "relative")
  ]
