import pytest
from _pytest.nodes import Item
from _pytest.runner import CallInfo
import os

TEST_RESULT_FILE = os.environ.get('TEST_RESULT_FILE')

def report_result(category, case, res, logs=''):
  with open(TEST_RESULT_FILE, "a") as f:
    res_str = 'PASS' if res == 'passed' else 'FAIL'
    f.write(f"{res_str}~{category}~{case}\n")
    

@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item: Item, call: CallInfo):
    
    outcome = yield  # Run all other pytest_runtest_makereport non wrapped hooks
    result = outcome.get_result()  # https://docs.pytest.org/en/latest/reference.html#_pytest.reports.TestReport
    
    if result.when == "call" and result.outcome != 'skipped':
        try:  # Just to not crash py.test reporting
            test_class_func = result.location[2]
            if '.' not in test_class_func:
                print('Skipping test function not in class: ' + test_class_func)
                return
            [class_name, func_name] = test_class_func.split('.')
            [_, test_name] = func_name.split('_', 1)
            cat_name = class_name[4:].replace('_', ' ')
            test_name = test_name.replace('_', ' ')
            print(cat_name, test_name)
            report_result(cat_name, test_name, result.outcome, result.longrepr)


        except Exception as e:
             print("ERROR", e)
             pass