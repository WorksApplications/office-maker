module Model.I18n exposing (..)


type Language
    = JA
    | EN


selectSamePost : Language -> String
selectSamePost lang =
    case lang of
        JA ->
            "同じ部署の人を選択"

        EN ->
            "Select people in the same post"


searchSamePost : Language -> String
searchSamePost lang =
    case lang of
        JA ->
            "同じ部署の人を検索"

        EN ->
            "Search people in the same post"


selectIsland : Language -> String
selectIsland lang =
    case lang of
        JA ->
            "島を選択する"

        EN ->
            "Select island"


selectSameColor : Language -> String
selectSameColor lang =
    case lang of
        JA ->
            "同じ色を選択する"

        EN ->
            "Select same color"


registerAsStamp : Language -> String
registerAsStamp lang =
    case lang of
        JA ->
            "スタンプとして登録する"

        EN ->
            "Register as stamp"


rotate : Language -> String
rotate lang =
    case lang of
        JA ->
            "90度回転する"

        EN ->
            "Rotate 90°"


pickupFirstWord : Language -> String
pickupFirstWord lang =
    case lang of
        JA ->
            "最初の単語を抜き出す"

        EN ->
            "Pickup first word"


removeSpaces : Language -> String
removeSpaces lang =
    case lang of
        JA ->
            "空白文字を除去"

        EN ->
            "Remove spaces"


copyFloor : Language -> String
copyFloor lang =
    case lang of
        JA ->
            "フロアを複製する"

        EN ->
            "Copy floor"


copyAndCreateTemporaryFloor : Language -> String
copyAndCreateTemporaryFloor lang =
    case lang of
        JA ->
            "複製して一時フロアを作る"

        EN ->
            "Copy and create temporary floor"


copyFloorWithEmptyDesks : Language -> String
copyFloorWithEmptyDesks lang =
    case lang of
        JA ->
            "フロアと空の机を複製する"

        EN ->
            "Copy floor and empty desks"



----


cancel : Language -> String
cancel lang =
    case lang of
        JA ->
            "キャンセル"

        EN ->
            "Cancel"


confirm : Language -> String
confirm lang =
    case lang of
        JA ->
            "確認"

        EN ->
            "Confirm"



----


missing : Language -> String
missing lang =
    case lang of
        JA ->
            "未登録"

        EN ->
            "Missing"



----


unexpectedFileError : Language -> String
unexpectedFileError lang =
    case lang of
        JA ->
            "予期しないエラー(FileError): "

        EN ->
            "Unexpected FileError: "


unexpectedHtmlError : Language -> String
unexpectedHtmlError lang =
    case lang of
        JA ->
            "予期しないエラー(HtmlError): "

        EN ->
            "Unexpected HtmlError: "


timeout : Language -> String
timeout lang =
    case lang of
        JA ->
            "タイムアウト"

        EN ->
            "Timeout"


networkErrorDetectedPleaseRefreshAndTryAgain : Language -> String
networkErrorDetectedPleaseRefreshAndTryAgain lang =
    case lang of
        JA ->
            "ネットワークエラーが検出されました。リフレッシュ(F5)してからもう一度試してください。"

        EN ->
            "NetworkError detected. Please refresh(F5) and try again."


unexpectedBadUrl : Language -> String
unexpectedBadUrl lang =
    case lang of
        JA ->
            "予期しない不正なURL"

        EN ->
            "Unexpected BadUrl"


unexpectedPayload : Language -> String
unexpectedPayload lang =
    case lang of
        JA ->
            "予期しないペイロード"

        EN ->
            "Unexpected BadPayload"


conflictSomeoneHasAlreadyChangedPleaseRefreshAndTryAgain : Language -> String
conflictSomeoneHasAlreadyChangedPleaseRefreshAndTryAgain lang =
    case lang of
        JA ->
            "競合: 他のユーザがすでに変更しています。リフレッシュ(F5)してからもう一度試してください。"

        EN ->
            "Conflict: Someone has already changed. Please refresh(F5) and try again."


unexpectedBadStatus : Language -> String
unexpectedBadStatus lang =
    case lang of
        JA ->
            "予期しないエラー(BadStatus)"

        EN ->
            "Unexpected BadStatus"



----


signIn : Language -> String
signIn lang =
    case lang of
        JA ->
            "サインイン"

        EN ->
            "Sign in"


signOut : Language -> String
signOut lang =
    case lang of
        JA ->
            "サインアウト"

        EN ->
            "Sign out"


goToMaster : Language -> String
goToMaster lang =
    case lang of
        JA ->
            "マスタメンテ画面へ"

        EN ->
            "Master maintenance"


goToManual : Language -> String
goToManual lang =
    case lang of
        JA ->
            "マニュアル (PDF)"

        EN ->
            "Manual (PDF)"


close : Language -> String
close lang =
    case lang of
        JA ->
            "閉じる"

        EN ->
            "Close"


print : Language -> String
print lang =
    case lang of
        JA ->
            "印刷"

        EN ->
            "Print"


edit : Language -> String
edit lang =
    case lang of
        JA ->
            "編集"

        EN ->
            "Edit"


help : Language -> String
help lang =
    case lang of
        JA ->
            "ヘルプ"

        EN ->
            "Help"



----


download : Language -> String
download lang =
    case lang of
        JA ->
            "ダウンロード"

        EN ->
            "Download"


name : Language -> String
name lang =
    case lang of
        JA ->
            "フロア名"

        EN ->
            "Name"


order : Language -> String
order lang =
    case lang of
        JA ->
            "順番"

        EN ->
            "Order"


widthMeter : Language -> String
widthMeter lang =
    case lang of
        JA ->
            "横(m)"

        EN ->
            "Width(m)"


heightMeter : Language -> String
heightMeter lang =
    case lang of
        JA ->
            "縦(m)"

        EN ->
            "Height(m)"


publish : Language -> String
publish lang =
    case lang of
        JA ->
            "変更を確認して公開"

        EN ->
            "View changes and publish"


deleteFloor : Language -> String
deleteFloor lang =
    case lang of
        JA ->
            "フロアを削除"

        EN ->
            "Delete this floor"


flipFloor : Language -> String
flipFloor lang =
    case lang of
        JA ->
            "フロアを反転"

        EN ->
            "Flip this floor"


lastUpdateByAt : Language -> String -> String -> String
lastUpdateByAt lang by at =
    case lang of
        JA ->
            "最終更新: " ++ by ++ " " ++ at

        EN ->
            "Last Update by " ++ by ++ " at " ++ at


loadImage : Language -> String
loadImage lang =
    case lang of
        JA ->
            "画像を読み込む"

        EN ->
            "Load Image"



--


nothingFound : Language -> String
nothingFound lang =
    case lang of
        JA ->
            "見つかりませんでした。"

        EN ->
            "Nothing found."



----


mailAddress : Language -> String
mailAddress lang =
    case lang of
        JA ->
            "メールアドレス"

        EN ->
            "Mail address"


password : Language -> String
password lang =
    case lang of
        JA ->
            "パスワード"

        EN ->
            "Password"


signInTo : Language -> String -> String
signInTo lang title =
    case lang of
        JA ->
            title ++ " にサインイン"

        EN ->
            "Sign in to " ++ title



----


search : Language -> String
search lang =
    case lang of
        JA ->
            "検索"

        EN ->
            "Search"


searchPlaceHolder : Language -> String
searchPlaceHolder lang =
    case lang of
        JA ->
            "名前、社員番号、組織名、会議室、etc."

        EN ->
            "Name, ID, Post, Room, etc."



----


changes : Language -> String
changes lang =
    case lang of
        JA ->
            "変更"

        EN ->
            "Changes"


changesFromDate : Language -> String -> String
changesFromDate lang date =
    case lang of
        JA ->
            date ++ " からの変更"

        EN ->
            "Changes from " ++ date


additions : Language -> Int -> String
additions lang number =
    case lang of
        JA ->
            "追加: " ++ toString number ++ "件"

        EN ->
            toString number ++ " additions"


modifications : Language -> Int -> String
modifications lang number =
    case lang of
        JA ->
            "更新: " ++ toString number ++ "件"

        EN ->
            toString number ++ " modifications"


deletions : Language -> Int -> String
deletions lang number =
    case lang of
        JA ->
            "削除: " ++ toString number ++ "件"

        EN ->
            toString number ++ " deletions"


noName : Language -> String
noName lang =
    case lang of
        JA ->
            "（名前なし）"

        EN ->
            "(no name)"
