elm-make src/elm/Main.elm --output=index.js --warn &&
elm-make src/elm/Login.elm --output=login.js --warn &&
mkdir -p server/public &&
mkdir -p server/public/images &&
mkdir -p server/public/images/floors &&
mkdir -p server/public/images/users &&
cp -f index.js login.js src/style.css server/public &&
cp -f test/admin01.png test/user01.png test/default.png server/public/images/users
