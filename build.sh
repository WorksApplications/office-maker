elm-make src/elm/Main.elm --output=index.js --warn &&
mkdir -p test/public &&
cp -f index.js src/index.html src/style.css test/public
