module Component.ImageLoader exposing (..)

import Task
import Html exposing (Html)
import Util.File as File exposing (..)
import Util.HtmlUtil as HtmlUtil
import Model.I18n as I18n exposing (Language)
import View.Styles as S


type Msg
    = LoadFile FileList


type alias Config msg =
    { onFileWithDataURL : File -> String -> msg
    , onFileLoadFailed : File.Error -> msg
    }


update : Config msg -> Msg -> Cmd msg
update config message =
    case message of
        LoadFile fileList ->
            File.getAt 0 fileList
                |> Maybe.map
                    (\file ->
                        readAsDataURL file
                            |> Task.map (config.onFileWithDataURL file)
                            |> Task.onError (Task.succeed << config.onFileLoadFailed)
                            |> Task.perform identity
                    )
                |> Maybe.withDefault Cmd.none


view : Language -> Html Msg
view lang =
    HtmlUtil.fileLoadButton LoadFile S.imageLoadButton "image/*" (I18n.loadImage lang)
