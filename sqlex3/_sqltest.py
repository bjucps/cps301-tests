import os, sys
import sqlex
from sqlex import FAIL

sqlex.EXPDIR=os.path.dirname(os.path.realpath(__file__))
sqlex.POINTS_MAX_CORRECT = 6

def precheckTests(testname, sql):
    sql = sql.lower()
    if testname in ['q2', 'q4'] and 'exists' in sql:
        return [sqlex.makeResult('Acceptable Query', FAIL, 0, f'Should not use EXISTS')]

    if testname in ['q3', 'q5'] and 'exists' not in sql:
        return [sqlex.makeResult('Acceptable Query', FAIL, 0, f'Must use (NOT) EXISTS')]

sqlex.runTests(['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7'], ['q7'], precheckTests)
