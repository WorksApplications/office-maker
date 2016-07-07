module Model.FloorInfo exposing (..)

import Model.Floor as Floor

type alias Floor = Floor.Model

type FloorInfo
  = Public Floor
  | PublicWithEdit Floor Floor
  | Private Floor
