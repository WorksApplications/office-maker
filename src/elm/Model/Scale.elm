module Model.Scale exposing (..)


type Msg = ScaleUp | ScaleDown


type alias Scale =
  { scaleDown : Int
  }


default : Scale
default = init 0


init : Int -> Scale
init scaleDown =
  { scaleDown = scaleDown
  }


update : Msg -> Scale -> Scale
update msg scale =
  case msg of
    ScaleUp ->
      { scale | scaleDown = max 0 (scale.scaleDown - 1) }

    ScaleDown ->
      { scale | scaleDown = min 4 (scale.scaleDown + 1) }


screenToImageForPosition : Scale -> (Int, Int) -> (Int, Int)
screenToImageForPosition scale (screenX, screenY) =
  ( screenToImage scale screenX
  , screenToImage scale screenY)


imageToScreenForPosition : Scale -> (Int, Int) -> (Int, Int)
imageToScreenForPosition scale (imageX, imageY) =
  ( imageToScreen scale imageX
  , imageToScreen scale imageY)


imageToScreenForRect : Scale -> (Int, Int, Int, Int) -> (Int, Int, Int, Int)
imageToScreenForRect scale (x, y, w, h) =
  ( imageToScreen scale x
  , imageToScreen scale y
  , imageToScreen scale w
  , imageToScreen scale h
  )


screenToImageForRect : Scale -> (Int, Int, Int, Int) -> (Int, Int, Int, Int)
screenToImageForRect scale (x, y, w, h) =
  ( screenToImage scale x
  , screenToImage scale y
  , screenToImage scale w
  , screenToImage scale h
  )


screenToImage : Scale -> Int -> Int
screenToImage scale imageLength =
  imageLength * (2 ^ scale.scaleDown)


imageToScreen : Scale -> Int -> Int
imageToScreen scale screenLength =
  screenLength // (2 ^ scale.scaleDown)


imageToScreenRatio : Scale -> Float
imageToScreenRatio scale =
  1.0 / (2 ^ (toFloat scale.scaleDown))


ratio : Scale -> Scale -> Float
ratio old new =
  (toFloat (2 ^ old.scaleDown)) / (toFloat (2 ^ new.scaleDown))
