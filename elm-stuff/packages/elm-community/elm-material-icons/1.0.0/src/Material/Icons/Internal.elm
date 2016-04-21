module Material.Icons.Internal where

import Color  exposing (Color)
import Svg    exposing (Svg)
import Svg.Attributes


icon : String -> Color -> Int -> Svg
icon path color size =
  let
      stringSize = toString size

      stringColor = toRgbaString color
  in
      Svg.svg
          [ Svg.Attributes.width stringSize
          , Svg.Attributes.height stringSize
          , Svg.Attributes.viewBox "0 0 24 24"
          ]
          [ Svg.path
                [ Svg.Attributes.d path
                , Svg.Attributes.fill stringColor  
                ]
                []
          ]


toRgbaString : Color -> String
toRgbaString color =
  let {red, green, blue, alpha} = Color.toRgb color
  in
      "rgba(" ++ toString red
       ++ "," ++ toString green
       ++ "," ++ toString blue
       ++ "," ++ toString alpha
       ++ ")"
