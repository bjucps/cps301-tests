# README

This repository contains tests for CpS 301.

To run tests locally:

First, build a local Docker container:
```
cd Docker
build.cmd
```

Then, to test a submission, use the run.cmd script in this folder:

```
cd submission-folder
\path\to\cps301-tests\run lab1
```

To run tests interactively in Docker container:

```
cd submission-folder
runi
# rt lab1
```

# Configuring Assignments

Create config.sh in an assignment folder to specify assignment configuration.

Options include:
* TIMEOUT - overall timeout in seconds for the test (default 30)
