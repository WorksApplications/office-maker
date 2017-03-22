module CoreType exposing (Position, PositionFloat, Size)


type alias Position =
  { x : Int
  , y : Int
  }


type alias PositionFloat =
  { x : Float
  , y : Float
  }


type alias Size =
  { width : Int
  , height : Int
  }
