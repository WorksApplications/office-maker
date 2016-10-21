elm-make src/elm/Page/Map/Main.elm --output=index.js --warn &&
elm-make src/elm/Page/Login.elm --output=login.js --warn &&
elm-make src/elm/Page/Master/Main.elm --output=master.js --warn &&
mkdir -p server/public &&
mkdir -p server/public/images &&
mkdir -p server/public/images/floors &&
cp -f index.js login.js master.js src/style.css server/public
