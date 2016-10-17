module Util.StyleUtil exposing (..)


px : number -> String
px num =
  toString num ++ "px"


em : number -> String
em num =
  toString num ++ "em"


percent : number -> String
percent num =
  toString num ++ "%"


rgb : number -> number -> number -> String
rgb r g b =
  "rgb(" ++ toString r ++ "," ++ toString g ++ "," ++ toString b ++ ")"


rgba : number -> number -> number -> number -> String
rgba r g b a =
  "rgba(" ++ toString r ++ "," ++ toString g ++ "," ++ toString b ++ "," ++ toString a ++ ")"
