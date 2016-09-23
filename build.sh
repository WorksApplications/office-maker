elm-make src/elm/Main.elm --output=index.js --warn &&
elm-make src/elm/Login.elm --output=login.js --warn &&
mkdir -p server/public &&
mkdir -p server/public/images &&
mkdir -p server/public/images/floors &&
cp -f index.js login.js src/style.css server/public
