import os, sys
import sqlex

sqlex.EXPDIR=os.path.dirname(os.path.realpath(__file__))
sqlex.POINTS_MAX_CORRECT = 6

sqlex.runTests(['q1', 'q2', 'q3', 'q4', 'q5'])
