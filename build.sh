elm-make src/elm/Main.elm --output=index.js --warn &&
elm-make src/elm/Login.elm --output=login.js --warn &&
elm-make src/elm/BugReport.elm --output=bugs.html &&
mkdir -p test/server/public &&
mkdir -p test/server/public/images &&
mkdir -p test/server/public/images/floors &&
mkdir -p test/server/public/images/users &&
cp -f bugs.html index.js src/index.html login.js src/login.html src/style.css test/server/public &&
cp -f test/admin01.png test/user01.png test/default.png test/server/public/images/users
