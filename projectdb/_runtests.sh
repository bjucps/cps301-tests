
export DBNAME=wso

function import_db {
  SQL_SCRIPT=$1

  if grep -iq "create database" /tmp/$SQL_SCRIPT 2>&1; then
    echo "*** FAIL: wso.sql contains CREATE DATABASE statement"
    echo "You must create wso.sql using mysqldump per project submission instructions."
    return 1
  fi
  echo
  echo -n "MYSQL Syntax check of $SQL_SCRIPT: "
  mysql -e "drop database if exists $DBNAME"
  mysql -e "create database $DBNAME"

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

function import_sqlite_db {
  SQL_SCRIPT=$1

  echo -n "SQLite Syntax check of $SQL_SCRIPT: "

  if stderr=$(sqlite3 $DBNAME < /tmp/$SQL_SCRIPT 2>&1); then
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

tr A-Z a-z < $SUBMISSION_DIR/wso.sql > /tmp/wso.sql

pass="FAIL"
if import_db wso.sql 2>&1; then
    pass="PASS"
fi
report-result  $pass "Must Pass" "valid wso.sql" 

if [ -r $SUBMISSION_DIR/wsoschema.sql ]
then
  tr A-Z a-z < $SUBMISSION_DIR/wsoschema.sql > /tmp/wsoschema.sql
  pass="FAIL"
  if import_db wsoschema.sql 2>&1; then
      pass="PASS"
  fi
  report-result $pass "WSOSchema" "wsoschema.sql imports in MySQL"  

  pass="FAIL"
  if import_sqlite_db wsoschema.sql 2>&1; then
      pass="PASS"
  fi
  # Delete database
  [ -r $DBNAME ] && rm $DBNAME
  report-result $pass  "WSOSchema" "wsoschema.sql imports in SQLite" 

else
  report-error "Warning" "Missing wsoschema.sql"
fi

do_sql_test 3

require-pdf report.pdf

rm /tmp/*.sql
