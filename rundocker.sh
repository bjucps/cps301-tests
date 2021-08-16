#!/bin/bash

# This script runs in my local Docker container. It sets up the
# folder structure for a submission test and runs the test, then copies test results
# to the student folder

export BASEDIR=/.
. ../tests/util/utils.sh

if [ -z "$1" ]; then
  echo Usage: rundocker.sh asmt_code
  exit 1
fi

project=$1
export TEST_DIR=$TEST_BASE_DIR/$project

mysqld_safe &

# Cleanup previous test results if we're running in the same Docker container
test -f $TEST_RESULT_FILE && rm $TEST_RESULT_FILE
test -d /submission && rm -r /submission

# Setup current test folder
cp -r /submission_src /submission
cd /submission

export SUBMISSION_DIR=$(pwd)
export NO_INSTALL_PACKAGES=1  # Disable installation of packages since the local Docker image already includes everything

if [ -e $TEST_DIR/_runtests.sh ]
then
    # Copy test files to submission folder
    cp -r $TEST_DIR/_* .

    run-tests || report-error "Warning" "Test script completed successfully"
else
    echo No tests for $project submissions... >$LOG_FILE
fi

gen-readme

echo Log file
echo -------------------------
cat $LOG_FILE

echo Test results
echo -------------------------
cat $TEST_RESULT_FILE
echo -------------------------

echo Overall Result: $(cat $SUBMISSION_DIR/submission.status)

cp $LOG_FILE $TEST_RESULT_FILE README.md /submission_src
