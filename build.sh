elm-make src/elm/Main.elm --output=index.js --warn &&
elm-make src/elm/Login.elm --output=login.js --warn &&
elm-make src/elm/BugReport.elm --output=bugs.html &&
mkdir -p test/public &&
mkdir -p test/public/images &&
mkdir -p test/public/images/floors &&
mkdir -p test/public/images/users &&
cp -f index.js src/index.html login.js src/login.html src/style.css test/public &&
cp -f test/admin01.png test/user01.png test/default.png test/public/images/users
