module View.Styles exposing (..)

import Model.ProfilePopupLogic as ProfilePopupLogic
import Util.StyleUtil exposing (..)
import View.CommonStyles as Common exposing (..)
import CoreType exposing (..)


type alias S = List (String, String)


zIndex :
  { labelObject : String
  , selectedDesk : String
  , selectedLabelObject : String
  , deskInput : String
  , selectorRect : String
  , floorInfo : String
  , personDetailPopup : String
  , candidatesView : String
  , lastUpdate : String
  , subView : String
  , headerForPrint : String
  , printGuide : String
  , messageBar : String
  , modalBackground : Int
  , userMenuView : String
  }
zIndex =
  { labelObject = "50"
  , selectedDesk = "100"
  , selectedLabelObject = "100"
  , deskInput = "200"
  , selectorRect = "300"
  , floorInfo = "500"
  , personDetailPopup = "550"
  , lastUpdate = "580"
  , subView = "600"
  , headerForPrint = "630"
  , printGuide = "650"
  , candidatesView = "660"
  , messageBar = "700"
  , modalBackground = 900
  , userMenuView = "1000"
  }


h1 : S
h1 =
  noMargin ++
    [ ( "font-size", "1.4em")
    , ("font-weight", "normal")
    , ("line-height", px headerHeight)
    ]


headerLink : S
headerLink =
  []


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


header : Bool -> S
header printMode =
  noMargin ++
    [ ("height", px headerHeight)
    , ("padding-left", "10px")
    , ("padding-right", "10px")
    , ("display", "flex")
    , ("justify-content", "space-between")
    , ("position", "relative")
    ] ++
      ( if printMode then
          [ ("position", "absolute")
          , ("z-index", zIndex.headerForPrint)
          , ("width", "100%")
          ]
        else
          [ ("color", "#eee")
          , ("background", "rgb(100,100,120)")
          ]
      )


deskInput : Position -> Size -> S
deskInput pos size =
  let
    size_ =
      Size (max size.width 100) (max size.height 15)
  in
    absoluteRect pos size_ ++ noPadding ++
      [ ("z-index", zIndex.deskInput)
      , ("box-sizing", "border-box")
      ]


nameInputTextArea : Position -> Size -> S
nameInputTextArea screenPos screenSize =
  deskInput screenPos screenSize


deskObject : Position -> Size -> String -> Bool -> Bool -> S
deskObject pos size backgroundColor selected isGhost =
  (absoluteRect pos size) ++
  [ ("opacity", if isGhost then "0.5" else "1.0")
  , ("display", "table")
  , ("background-color", backgroundColor)
  , ("box-sizing", "border-box")
  , ("z-index", if selected then zIndex.selectedDesk else "")
  , ("border-style", "solid")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-top-color", if selected  then selectColor else "rgba(100,100,100,0.3)")
  , ("border-left-color", if selected  then selectColor else "rgba(100,100,100,0.3)")
  , ("border-bottom-color", if selected  then selectColor else "rgba(100,100,100,0.7)")
  , ("border-right-color", if selected  then selectColor else "rgba(100,100,100,0.7)")
  ] ++ noUserSelect


labelObject : Bool -> Position -> Size -> String -> String -> Bool -> Bool -> Bool -> S
labelObject isEllipse pos size backgroundColor fontColor selected isGhost rectVisible =
  absoluteRect pos size ++
  [ ("opacity", if isGhost then "0.5" else "1.0")
  , ("display", "table")
  , ("background-color",
      if backgroundColor == "" || backgroundColor == "transparent" then
        if rectVisible then "rgba(255,255,255,0.2)" else "transparent"
      else
        backgroundColor
    )
  , ("box-sizing", "border-box")
  , ("text-align", "center")
  , ("z-index", if selected then zIndex.selectedLabelObject else zIndex.labelObject)
  , ("border-style", if rectVisible then "dashed" else "none")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then selectColor else "rgba(100,100,100,0.3)")
  , ("border-radius", if isEllipse  then "50%" else "")
  ] ++ noUserSelect


deskResizeGrip : Bool -> S
deskResizeGrip selected =
  [ ("position", "absolute")
  , ("width", "8px")
  , ("height", "8px")
  , ("bottom", "-2px")
  , ("right", "-2px")
  , ("cursor", "nw-resize")
  ] ++
  ( if selected then
      [ ("border-bottom-style", "solid")
      , ("border-right-style", "solid")
      , ("border-width", "2px")
      , ("border-color", selectColor)
      ]
    else
      []
  )


selectorRect : Position -> Size -> S
selectorRect pos size =
  absoluteRect pos size ++
    [ ("z-index", zIndex.selectorRect)
    , ("border-style", "solid")
    , ("border-width", "2px")
    , ("border-color", selectColor)
    ]


colorProperties : S
colorProperties =
  [("display", "flex")]


propertyViewPropertyIcon : S
propertyViewPropertyIcon =
  [ ("width", "12px") ]


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
  , ("border-color", if selected  then selectColor else "#666")
  , ("font-size", "12px")
  ]


shapeProperties : S
shapeProperties =
  flex


shapeProperty : Bool -> S
shapeProperty selected =
  [ ("cursor", "pointer")
  , ("width", "24px")
  , ("height", "24px")
  , ("box-sizing", "border-box")
  , ("border-style", "solid")
  , ("margin-right", "2px")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then selectColor else "#666")
  ]


subView : S
subView =
    [ ("z-index", zIndex.subView)
    , ("width", "320px")
    , ("position", "absolute")
    , ("right", "0")
    ]


canvasView : Bool -> Bool -> Position -> Size -> S
canvasView transition isViewing pos size =
  absoluteRect pos size ++
    [ ("font-family", "default")
    , ("background-color", "#fff")
    , ("transition", if transition then "top 0.3s ease, left 0.3s ease" else "")
    ] ++ noUserSelect ++ (if isViewing then [("overflow", "hidden")] else [])


canvasViewForPrint : Size -> Size -> S
canvasViewForPrint windowSize size =
  let
    scale =
      toString
        ( min
            (toFloat windowSize.width / toFloat size.width)
            (toFloat windowSize.height / toFloat size.height)
        )
  in
    [ ("background-color", "#fff")
    , ("font-family", "default")
    , ("position", "absolute")
    , ("width", px size.width)
    , ("height", px size.height)
    , ("transform", "scale(" ++ scale ++ ")")
    , ("transform-origin", "top left")
    , ("overflow", "hidden")
    ]


canvasImage : S
canvasImage =
  [ ("position", "absolute")
  , ("top", "0")
  , ("left", "0")
  , ("width", "100%")
  , ("height", "100%")
  , ("pointer-events", "none")
  ]


gridLayer : S
gridLayer =
  [ ("position", "relative")
  , ("top", "0")
  , ("left", "0")
  , ("width", "100%")
  , ("height", "100%")
  ]


gridBorderValue : String
gridBorderValue = "dotted 1px #ccc"


gridLayerVirticalLine : Int -> S
gridLayerVirticalLine left =
  [ ("border-right", gridBorderValue)
  , ("position", "absolute")
  , ("left", px left)
  , ("height", "100%")
  ]


gridLayerHorizontalLine : Int -> S
gridLayerHorizontalLine top =
  [ ("border-bottom", gridBorderValue)
  , ("position", "absolute")
  , ("top", px top)
  , ("width", "100%")
  ]


nameLabel : String -> Float -> number -> S
nameLabel color scale fontSize =
  [ ("color", color)
  , ("text-align", "center")
  , ("position", "absolute")
  , ("cursor", "default")
  , ("font-size", px fontSize)
  , ("width", percent (100 / scale))
  , ("word-wrap", "break-word")
  , ("top", "50%")
  , ("transform", "translateY(-50%) scale(" ++ toString scale ++ ")")
  , ("transform-origin", "left")
  ] ++ noMargin


shadow : S
shadow =
  [ ("box-shadow", "0 2px 2px 0 rgba(0,0,0,.14),0 3px 1px -2px rgba(0,0,0,.2),0 1px 5px 0 rgba(0,0,0,.12)") ]


modeSelectionView : S
modeSelectionView =
  formControl ++ flex


modeSelectionViewEach : Bool -> S
modeSelectionViewEach selected =
  [ ("cursor", "pointer")
  , ("padding-top", "8px")
  , ("padding-bottom", "4px")
  , ("text-align", "center")
  , ("box-sizing", "border-box")
  , ("margin-right", "-1px")
  , ("border", "solid 1px #666")
  , ("background-color", if selected then selectColor else "inherit")
  , ("color", if selected then invertedTextColor else "inherit")
  , ("flex-grow", "1")
  ]


pasteFromSpreadsheetInput : S
pasteFromSpreadsheetInput =
  input ++ formControl


prototypePreviewView : Int -> Int -> S
prototypePreviewView width height =
  [ ("width", px width)
  , ("height", px height)
  , ("position", "relative")
  , ("border-style", "solid")
  , ("border-width", "1px")
  , ("border-color", "#666")
  , ("box-sizing", "border-box")
  , ("margin-top", "10px")
  , ("background-color", "#fff")
  , ("overflow", "hidden")
  ]


prototypePreviewViewInner : Int -> Int -> S
prototypePreviewViewInner containerWidth index =
  [ ("height", "238px")
  , ("position", "relative")
  , ("top", "0")
  , ("left", px (index * -containerWidth))
  , ("transition-property", "left")
  , ("transition-duration", "0.2s")
  ]


prototypePreviewScroll : Bool -> S
prototypePreviewScroll isLeft =
  (if isLeft then "left" else "right", "3px") ::
  [ ("width", "30px")
  , ("height", "30px")
  , ("font-size", "large")
  , ("font-weight", "bold")
  , ("line-height", "30px")
  , ("position", "absolute")
  , ("top", "104px")
  , ("border-radius", "15px")
  , ("text-align", "center")
  , ("color", invertedTextColor)
  , ("background-color", "#ccc")
  , ("cursor", "pointer")
  ]


floorPropertyLabel : S
floorPropertyLabel =
  [ ("display", "block")
  , ("line-height", "30px")
  , ("text-align", "right")
  , ("margin-right", "10px")
  , ("font-size", "15px")
  ]


floorPropertyText : S
floorPropertyText =
  [ ("width", "100%")
  , ("height", "30px")
  , ("padding", "6px 12px")
  , ("box-sizing", "border-box")
  , ("font-size", "13px")
  , ("border-bottom", "1px dotted #aaa")
  ]


imageLoadButton : S
imageLoadButton =
  formControl ++ defaultButton


imageDownloadButton : S
imageDownloadButton =
  formControl ++ defaultButton


publishButton : S
publishButton =
  formControl ++ primaryButton


deleteFloorButton : S
deleteFloorButton =
  formControl ++ defaultButton


deleteFloorButtonHover : S
deleteFloorButtonHover =
  formControl ++ dangerButton


floorNameInputContainer : S
floorNameInputContainer =
  formControl ++ flex


floorNameInput : S
floorNameInput =
  input ++
    [ ("display", "block")
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
  [ ("z-index", zIndex.lastUpdate)
  , ("position", "fixed")
  , ("left", "0")
  , ("bottom", "0")
  , ("background-color", "#fff")
  , ("padding", "5px 20px")
  , ("box-shadow", "rgba(0, 0, 0, 0.237255) 2px 0px 5px 0px")
  ]


floorPropertyLastUpdateForPrint : S
floorPropertyLastUpdateForPrint =
  [ ("position", "fixed")
  , ("left", "0")
  , ("top", "34px")
  , ("padding", "5px 10px")
  , ("font-size", "14px")
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
    , ("line-height", px headerHeight)
    , ("font-size", "15px")
    ]


userMenuToggleIcon : S
userMenuToggleIcon =
  [ ("margin-top", "10px")
  , ("right", "10px")
  , ("position", "absolute")
  ]


userMenuView : S
userMenuView =
  [ ("position", "absolute")
  , ("background", "rgb(100, 100, 120)")
  , ("box-shadow", "rgba(0, 0, 0, 0.2) 0px 3px 4px inset")
  , ("padding", "10px")
  , ("top", px headerHeight)
  , ("width", px 150)
  , ("z-index", zIndex.userMenuView)
  ]


langSelectView : S
langSelectView =
  flex ++ userMenuItem


langSelectViewItem : Bool -> S
langSelectViewItem selected =
  [ ("background-color", if selected then selectColor else "")
  , ("text-align", "center")
  , ("flex-grow", "1")
  , ("cursor", "pointer")
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
  ] ++ noUserSelect


userMenuToggle : S
userMenuToggle =
  flex ++
    [ ("width", "150px")
    , ("box-sizing", "border-box")
    , ("position", "relative")
    , ("cursor", "pointer")
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


userMenuItem : S
userMenuItem =
  [ ("margin", "10px 0") ]


searchBoxContainer : S
searchBoxContainer =
  [ ("box-shadow", "white")
  , ("top", "0")
  , ("padding-right", "30px")
  , ("bottom", "0")
  , ("margin", "auto")
  , ("width", "400px")
  , ("height", "29px")
  , ("display", "flex")
  ]


searchBox : S
searchBox =
  input ++
    [ ("outline", "none")
    , ("box-shadow", "rgb(0, 0, 0) 0px 2px 6px -3px inset")
    , ("border", "solid 1px #445")
    , ("border-right", "none")
    , ("border-bottom-left-radius", "15px")
    , ("border-top-left-radius", "15px")
    ]


searchBoxSubmit : S
searchBoxSubmit =
  [ ("line-height", "30px")
  , ("padding", "0 15px 0 12px")
  , ("background-color", "inherit")
  , ("color", "white")
  , ("border", "solid 1px #445")
  , ("outline", "none")
  , ("cursor", "pointer")
  , ("border-bottom-right-radius", "15px")
  , ("border-top-right-radius", "15px")
  ]


floorsInfoView : S
floorsInfoView =
    [ ("position", "absolute")
    -- , ("display", "flex")
    , ("width", "calc(100% - 300px)")
    , ("z-index", zIndex.floorInfo)
    ]


floorsInfoViewItem : Bool -> Bool -> S
floorsInfoViewItem selected private =
    [ ("background-color", if private then "#dbdbdb" else "#fff")
    , ("border-right", if selected then "solid 2px " ++ selectColor else "solid 1px #d0d0d0")
    , ("border-bottom", if selected then "solid 2px " ++ selectColor else "solid 1px #d0d0d0")
    , ("border-top", if selected then "solid 2px " ++ selectColor else "none")
    , ("border-left", if selected then "solid 2px " ++ selectColor else "none")
    , ("min-width", "72px")
    , ("box-sizing", "border-box")
    , ("height", "30px")
    , ("position", "relative")
    , ("font-size", "12px")
    , ("float", "left")
    , ("cursor", "pointer")
    ]


floorsInfoViewItemLink : S
floorsInfoViewItemLink =
    [ ("display", "block")
    , ("text-align", "center")
    , ("vertical-align", "middle")
    , ("line-height", "30px")
    , ("padding", "0 8px")
    ]


personMatchingInfo : Float -> S
personMatchingInfo ratio =
    [ ("border-radius", px (10 * ratio))
    , ("width", px (20 * ratio))
    , ("height", px (20 * ratio))
    , ("position", "absolute")
    ]


personMatched : Float -> S
personMatched ratio =
    personMatchingInfo ratio ++ [ ("background-color", "#6a6") ]


personNotMatched : Float -> S
personNotMatched ratio =
    personMatchingInfo ratio ++ [ ("background-color", "#ccc") ]


defaultPopup : S
defaultPopup =
  popup 20 "absolute"


smallPopup : S
smallPopup =
  popup 10 "absolute"


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


personDetailPopup : Bool -> Size -> Position -> S
personDetailPopup transition size pos =
  shadow ++
    [ ("width", px size.width)
    , ("height", px size.height)
    , ("left", px (ProfilePopupLogic.calcPopupLeftFromObjectCenter size.width pos.x))
    , ("top", px (ProfilePopupLogic.calcPopupTopFromObjectTop size.height pos.y))
    , ("z-index", zIndex.personDetailPopup)
    , ("transition", if transition then "top 0.3s ease, left 0.3s ease" else "")
    ]


personDetailPopupDefault : Bool -> Size -> Position -> S
personDetailPopupDefault transition size pos =
  defaultPopup ++ personDetailPopup transition size pos


personDetailPopupSmall : Bool -> Size -> Position -> S
personDetailPopupSmall transition size pos =
  smallPopup ++ personDetailPopup transition size pos


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


personDetailPopupPointer : Bool -> Int -> S
personDetailPopupPointer transition width =
  popupPointerButtom ++
    [ ("bottom", "-10px")
    , ("left", px (width // 2 - 20 // 2))
    , ("transition", if transition then "bottom 0.3s ease, left 0.3s ease" else "")
    ]


personDetailPopupPointerDefault : Bool -> Int -> S
personDetailPopupPointerDefault transition width =
  personDetailPopupPointer transition width


personDetailPopupPointerSmall : Bool -> Int -> S
personDetailPopupPointerSmall transition width =
  personDetailPopupPointer transition width


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

personDetailPopupPersonPost : S
personDetailPopupPersonPost =
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


candidatesViewContainer : Position -> Size -> Bool -> Int -> S
candidatesViewContainer screenPosOfDesk screenSizeOfDesk relatedPersonExists candidateLength =
  let
    totalHeight =
      (if relatedPersonExists then 160 else 0) +
      (candidateItemHeight * candidateLength)

    left =
      screenPosOfDesk.x + (max screenSizeOfDesk.width 100) + 15

    top =
      Basics.max 10 (screenPosOfDesk.y - totalHeight // 2)
  in
    [ ("position", "absolute")
    , ("top", px top)
    , ("left", px left)
    , ("z-index", zIndex.candidatesView)
    ] ++ shadow


candidateViewPointer : Position -> Size -> S
candidateViewPointer screenPosOfDesk screenSizeOfDesk =
  let
    left = screenPosOfDesk.x + screenSizeOfDesk.width + 5
    top = screenPosOfDesk.y + 10
  in
    popupPointerLeft ++
      [ ("top", px top)
      , ("left", px left)
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


candidateItemPersonPost : S
candidateItemPersonPost =
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
  , ("color", invertedTextColor)
  ]


messageBar : S
messageBar =
    [ ("position", "absolute")
    , ("color", invertedTextColor)
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
  [ ("height", px (windowHeight - headerHeight))
  , ("position", "relative")
  , ("overflow", "hidden")
  ] ++ flex



searchResultClose : S
searchResultClose =
  [ ("display", "flex")
  , ("float", "right")
  , ("height", "20px")
  , ("margin-bottom", "6px")
  , ("cursor", "pointer")
  ]


searchResult : S
searchResult =
  [ ("font-size", "14px")
  , ("clear", "both")
  ]


searchResultGroup : S
searchResultGroup =
  [ ("margin-bottom", "12px")
  ]


searchResultGroupHeader : S
searchResultGroupHeader =
  [ ("color", "#aaa")
  , ("margin-bottom", "5px")
  , ("cursor", "pointer")
  , ("font-size", "smaller")
  ]


searchResultGroupHeaderHover : S
searchResultGroupHeaderHover =
  [ ("text-decoration", "underline")
  ]


searchResultItem : Bool -> S
searchResultItem draggable =
  [ ("margin-top", "8px")
  , ("margin-bottom", "8px")
  ] ++
    ( if draggable then
        [ ("background-color", "#cde")
        , ("padding", "5px")
        , ("border", "solid 1px #aaa")
        , ("cursor", "move")
        ] ++ noUserSelect
      else
        []
    )


searchResultItemInner : S
searchResultItemInner =
  flex


searchResultItemInnerLabel : Bool -> Bool -> S
searchResultItemInnerLabel selectable selected =
  [ ("text-decoration", if selectable then "underline" else "")
  , ("cursor", if selectable then "pointer" else "")
  , ("font-weight", if selected then "bold" else "")
  ]


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



printGuideColor : String
printGuideColor =
  "rgb(200, 150, 220)"


printGuide : List (String, String)
printGuide =
  [ ("position", "fixed")
  , ("z-index", zIndex.printGuide)
  , ("top", "0")
  , ("left", "0")
  , ("pointer-events", "none")
  ]


printGuideItem : Int -> Int -> List (String, String)
printGuideItem width height =
  [ ("position", "fixed")
  , ("top", "0")
  , ("left", "0")
  , ("width", px width)
  , ("height", px height)
  , ("border", "dashed 5px " ++ printGuideColor)
  , ("font-size", "x-large")
  , ("font-weight", "bold")
  , ("color", printGuideColor)
  , ("text-align", "right")
  , ("padding-right", "3px")
  ]


printGuidePrintButton : List (String, String)
printGuidePrintButton =
  [ ("border", "2px solid " ++ printGuideColor)
  , ("color", "white")
  , ("margin", "auto")
  , ("position", "absolute")
  , ("top", "0")
  , ("bottom", "0")
  , ("left", "0")
  , ("right", "0")
  , ("width", "300px")
  , ("height", "150px")
  , ("line-height", "150px")
  , ("text-align", "center")
  , ("font-size", "3em")
  , ("font-weight", "normal")
  , ("cursor", "pointer")
  , ("background-color", printGuideColor)
  , ("opacity", "0.4")
  , ("pointer-events", "all")
  ]
