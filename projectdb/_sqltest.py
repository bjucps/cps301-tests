import os, sys
import sqlex
from mysql.connector import connect
import mysql.connector

sqlex.MAX_OUTPUT_DISPLAY_ROWS = 50

def select(sql):
    cursor.execute(sql)
    return cursor.fetchall()

def check_foreign_keys():

  foreign_keys = select(f"""
        select lower(table_name), lower(column_name), lower(referenced_table_name)
        from INFORMATION_SCHEMA.key_column_usage 
        where constraint_schema = '{dbschema}' and referenced_table_name is not null
        order by table_name, column_name
  """)

  EXPECTED_FOREIGN_KEYS = [
      ['fills_role', 'person_id', 'person'],
      ['fills_role', 'service_id', 'service'],
      ['member_of', 'ensemble_id', 'ensemble'], 
      ['member_of', 'person_id', 'person'], 
      ['service_item', 'ensemble_id', 'ensemble'], 
      ['service_item', 'event_type_id', 'event_type'], 
      ['service_item', 'person_id', 'person'], 
      ['service_item', 'service_id', 'service'], 
      ['service_item', 'song_id', 'song'],
      ['unavailable_for', 'person_id', 'person'], 
      ['unavailable_for', 'service_id', 'service'], 
    ]
  output = 'Found the following in your database:\nTable                Column               Referenced Table\n--------------------------------------------------------------\n'
  correct_fks = 0
  for key in foreign_keys:
    output += f'{key[0]:<20} {key[1]:<20} {key[2]}\n'
    if key in EXPECTED_FOREIGN_KEYS:
      correct_fks += 1

  missing_fk_count = (len(EXPECTED_FOREIGN_KEYS) - correct_fks)
  if missing_fk_count > 0:
    output += f'\nMissing {missing_fk_count} expected foreign keys\n'

  correct_fk_points = 10 - missing_fk_count
  if correct_fk_points < 0:
      correct_fk_points = 0

  return sqlex.makeResult('Foreign Keys', 
    sqlex.OK if correct_fk_points == 10 else sqlex.FAIL, 
    correct_fk_points, output)    

def check_table_columns():
  table_cols = select(f"""
        SELECT lower(table_name), lower(column_name)
        FROM information_schema.columns 
        WHERE table_schema = '{dbschema}' 
        ORDER BY table_name, column_name;
  """)
  
  # No foreign keys here
  EXPECTED_TABLE_COLS = [
    ['ensemble', 'ensemble_id'] ,
    ['ensemble', 'name'] ,
    ['event_type', 'description'] ,
    ['event_type', 'event_type_id'] ,
    ['fills_role', 'confirmed'],
    ['fills_role', 'role_type'],
    ['person', 'email'] ,
    ['person', 'first_name'] ,
    ['person', 'last_name'] ,
    ['person', 'person_id'] ,
    ['service', 'service_id'] ,
    ['service', 'svc_datetime'] ,
    ['service', 'theme_event'] ,
    ['service_item', 'confirmed'] ,
    ['service_item', 'service_item_id'] ,
    ['service_item', 'seq_num'] ,
    ['service_item', 'title'] ,
    ['song', 'arranger'] ,
    ['song', 'hymnbook_num'] ,
    ['song', 'song_id'] ,
    ['song', 'song_type'] ,
    ['song', 'title'],
]

  correct_tcs = 0
  output = 'Found the following in your database:\nTable                Column\n----------------------------------\n'
  for table_col in table_cols:
    #print(table_col, ',')
    output += f'{table_col[0]:<20} {table_col[1]}\n'
    if table_col in EXPECTED_TABLE_COLS:
        correct_tcs += 1

  missing_col_count = (len(EXPECTED_TABLE_COLS) - correct_tcs)
  if missing_col_count > 0:
    output += f'\nMissing {missing_col_count} expected columns\n'

  correct_tc_points = 4 - missing_col_count
  if correct_tc_points < 0:
      correct_tc_points = 0

  return sqlex.makeResult('Tables/Cols', 
    sqlex.OK if correct_tc_points == 4 else sqlex.FAIL, 
    correct_tc_points, output)    

def runTests():

  #results = [{ 'id': 'q1', 'results': [ 
  #              { 'test': 'Syntax Check', 'result': 'OK', 'points': .5, 'output': '...' }, 
  #              { 'columns': 'ok' }, 
  #              { 'rows': 'ok' } ]}]
  results = []

  TC_CHECK = check_table_columns()
  FK_CHECK = check_foreign_keys()

    #     CHK_SYNTAX = sqlex.runsql(test)
    #     if CHK_SYNTAX['result'] == OK:
    #       num_syntax_ok += 1
    #       CHK_COL, CHK_ROW = checkresult(test, CHK_SYNTAX['output'])
    #       result = [CHK_SYNTAX, CHK_COL, CHK_ROW]
    #     else:
    #       result = [CHK_SYNTAX]

  result = [TC_CHECK, FK_CHECK]

  points = 0
  for subtest in result:
    points += subtest['points']
    
  results.append({ 'id': 'Database Structure', 'results': result, 'points': points })

  totalPoints = sqlex.printReport(results)

# See https://stackoverflow.com/questions/27566078/how-to-return-str-from-mysql-using-mysql-connector
class MyConverter(mysql.connector.conversion.MySQLConverter):

    def row_to_python(self, row, fields):
        row = super(MyConverter, self).row_to_python(row, fields)

        def to_unicode(col):
            if isinstance(col, bytearray):
                return col.decode('utf-8')
            return col

        return[to_unicode(col) for col in row]  

dbschema=os.environ['DBNAME']

dbport = int(os.environ.get('DBPORT', 3306))
dbpassword = os.environ.get('DBPASS', '')
cnx = connect(user='root', port=dbport, password=dbpassword, database=dbschema, converter_class=MyConverter)
cursor = cnx.cursor()

sqlex.POINTS_MAX_CORRECT = 5

runTests()


