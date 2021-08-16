#!/bin/bash

export TEST_RESULT_FILE=$BASEDIR/_testresults.log
export LOG_FILE=$BASEDIR/_log.txt
export TEST_BASE_DIR=$BASEDIR/tests
#export TEST_DIR=   # Must be set by script
#export SUBMISSION_DIR=   # Must be set by script
export TIMEOUT=60  # default timeout in seconds

# Constants
CAT_MUST_PASS="Must Pass"
PASS="PASS"
FAIL="FAIL"

touch $TEST_RESULT_FILE  # Create if it doesn't exist

# Usage: report-error test-category test-name 
function report-error {
    echo "FAIL~$1~$2" >> $TEST_RESULT_FILE
}

# Usage: report-result PASS|FAIL test-category test-name 
function report-result {
    echo "$1~$2~$3" >> $TEST_RESULT_FILE
}

function must-pass-tests-failed {
    grep "^$FAIL~$CAT_MUST_PASS" $TEST_RESULT_FILE >/dev/null
}

function exit-if-must-pass-tests-failed {
    must-pass-tests-failed && exit 1
}

# Detect project name
#
# Usage: project=$(get-project-name)
#
function get-project-name {
    if [ -n "$PROJECT_NAME" ]; then
        echo $PROJECT_NAME
    else
        # Extract project name from github remote URL
        # Repo name should be of the form (ex.) cps250-project-student_github_username
        git remote get-url origin | cut -d/ -f5 | cut -d- -f2
    fi
}

# returns 0 if this test is run locally
function is-local-test {
    [ -z "$GITHUB_WORKFLOW" ]
}

# Returns 0 on success, 1 on failure
function run-tests {
    # Read test config if it exists
    if [ -r $TEST_DIR/_config.sh ]; then
      . $TEST_DIR/_config.sh
    fi

    echo "Starting MySQL"    
    while ! mysql $MYSQL_INIT_PW sys -e "select count(*)" 
    do
        sleep 1
    done

    # mysql $MYSQL_INIT_PW -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''"
    # mysql $MYSQL_INIT_PW -e "flush privileges"

    mysql -e "create database ordentry"
    mysql ordentry < $TEST_BASE_DIR/util/ordentry.sql

    echo "Beginning test run with timeout $TIMEOUT"
    result=0
    if BASH_ENV=$TEST_BASE_DIR/util/utils.sh timeout -k 1 $TIMEOUT bash _runtests.sh  2>&1 | tee $LOG_FILE
    then
        echo "Test run completed."
    else
        if [ $? -eq 124 ]; then
          echo "Time limit of $TIMEOUT seconds exceeded. Test aborted."
          report-error "$CAT_MUST_PASS" "Complete all tests within $TIMEOUT seconds"
        else
          report-error "$CAT_MUST_PASS" "Complete basic tests successfully"
        fi
        result=1
    fi

    return $result
}

function gen-readme {

    local final_result
    
    final_result=$PASS
    if must-pass-tests-failed; then
        final_result=$FAIL
    fi

    echo $final_result >$SUBMISSION_DIR/submission.status

    if [ $final_result = "$PASS" ]; then
        icon=https://raw.githubusercontent.com/bjucps/cps301-tests/main/images/pass.png
    else
        icon=https://raw.githubusercontent.com/bjucps/cps301-tests/main/images/fail.png
    fi

    cat > $SUBMISSION_DIR/README.md <<EOF
# Submission Status ![$final_result]($icon)

Test results generated at **$(TZ=America/New_York date)**

Category | Test | Result
---------|------|-------
$(awk -F~ -f $TEST_BASE_DIR/util/gentable.awk $TEST_RESULT_FILE | grep "^Must Pass")
$(awk -F~ -f $TEST_BASE_DIR/util/gentable.awk $TEST_RESULT_FILE | grep -v "^Must Pass")

## Detailed Test Results
\`\`\`
$(cat $LOG_FILE)
\`\`\`
EOF

}

# Usage: require-files [ --test-category <cat> ] [ --test-message <msg> ] file...
function require-files {
    local result overallresult
    local testcategory="$CAT_MUST_PASS"
    local testmessage="Required Files Submitted"

    if [ "$1" = "--test-category" ]; then
        testcategory=$2
        shift 2
    fi
    if [ "$1" = "--test-message" ]; then
        testmessage=$2
        shift 2
    fi

    overallresult=$PASS
    for file in $*
    do
        result=$PASS
        if [ ! -r "$file" ]; then
            result=$FAIL
            overallresult=$FAIL
        fi
        echo -e "\nChecking for required file $file... $result"
    done

    report-result $overallresult "$testcategory" "$testmessage"

}

function require-pdf {
    local overallresult
    local reason

    overallresult=$PASS
    for file in $*
    do
        echo -en "\nChecking for required PDF $file... "
        if [ ! -r $file ]; then
            echo "$FAIL - $file is not found"
            overallresult=$FAIL
        elif file $file | grep PDF >/dev/null; then
            echo "$PASS"
        else
            echo "$FAIL - $file is not a valid PDF"
            overallresult=$FAIL
        fi
    done

    report-result $overallresult "$CAT_MUST_PASS" "Required PDF submitted" 

}

# Compiles a program and reports success or failure
# Usage: do-compile <compile command> [ <expected executable> ]
# Example:
#     do-compile [ --always-show-output ] [ --test-message <msg> ] "gcc -g myproc.c -omyprog" "myprog" 
function do-compile {
    local result=$FAIL
    local detail
    local always_show=0
    local compile_cmd
    local expected_exe
    local testmessage="Successful compile"
    
    if [ "$1" = "--always-show-output" ]; then
        always_show=1
        shift
    fi
    if [ "$1" = "--test-message" ]; then
        testmessage=$2
        shift 2
    fi


    compile_cmd=$1
    expected_exe=$2

    if detail=$($compile_cmd 2>&1); then
        result=$PASS
        if [ -n "$expected_exe" -a ! -e "$expected_exe" ]; then
            result=$FAIL
            detail="No executable $expected_exe produced from make"
        fi
    fi

    echo -e "\nExecuting: $compile_cmd... $result"
    if [ $result = $FAIL -o $always_show -eq 1 ]; then
        echo "----------------------------------------------------------------"
        echo "$detail"
        echo "----------------------------------------------------------------"
    fi

    report-result $result "$CAT_MUST_PASS" "$testmessage"
 
    [ $result = $PASS ]
}

# Execute a program and report result.
#
# Usage: run-program [ --test-category <category> ] [ --test-message <message> ] [ --timeout <seconds> ] [ --maxlines <lines> ] [ --showoutputonpass ] program args...
#
# * Output of program is normally displayed only if the exit code indicates failure.
#   Use --showoutputonpass to always display output.
# * An entry is added to the test report if --test-message is specified
#
# Example: 
#    run-program --test-message "valgrind executes with no errors" --showoutputonpass valgrind ./args
#
function run-program {
    local testcategory="Warning" 
    local testmessage
    local timeout=30              # Default timeout
    local showoutputonpass=0 
    local maxlines=50
    local result

    testcategory="Warning"
    if [ "$1" = "--test-category" ]; then
        testcategory=$2
        shift 2
    fi
    if [ "$1" = "--test-message" ]; then
        testmessage=$2
        shift 2
    fi
    if [ "$1" = "--timeout" ]; then
        timeout=$2
        shift 2
    fi
    if [ "$1" = "--max-lines" ]; then
        maxlines=$2
        shift 2
    fi
    if [ "$1" = "--showoutputonpass" ]; then
        showoutputonpass=1
        shift 
    fi

    result=$FAIL
    if output=$(set -o pipefail; timeout $timeout $* 2>&1 | head -$maxlines); then
        result=$PASS
    fi

    echo -e "\nExecuting: $* ... $result"
    if [ $result = $FAIL -o $showoutputonpass = 1 ]; then
        echo "----------------------------------------------------------------"
        echo "$output"
        echo "----------------------------------------------------------------"
    fi

    if [ -n "$testmessage" ]; then
        report-result $result "$testcategory" "$testmessage"
    fi

    [ $result = $PASS ]
}

function sql_check {
  
    if [ -n "$QUERYDIR" ]; then
      echo Running in local Docker... skipping sql filename check
      return
    fi

    if stdout=$(ls q*.sql); then
        result=true
    else
        result=false
    fi
    TestOutput "Must Pass" "Correct .sql filenames" $result "$stdout"
    if [ $result = false ]; then
      exit 1
    fi
}

function do_sql_test {

    SQL_TEST=$1

    if [ -r .git ]
    then
        max_submits=3
        commit_count=$(git log --pretty="%an %s" | grep -v "GitHub" | grep -v "Merge" | wc -l)
        if [ "$commit_count" -gt $max_submits ]
        then
            report-error "Notice" "$commit_count submissions exceeds free allowance"
        fi
    fi

    export PYTHONPATH=$TEST_BASE_DIR/util

    echo "Autograding submission #$commit_count (first 3 are free)"

    python3 $TEST_DIR/_sqltest.py

}