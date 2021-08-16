export DBNAME=lab5

function import_db {
  SQL_SCRIPT=$1

  if grep -iq "create database" $SUBMISSION_DIR/$SQL_SCRIPT 2>&1; then
    echo "*** FAIL: wso.sql contains CREATE DATABASE statement"
    echo "You must create wso.sql using mysqldump per project submission instructions."
    return 1
  fi
  echo
  echo -n "Syntax check of $SQL_SCRIPT: "
  mysql -e "drop database if exists $DBNAME"
  mysql -e "create database $DBNAME"

  # Convert file to all lowercase due to MySQL case sensitivity on Linux
  tr A-Z a-z <$SUBMISSION_DIR/$SQL_SCRIPT >/tmp/$SQL_SCRIPT
  if stderr=$(mysql $DBNAME < /tmp/$SQL_SCRIPT 2>&1); then
    echo 'OK'
    echo
  else
    echo "FAIL"
    echo "----------------------------------------------------------------"
    echo "$stderr"
    echo "----------------------------------------------------------------"
    echo
    return 1
  fi
}

pass="FAIL"
if stderr=$(import_db lab5.sql 2>&1); then
    pass="PASS"
fi
report-result "Must Pass" "valid lab5.sql" $pass 

require-pdf lab5.pdf


if pytest lab5.py
then
  echo "All tests passed."
fi

rm conftest.py
