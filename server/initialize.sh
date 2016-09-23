# for developmemt
user=root
pass=root

cat defaultConfig.json \
  | sed -e "s/\"user\": \"root\"/\"user\": \"$user\"/"\
  | sed -e "s/\"pass\": \"\"/\"pass\": \"$pass\"/" \
  > config.json
mysql --user=$user --password=$pass -e "drop database map2;"
mysql --user=$user --password=$pass < sql/1-create-schema.sql
mysql --user=$user --password=$pass < sql/2-create-tables.sql
node commands.js createDataForDebug
