module Util.File exposing (..)

import Native.File
import Json.Decode exposing (..)
import Task exposing (Task)


type FileList
    = FileList Json.Decode.Value


type File
    = File Json.Decode.Value


type Error
    = Unexpected String


readAsDataURL : File -> Task Error String
readAsDataURL (File file) =
    Task.mapError
        (always (Unexpected (toString file)))
        (Native.File.readAsDataURL file)


length : FileList -> Int
length (FileList list) =
    Native.File.length list


getAt : Int -> FileList -> Maybe File
getAt index fileList =
    case fileList of
        FileList list ->
            if 0 <= index && index < length fileList then
                Just (File <| Native.File.getAt index list)
            else
                Nothing


decodeFile : Decoder FileList
decodeFile =
    Json.Decode.map FileList (at [ "target", "files" ] (value))


getSizeOfImage : String -> ( Int, Int )
getSizeOfImage =
    Native.File.getSizeOfImage
