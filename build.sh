mkdir -p server/public &&
mkdir -p server/public/images &&
mkdir -p server/public/images/floors &&
elm-make src/elm/Page/Map/Main.elm --output=server/public/index.js --warn $1 &&
elm-make src/elm/Page/Login/Main.elm --output=server/public/login.js --warn $1 &&
elm-make src/elm/Page/Master/Main.elm --output=server/public/master.js --warn $1 &&
cp -f src/style.css server/public
