module Styles where

--import Html.Attributes exposing (Attributes, style)

type alias S = List (String, String)

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
  [ ( "flex", "2"), ("height", "600px") ]

flexSub : S
flexSub =
  [ ( "flex", "1"), ("background", "#eee") ]

h1 : S
h1 = noMargin

ul : S
ul = [ ("list-style-type", "none"), ("padding-left", "0") ]


header : S
header =
  noMargin ++ [ ( "background", "#555"), ("color", "#eee") ]

rect : Int -> Int -> Int -> Int -> S
rect x y w h =
  [ ("top", toString y ++ "px")
  , ("left", toString x ++ "px")
  , ("width", toString w ++ "px")
  , ("height", toString h ++ "px")
  ]

absoluteRect : Int -> Int -> Int -> Int -> S
absoluteRect x y w h =
  ("position", "absolute") :: (rect x y w h)

deskInput : Int -> Int -> Int -> Int -> S
deskInput x y w h =
  (absoluteRect x y w h) ++ noPadding ++ [ ("z-index", zIndex.deskInput)
  , ("box-sizing", "border-box")
  ]

desk : Int -> Int -> Int -> Int -> String -> Bool -> Bool -> S
desk x y w h color selected alpha =
  (absoluteRect x y w h) ++ [ ("opacity", if alpha then "0.5" else "1.0")
  , ("background-color", color)
  , ("box-sizing", "border-box")
  , ("z-index", if selected then zIndex.selectedDesk else "")
  , ("border-style", "solid")
  , ("border-width", if selected  then "2px" else "1px")
  , ("border-color", if selected  then "#69e" else "#666")
  ]

selectorRect : Int -> Int -> Int -> Int -> S
selectorRect x y w h =
  (absoluteRect x y w h) ++ [("z-index", zIndex.selectorRect)
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
    height = rows * 20
    x' = min x (windowWidth - width)
    y' = min y (windowHeight - height)
  in
    (rect x' y' width height) ++
      [ ("position", "fixed")
      , ("z-index", zIndex.contextMenu)
      , ("background-color", "#fff")
      , ("box-sizing", "border-box")
      , ("border-style", "solid")
      , ("border-width", "1px")
      , ("border-color", "#eee")
      ]
