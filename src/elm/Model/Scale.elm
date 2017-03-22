module Model.Scale exposing (..)


import CoreType exposing (..)


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


screenToImageForPosition : Scale -> Position -> Position
screenToImageForPosition scale screenPosition =
  Position
    (screenToImage scale screenPosition.x)
    (screenToImage scale screenPosition.y)


imageToScreenForPosition : Scale -> Position -> Position
imageToScreenForPosition scale imagePosition =
  Position
    (imageToScreen scale imagePosition.x)
    (imageToScreen scale imagePosition.y)


imageToScreenForSize : Scale -> Size -> Size
imageToScreenForSize scale { width, height } =
  Size (imageToScreen scale width) (imageToScreen scale height)


screenToImageForSize : Scale -> Size -> Size
screenToImageForSize scale { width, height } =
  Size (screenToImage scale width) (screenToImage scale height)


imageToScreenForRect : Scale -> Position -> Size -> (Position, Size)
imageToScreenForRect scale pos size =
  ( imageToScreenForPosition scale pos
  , imageToScreenForSize scale size
  )


screenToImageForRect : Scale -> Position -> Size -> (Position, Size)
screenToImageForRect scale pos size =
  ( screenToImageForPosition scale pos
  , screenToImageForSize scale size
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
