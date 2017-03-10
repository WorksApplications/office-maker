cd `dirname $0`

user=root
pass=root

if ls config.json ; then
  echo "Already initialized. To reinitialize, delete config.json."
  exit 1;
fi

cat defaultConfig.json \
  | sed -e "s/\"user\": \"root\"/\"user\": \"$user\"/"\
  | sed -e "s/\"pass\": \"\"/\"pass\": \"$pass\"/" \
  > config.json
mysql --user=$user --password=$pass -e "drop database map2;"
mysql --user=$user --password=$pass < sql/1-create-schema.sql
mysql --user=$user --password=$pass < sql/2-create-tables.sql
node commands.js createDataForDebug
