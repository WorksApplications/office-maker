# for developmemt
mysql -uroot < sql/1-create-schema.sql
mysql -uroot map2 < sql/2-create-tables.sql
node commands.js createDataForDebug onpremiss
