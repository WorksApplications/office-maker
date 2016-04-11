module Styles where

--import Html.Attributes exposing (Attributes, style)

type alias S = List (String, String)

zIndex :
  { selectedDesk : String
  , deskInput : String
  , selectorRect : String
  , subMenu : String
  , contextMenu : String
  }
zIndex =
  { selectedDesk = "100"
  , deskInput = "200"
  , selectorRect = "300"
  , subMenu = "600"
  , contextMenu = "800"
  }

noMargin : S
noMargin =
  [ ( "margin", "0") ]

noPadding : S
noPadding =
  [ ( "padding", "0") ]

flex : S
flex =
  [ ( "display", "flex") ]

flexMain : S
flexMain =
  [ ( "flex", "2"), ("background", "#000") ]

flexSub : S
flexSub =
  [ ( "flex", "1"), ("background", "#eee") ]

h1 : S
h1 =
  noMargin ++
    [ ( "font-size", "1.4em")
    , ("font-weight", "normal")
    , ("font-family", "'Roboto'") ]

ul : S
ul =
  [ ("list-style-type", "none")
  , ("padding-left", "0") ]

header : S
header =
  noMargin ++
    [ ( "background", "rgb(100, 180, 85)")
    , ("color", "#eee")
    , ("padding", "5px 10px")
    ]

rect : (Int, Int, Int, Int) -> S
rect (x, y, w, h) =
  [ ("top", toString y ++ "px")
  , ("left", toString x ++ "px")
  , ("width", toString w ++ "px")
  , ("height", toString h ++ "px")
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
  , ("border-color", "#69e")
  ]

colorProperty : String -> Bool -> S
colorProperty color selected =
  [ ("background-color", color)
  , ("width", "30px")
  , ("height", "30px")
  , ("box-sizing", "border-box")
  , ("border-style", "solid")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then "#69e" else "#666")
  ]

subMenu : S
subMenu =
  flexSub ++ [("z-index", zIndex.subMenu)]

contextMenu : (Int, Int) -> (Int, Int) -> Int -> S
contextMenu (x, y) (windowWidth, windowHeight) rows =
  let
    width = 200
    height = rows * 20 --TODO
    x' = min x (windowWidth - width)
    y' = min y (windowHeight - height)
  in
    [ ("width", toString width ++ "px")
    , ("left", toString x' ++ "px")
    , ("top", toString y' ++ "px")
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
    ]


nameLabel : Int -> S
nameLabel scaleDown =
  [ ("display", "table-cell")
  , ("vertical-align", "middle")
  , ("text-align", "center")
  , ("position", "absolute")
  , ("cursor", "default")
  , ("font-size", (toString (1 / toFloat (2 ^ scaleDown))) ++ "em") --TODO
   -- TODO vertical align
  ]

card : S
card =
  [ ("margin", "5px")
  , ("padding", "5px")
  , ("box-shadow", "0 2px 2px 0 rgba(0,0,0,.14),0 3px 1px -2px rgba(0,0,0,.2),0 1px 5px 0 rgba(0,0,0,.12)")
  ]
