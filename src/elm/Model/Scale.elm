module Model.Scale exposing (..)


type Msg = ScaleUp | ScaleDown


type alias Scale =
  { scaleDown : Int
  }


type alias Position =
    { x : Int
    , y : Int
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
  { x = screenToImage scale screenPosition.x
  , y = screenToImage scale screenPosition.y
  }


imageToScreenForPosition : Scale -> Position -> Position
imageToScreenForPosition scale imagePosition =
  { x = imageToScreen scale imagePosition.x
  , y = imageToScreen scale imagePosition.y
  }


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
