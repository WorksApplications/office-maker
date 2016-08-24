# for developmemt
mysql -uroot map2 < sql/1-create-schema.sql &&
mysql -uroot map2 < sql/2-create-tables.sql &&
node commands.js createDataForDebug onpremiss
