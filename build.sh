# prepare directories
mkdir -p server/static/public &&
mkdir -p server/static/public/images &&
mkdir -p server/static/public/images/floors &&

# generate javascript
elm-make src/elm/Page/Map/Main.elm --output=server/static/public/index.js --warn $1 &&
elm-make src/elm/Page/Login/Main.elm --output=server/static/public/login.js --warn $1 &&
elm-make src/elm/Page/Master/Main.elm --output=server/static/public/master.js --warn $1 &&

# copy static files
cp -f src/style.css server/static/public

# generate html
node server/static/generate-html
