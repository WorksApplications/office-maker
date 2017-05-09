module Page.Master.PrototypeForm exposing (..)

import Model.Object exposing (Shape)
import Model.Prototype exposing (Prototype)


type alias PrototypeId =
    String


type alias PrototypeForm =
    { id : PrototypeId
    , name : String
    , color : String
    , backgroundColor : String
    , width : String
    , height : String
    , fontSize : String
    , shape : Shape
    , personId : Maybe String
    }


fromPrototype : Prototype -> PrototypeForm
fromPrototype prototype =
    { id = prototype.id
    , name = prototype.name
    , color = prototype.color
    , backgroundColor = prototype.backgroundColor
    , width = toString prototype.width
    , height = toString prototype.height
    , fontSize = toString prototype.fontSize
    , shape = prototype.shape
    , personId = prototype.personId
    }


toPrototype : PrototypeForm -> Result String Prototype
toPrototype form =
    validateName form.name
        |> Result.andThen
            (\name ->
                validateColor form.color
                    |> Result.andThen
                        (\color ->
                            validateBackgroundColor form.backgroundColor
                                |> Result.andThen
                                    (\backgroundColor ->
                                        validateWidth form.width
                                            |> Result.andThen
                                                (\width ->
                                                    validateHeight form.height
                                                        |> Result.andThen
                                                            (\height ->
                                                                validateFontSize form.fontSize
                                                                    |> Result.map
                                                                        (\fontSize ->
                                                                            { id = form.id
                                                                            , name = name
                                                                            , color = color
                                                                            , backgroundColor = backgroundColor
                                                                            , width = width
                                                                            , height = height
                                                                            , fontSize = fontSize
                                                                            , shape = form.shape
                                                                            , personId = form.personId
                                                                            }
                                                                        )
                                                            )
                                                )
                                    )
                        )
            )


validateName : String -> Result String String
validateName name =
    Ok name


validateColor : String -> Result String String
validateColor color =
    Ok color


validateBackgroundColor : String -> Result String String
validateBackgroundColor backgroundColor =
    Ok backgroundColor


validateFontSize : String -> Result String Float
validateFontSize size =
    case String.toFloat size of
        Ok i ->
            if i >= 10 then
                Ok i
            else
                Err ("font size must not be less than 10")

        Err _ ->
            Err ("font size must be a number")


validateWidth : String -> Result String Int
validateWidth width =
    validateLength "width" width


validateHeight : String -> Result String Int
validateHeight height =
    validateLength "height" height


validateLength : String -> String -> Result String Int
validateLength fieldName length =
    case String.toInt length of
        Ok i ->
            if i > 0 && i % 8 == 0 then
                Ok i
            else
                Err (fieldName ++ " must be multiple of 8")

        Err _ ->
            Err (fieldName ++ " must be multiple of 8")
