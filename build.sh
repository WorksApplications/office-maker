elm-make src/elm/Main.elm --output=index.js --warn &&
elm-make src/elm/Login.elm --output=login.js --warn &&
mkdir -p test/public &&
cp -f index.js src/index.html login.js src/login.html src/style.css test/public
