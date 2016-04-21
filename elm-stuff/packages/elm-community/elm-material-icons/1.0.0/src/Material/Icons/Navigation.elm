module Material.Icons.Navigation where

{-|

# Icons
@docs apps
@docs arrow_back
@docs arrow_drop_down
@docs arrow_drop_down_circle
@docs arrow_drop_up
@docs arrow_forward
@docs cancel
@docs check
@docs chevron_left
@docs chevron_right
@docs close
@docs expand_less
@docs expand_more
@docs fullscreen
@docs fullscreen_exit
@docs menu
@docs more_horiz
@docs more_vert
@docs refresh
@docs unfold_less
@docs unfold_more


-}

import Svg                      exposing (Svg)
import Svg.Attributes
import Color                    exposing (Color)
import Material.Icons.Internal  exposing (icon, toRgbaString)
import VirtualDom
{-|-}
apps : Color -> Int -> Svg
apps =
  icon "M4 8h4V4H4v4zm6 12h4v-4h-4v4zm-6 0h4v-4H4v4zm0-6h4v-4H4v4zm6 0h4v-4h-4v4zm6-10v4h4V4h-4zm-6 4h4V4h-4v4zm6 6h4v-4h-4v4zm0 6h4v-4h-4v4z"
{-|-}
arrow_back : Color -> Int -> Svg
arrow_back =
  icon "M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"
{-|-}
arrow_drop_down : Color -> Int -> Svg
arrow_drop_down =
  icon "M7 10l5 5 5-5z"
{-|-}
arrow_drop_down_circle : Color -> Int -> Svg
arrow_drop_down_circle =
  icon "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 12l-4-4h8l-4 4z"
{-|-}
arrow_drop_up : Color -> Int -> Svg
arrow_drop_up =
  icon "M7 14l5-5 5 5z"
{-|-}
arrow_forward : Color -> Int -> Svg
arrow_forward =
  icon "M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z"
{-|-}
cancel : Color -> Int -> Svg
cancel =
  icon "M12 2C6.47 2 2 6.47 2 12s4.47 10 10 10 10-4.47 10-10S17.53 2 12 2zm5 13.59L15.59 17 12 13.41 8.41 17 7 15.59 10.59 12 7 8.41 8.41 7 12 10.59 15.59 7 17 8.41 13.41 12 17 15.59z"
{-|-}
check : Color -> Int -> Svg
check =
  icon "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"
{-|-}
chevron_left : Color -> Int -> Svg
chevron_left =
  icon "M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"
{-|-}
chevron_right : Color -> Int -> Svg
chevron_right =
  icon "M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"
{-|-}
close : Color -> Int -> Svg
close =
  icon "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"
{-|-}
expand_less : Color -> Int -> Svg
expand_less =
  icon "M12 8l-6 6 1.41 1.41L12 10.83l4.59 4.58L18 14z"
{-|-}
expand_more : Color -> Int -> Svg
expand_more =
  icon "M16.59 8.59L12 13.17 7.41 8.59 6 10l6 6 6-6z"
{-|-}
fullscreen : Color -> Int -> Svg
fullscreen =
  icon "M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"
{-|-}
fullscreen_exit : Color -> Int -> Svg
fullscreen_exit =
  icon "M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"
{-|-}
menu : Color -> Int -> Svg
menu =
  icon "M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"
{-|-}
more_horiz : Color -> Int -> Svg
more_horiz =
  icon "M6 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm12 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm-6 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"
{-|-}
more_vert : Color -> Int -> Svg
more_vert =
  icon "M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"
{-|-}
refresh : Color -> Int -> Svg
refresh =
  icon "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"
{-|-}
unfold_less : Color -> Int -> Svg
unfold_less =
  icon "M7.41 18.59L8.83 20 12 16.83 15.17 20l1.41-1.41L12 14l-4.59 4.59zm9.18-13.18L15.17 4 12 7.17 8.83 4 7.41 5.41 12 10l4.59-4.59z"
{-|-}
unfold_more : Color -> Int -> Svg
unfold_more =
  icon "M12 5.83L15.17 9l1.41-1.41L12 3 7.41 7.59 8.83 9 12 5.83zm0 12.34L8.83 15l-1.41 1.41L12 21l4.59-4.59L15.17 15 12 18.17z"
