#!/bin/bash
# Abort on Error
set -e

export PING_SLEEP=100s

dump_output() {
	echo Tailing the last 500 lines of output:
	tail -n500 $(find logs -type f -name "build*.log")
}
error_handler() {
	echo ERROR: An error was encountered with the build.
	dump_output
	exit 1
}
# If an error occurs, run our error handler to output a tail of the build
trap 'error_handler' ERR

# Set up a repeating loop for Travis keep alive output.
bash -c "while true; do echo keep alive...; sleep $PING_SLEEP; done" &
PING_LOOP_PID=$!

env
unset CC
unset LD
unset AS
unset CXX
unset CPP
./sdk/build-epiphany-sdk.sh -j 2

# nicely terminate the ping output loop
kill $PING_LOOP_PID
