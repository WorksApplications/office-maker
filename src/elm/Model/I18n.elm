module Model.I18n exposing (..)


type Language = JA | EN


selectSamePost : Language -> String
selectSamePost lang =
  case lang of
    JA -> "同じ部署の人を選択"
    EN -> "Select people in the same post"


selectIsland : Language -> String
selectIsland lang =
  case lang of
    JA -> "島を選択する"
    EN -> "Select island"


registerAsStamp : Language -> String
registerAsStamp lang =
  case lang of
    JA -> "スタンプとして登録する"
    EN -> "Register as stamp"


rotate : Language -> String
rotate lang =
  case lang of
    JA -> "90度回転する"
    EN -> "Rotate 90°"


pickupFirstWord : Language -> String
pickupFirstWord lang =
  case lang of
    JA -> "最初の単語を抜き出す"
    EN -> "Pickup first word"


removeSpaces : Language -> String
removeSpaces lang =
  case lang of
    JA -> "空白文字を除去"
    EN -> "Remove spaces"


copyFloor : Language -> String
copyFloor lang =
  case lang of
    JA -> "フロアを複製する"
    EN -> "Copy floor"


----

pasteFromSpreadsheet : Language -> String
pasteFromSpreadsheet lang =
  case lang of
    JA -> "スプレッドシートから貼り付け"
    EN -> "Paste from Spreadsheet"

----

cancel : Language -> String
cancel lang =
  case lang of
    JA -> "キャンセル"
    EN -> "Cancel"


confirm : Language -> String
confirm lang =
  case lang of
    JA -> "確認"
    EN -> "Confirm"

----

missing : Language -> String
missing lang =
  case lang of
    JA -> "未登録"
    EN -> "Missing"


----

unexpectedFileError : Language -> String
unexpectedFileError lang =
  case lang of
    JA -> "予期しないエラー(FileError): "
    EN -> "Unexpected FileError: "


unexpectedHtmlError : Language -> String
unexpectedHtmlError lang =
  case lang of
    JA -> "予期しないエラー(HtmlError): "
    EN -> "Unexpected HtmlError: "


timeout : Language -> String
timeout lang =
  case lang of
    JA -> "タイムアウト"
    EN -> "Timeout"


networkErrorDetectedPleaseRefreshAndTryAgain : Language -> String
networkErrorDetectedPleaseRefreshAndTryAgain lang =
  case lang of
    JA -> "ネットワークエラーが検出されました。リフレッシュ(F5)してからもう一度試してください。"
    EN -> "NetworkError detected. Please refresh(F5) and try again."


unexpectedPayload : Language -> String
unexpectedPayload lang =
  case lang of
    JA -> "予期しないペイロード"
    EN -> "UnexpectedPayload"


conflictSomeoneHasAlreadyChangedPleaseRefreshAndTryAgain : Language -> String
conflictSomeoneHasAlreadyChangedPleaseRefreshAndTryAgain lang =
  case lang of
    JA -> "コンフリクト: 他のユーザがすでに変更しています。リフレッシュ(F5)してからもう一度試してください。"
    EN -> "Conflict: Someone has already changed. Please refresh(F5) and try again."


unexpectedBadResponse : Language -> String
unexpectedBadResponse lang =
  case lang of
    JA -> "予期しないエラー(BadResponse)"
    EN -> "Unexpected BadResponse"



----


signIn : Language -> String
signIn lang =
  case lang of
    JA -> "サインイン"
    EN -> "Sign in"


signOut : Language -> String
signOut lang =
  case lang of
    JA -> "サインアウト"
    EN -> "Sign out"


----

name : Language -> String
name lang =
  case lang of
    JA -> "フロア名"
    EN -> "Name"


order : Language -> String
order lang =
  case lang of
    JA -> "順番"
    EN -> "Order"


widthMeter : Language -> String
widthMeter lang =
  case lang of
    JA -> "横(m)"
    EN -> "Width(m)"


heightMeter : Language -> String
heightMeter lang =
  case lang of
    JA -> "縦(m)"
    EN -> "Height(m)"


publish : Language -> String
publish lang =
  case lang of
    JA -> "公開"
    EN -> "Publish"


lastUpdateByAt : Language -> String -> String -> String
lastUpdateByAt lang by at =
  case lang of
    JA -> "最終更新: " ++ by ++ " " ++ at
    EN -> "Last Update by " ++ by ++ " at " ++ at


loadImage : Language -> String
loadImage lang =
  case lang of
    JA -> "画像を読み込む"
    EN -> "Load Image"

--

nothingFound : Language -> String
nothingFound lang =
  case lang of
    JA -> "見つかりませんでした。"
    EN -> "Nothing found."
