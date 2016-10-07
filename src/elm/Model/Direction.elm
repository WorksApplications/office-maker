module Model.Direction exposing (..)


type Direction = Up | Left | Right | Down


opposite : Direction -> Direction
opposite direction =
  case direction of
    Left -> Right
    Right -> Left
    Up -> Down
    Down -> Up


shiftTowards : Direction -> number -> (number, number)
shiftTowards direction amount =
  case direction of
    Up -> (0, -amount)
    Down -> (0, amount)
    Right -> (amount, 0)
    Left -> (-amount, 0)
