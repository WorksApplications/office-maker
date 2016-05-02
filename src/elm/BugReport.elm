import Html exposing (Html, text)
import Json.Decode as Json exposing (Decoder)

main : Html
main = text <| toString <| Json.decodeString decoder ""

decoder : Decoder String
decoder =
  Json.succeed "Succeed!"
