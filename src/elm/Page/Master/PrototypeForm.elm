module Page.Master.PrototypeForm exposing (..)

import String

import Model.Object exposing (Shape)
import Model.Prototype exposing (Prototype)


type alias PrototypeId = String

type alias FormInput =
  { value : String
  , errorMessage : Maybe String
  }


type alias PrototypeForm =
  { id : PrototypeId
  , name : FormInput
  , color : FormInput
  , backgroundColor : FormInput
  , width : FormInput
  , height : FormInput
  , fontSize : FormInput
  , shape : Shape
  , personId : Maybe String
  }


validateWidth : String -> FormInput
validateWidth width =
  case validateLength "width" width of
    Ok _ ->
      { value = width
      , errorMessage = Nothing
      }

    Err message ->
      { value = width
      , errorMessage = Just message
      }


validateHeight : String -> FormInput
validateHeight height =
  case validateLength "height" height of
    Ok _ ->
      { value = height
      , errorMessage = Nothing
      }

    Err message ->
      { value = height
      , errorMessage = Just message
      }


validateLength : String -> String -> Result String Int
validateLength fieldName width =
  case String.toInt width of
    Ok i ->
      if i > 0 && i % 8 == 0 then
        Ok i
      else
        Err (fieldName ++ " must be multiple of 8")

    Err _ ->
      Err (fieldName ++ " must be multiple of 8")
