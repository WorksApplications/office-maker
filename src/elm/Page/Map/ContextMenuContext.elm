module Page.Map.ContextMenuContext exposing (..)


type alias ObjectId = String
type alias FloorId = String


type ContextMenuContext
  = ObjectContextMenu ObjectId
  | FloorInfoContextMenu FloorId
