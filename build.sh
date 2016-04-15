elm-make src/elm/Main.elm --output=index.js --warn
cp -f index.js src/index.html src/style.css lib/Roboto-Light.ttf test/public
