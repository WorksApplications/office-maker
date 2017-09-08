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
mysql --user=$user --password=$pass < sql/3-update-at.sql
mysql --user=$user --password=$pass < sql/4-utf8mb4.sql
mysql --user=$user --password=$pass < sql/5-add-object-field.sql
mysql --user=$user --password=$pass < sql/6-temporary-floor.sql
mysql --user=$user --password=$pass < sql/7-flip-image-field.sql
mysql --user=$user --password=$pass < sql/8-objects_opt.sql
node commands.js createInitialData
