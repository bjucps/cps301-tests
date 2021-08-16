# Requires MySQL connector
# pip install mysql-connector==2.1.4
# See https://dev.mysql.com/doc/connector-python/en/
# See PEP-249 for the API standard: https://www.python.org/dev/peps/pep-0249/

from mysql.connector import connect
import mysql.connector
import os

# See https://stackoverflow.com/questions/27566078/how-to-return-str-from-mysql-using-mysql-connector
class MyConverter(mysql.connector.conversion.MySQLConverter):

    def row_to_python(self, row, fields):
        row = super(MyConverter, self).row_to_python(row, fields)

        def to_unicode(col):
            if isinstance(col, bytearray):
                return col.decode('utf-8')
            return col

        return[to_unicode(col) for col in row]  


dbpassword = os.environ.get('DBPASS', '')
cnx = connect(user='root', password=dbpassword, database=os.environ['DBNAME'], converter_class=MyConverter)
cursor = cnx.cursor()

def select(sql):
    cursor.execute(sql)
    return cursor.fetchall()


class TestUpdateGrade:
    def test_Updates_Grade(self):
        cursor.execute("""
            update enrollment 
            set enrgrade = 3
        """)

        result = cursor.callproc('updategrade', (1234,'123456789',90, ''))
        assert result[3] == 'success'

        # Ensure grade was correctly recorded
        result = select("""
        select enrgrade
        from enrollment
        where offerno = 1234 and stdno = '123456789'
        """)

        assert result[0][0] * 10 == 36

        # Ensure other rows are unchanged
        result = select("""
        select count(*)
        from enrollment
        where enrgrade = 3.6
        """)

        assert result[0][0] == 1
        

    def test_Rejects_Student_Not_Enrolled_In_Offering(self):

        result = cursor.callproc('updategrade', (5555,'345678901',90, ''))
        assert result[3] == 'student not enrolled in specified offering'

    def test_Rejects_Invalid_Grade(self):

        result = cursor.callproc('updategrade', (1234,'123456789',105, ''))
        assert result[3] == 'grade is not in the range 0..100'

    


