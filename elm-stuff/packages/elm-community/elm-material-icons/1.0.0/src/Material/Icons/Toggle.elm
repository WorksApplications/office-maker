module Material.Icons.Toggle where

{-|

# Icons
@docs check_box
@docs check_box_outline_blank
@docs indeterminate_check_box
@docs radio_button_checked
@docs radio_button_unchecked
@docs star
@docs star_border
@docs star_half

-}

import Svg                      exposing (Svg)
import Svg.Attributes
import Color                    exposing (Color)
import Material.Icons.Internal  exposing (icon, toRgbaString)
import VirtualDom
{-|-}
check_box : Color -> Int -> Svg
check_box =
  icon "M19 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.11 0 2-.9 2-2V5c0-1.1-.89-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"
{-|-}
check_box_outline_blank : Color -> Int -> Svg
check_box_outline_blank =
  icon "M19 5v14H5V5h14m0-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z"
{-|-}
indeterminate_check_box : Color -> Int -> Svg
indeterminate_check_box color size =
  let
      stringSize = toString size

      stringColor = toRgbaString color

  in
      Svg.svg
          [ Svg.Attributes.width stringSize
          , Svg.Attributes.height stringSize
          , Svg.Attributes.viewBox "0 0 24 24"
          ]
          [ Svg.defs
                []
                [ Svg.path
                      [ Svg.Attributes.id "a"
                      , Svg.Attributes.d "M0 0h24v24H0z"
                      ]
                      []
                ]
          , VirtualDom.node "clipPath"
                [ Svg.Attributes.id "b" ]
                [ Svg.use
                      [ Svg.Attributes.xlinkHref "#a"
                      , Svg.Attributes.overflow "visible"
                      ]
                      []

                ]
          , Svg.path
                [ Svg.Attributes.d "M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 10H7v-2h10v2z"
                , Svg.Attributes.clipPath "url(#b)"
                , Svg.Attributes.fill stringColor
                ]
                []

          ]
{-|-}
radio_button_checked : Color -> Int -> Svg
radio_button_checked =
  icon "M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm0-5C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"
{-|-}
radio_button_unchecked : Color -> Int -> Svg
radio_button_unchecked =
  icon "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"
{-|-}
star : Color -> Int -> Svg
star =
  icon "M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"
{-|-}
star_border : Color -> Int -> Svg
star_border =
  icon "M22 9.24l-7.19-.62L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27 18.18 21l-1.63-7.03L22 9.24zM12 15.4l-3.76 2.27 1-4.28-3.32-2.88 4.38-.38L12 6.1l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.4z"
{-|-}
star_half : Color -> Int -> Svg
star_half =
  icon "M22 9.74l-7.19-.62L12 2.5 9.19 9.13 2 9.74l5.46 4.73-1.64 7.03L12 17.77l6.18 3.73-1.63-7.03L22 9.74zM12 15.9V6.6l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.9z"
