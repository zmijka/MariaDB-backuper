#!/usr/bin/env bash
#
# MariaDB backuper ver 1.0
#
# Skrypt do wykonywania kopii bazy danych MariaDB/Mysql
#
# Wymagane uprawnienia dla uzytkownika backuper po stronie bazy danych:
# Select_priv, Insert_priv, Create_priv, Reload_priv, File_priv, Alter_priv,
# Show_db_priv, Super_priv, Lock_tables_priv, Show_view_priv
#
# by Krzysztof 'zmijka' Zmijewski


# Nazwa uzytkownika w Bazie Danych wykorzystywana do robienia backup'a
DBUSER="backuper"

# Haslo uzytkownika
DBPASS=""

# Adres IP lub HOST bazy danych
DBHOST="127.0.0.1"

# Sciezka do plikow binarnych bazy danych
DBPATH="/usr/bin"

# Katalog tymczasowy
DBTMP="/home/../DBbackuper/tmp"

# Sciezka do katalogu z backup'ami
DBTARGET="/home/../DBbackuper/bkp"

# Sciezka do pliku logow
DBLOG="/.../DB_backuper.log"

# Format daty umieszczany w nazwie pliku kopii
DBDATA=`/bin/date +%d-%m-%Y`


#####
###   Cialo programu, prosze nie edytowac!!!
#


# Sprawdzamy czy baza danych dziala
DBALIVE=$(pgrep mysqld | wc -l);

if [ $DBALIVE -eq 0 ]
then
	echo $DBDATA - "Nie wykonano kopii z powodu nie dzialajacej Bazy Danych !!!" >> $DBLOG
else

# Kasujemy zawartosc katalogu tymczasowego $DBTMP
rm -rf $DBTMP/*

# Blokujemy bazy danych
$DBPATH/mysql --user=$DBUSER --password=$DBPASS --host=$DBHOST -e "FLUSH TABLES WITH READ LOCK;"

# Tworzymy liste baz danych
DBCHECK=`$DBPATH/mysql --user=$DBUSER --password=$DBPASS --host=$DBHOST -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`;

# Wykonanie backupu dla kazdej bazy z listy
for DBNAME in $DBCHECK
do
	# warunkiem if odrzucamy wykonywanie kopii baz - information_schema, performance_schema
	if [[ "$DBNAME" != "information_schema" ]] && [[ "$DBNAME" != "performance_schema" ]]  && [[ "$DBNAME" != _* ]]
	then
		#wykonujemu zrzut bazy danych ktorej nazwa zawarta jest w zmiennej $DBNAME
		$DBPATH/mysqldump --force --opt --user=$DBUSER --password=$DBPASS --host=$DBHOST $DBNAME > $DBTMP/$DBNAME.sql
	fi
done

# Odblokowanie baz danych
$DBPATH/mysql --user=$DBUSER --password=$DBPASS --host=$DBHOST -e "UNLOCK TABLES;"

# Archiwizujemy pliki baz danych
	tar czf $DBTARGET/$DBDATA"_DB_Backup".tar.gz $DBTMP >> /dev/null

	echo $DBDATA - "Wykonano kopie Bazy Danych" >> $DBLOG
	# Kasujemy zawartosc katalogu tymczasowego $DBTMP
	rm -rf $DBTMP/*
fi
