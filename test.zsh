# ================================
# test.zsh - main source file of the testing framework


__VERSION__='1.0.1'


# ================================
# Configuration
#
# Feel free to change values of variables in this "section" to fit the
# framework to your needs

# Paths (relative) to directories used by this framework
#
# The project root directory
ROOT_DIR=..
# Actual tests will be stored here
TESTS_DIR=./tests
# Tests' static data will be stored here
DATA_DIR=./data
# Tests' temporary data will be stored here
TMP_DIR=./tmp

# Path (relative) to a script that will be executed before every test (test's
# init phase); set to nothing (empty string) to disable (no "init script" will
# be executed for any test)
#
# TEST_INIT_SCRIPT='./init.zsh'
TEST_INIT_SCRIPT=

# Pattern that filenames must match to be considered as tests; set to empty
# string to consider every file in TESTS_DIR as a test
#
# By default, test is a file with name like test_<x>.<y>sh, where <x> and <y>
# are any strings
#
TEST_PATTERN='test_*.*sh(N)'

# Tests status pattern symbols
#
# 1 - success
# 2 - failure
# 3 - error
# 4 - skipped
# 5 - broken
# 6 - expected fail
# 7 - unexpected success
#
PATTERN_SYMBOLS='.F!...F'

# This framework (functions it defines) may be used as a library (and sourced
# by some other project) - if that's the case, set this one to true
#
LIBRARY=

# End of configuration
# Any changes below this line should be made by developers only
# ================================


# `perform_test()` return codes
TEST_SUCCESS=0   # The test was passed
TEST_FAILURE=1   # The test failed
TEST_ERROR=2     # During the test, some errors occured
TEST_SKIPPED=3   # The test was skipped
TEST_BROKEN=4    # The test is broken
TEST_FAIL_OK=5   # The test failed but that's OK
TEST_SUCC_FAIL=6 # The test was passed but it shouldn't happen


# Make the argv accessible by any function
ARGV=$@
PROGNAME=$0


# ================================
# Error function based on the behaviour of C error() function
#
# $1 status (0 - just print message, else print message and return status)
# $2 format string
# ... format string arguments
#
function error
{
	STATUS=0
	FORMAT=''

	if [ $# -gt 0 ]
	then
		STATUS=$1
		shift
	fi

	if [ $# -gt 0 ]
	then
		FORMAT=$1
		shift
	fi

	if [ ! -z "$FORMAT" ]
	then
		MSG=$(printf "$FORMAT" "$@")
	fi

	if [ -z "$MSG" ]
	then
		echo "$PROGNAME: error"
	else
		echo "$PROGNAME: $MSG"
	fi

	if [ $STATUS -ne 0 ]
	then
		exit $STATUS
	fi
} >&2


# ================================
# Initialize the testing environment
#
# Check some directories for existence and (re)create the others
#
function init
{
	# Directory with tests must exist
	if [ ! -d $TESTS_DIR ]
	then
		error 1 "$TESTS_DIR: directory does not exist"
	fi

	# Make tmp directory existent and empty
	rm -rf $TMP_DIR
	if ! mkdir -p $TMP_DIR
	then
		exit 1
	fi
}


# ================================
# Definitions of default test phases handlers
#
# If a test does not define its own test phase handler, one of these will be
# used. "setup", "cleanup" and "test" handlers do nothing; "verify" handler
# prints warning and fails.

function setup
{}

function cleanup
{}

function test
{}

function verify
{
	echoerr "verification handler is not defined"

	return 1
}

# ================================
# Functions for tests to simplify some common operations

# Print a message ($1) to stderr
#
function echoerr
{
	error 0 $1
}

# Make a temporary copy of a static data (recursive)
#
# $1 - static file name
# $2 - optional, temporary file name (default: $1)
#
function tmpcopy
{
	FSRC=$1
	FDST=$2

	if [ -z $FSRC ]
	then
		echoerr "static file name not given"
		return 1
	fi

	if [ -z $FDST ]
	then
		FDST=$FSRC
	fi

	cp -r $TEST_DATA/$FSRC $TEST_TMP/$FDST
}


# ================================
# Perform one test; test file path must be given as $1; this function also
# prints test description if provided
#
function perform_test
{
	# Get name and stem of the test file
	TEST_FNAME=$1
	TEST_FSTEM=${$(basename $TEST_FNAME)%.*}

	# By default the test does not want to merge stderr with stdout
	STDERR_MERGE=
	# Test does not provide description by default
	DESCRIPTION=
	# By default test is not marked in any way
	TEST_MARK_SKIP=
	TEST_MARK_BROKEN=
	TEST_MARK_FAIL=

	# Load the initialization script
	if [ ! -z $TEST_INIT_SCRIPT ] && ! source $TEST_INIT_SCRIPT
	then
		error 0 "$TEST_INIT_SCRIPT: unable to load"

		return TEST_ERROR
	fi

	# Load the test
	if ! source $TEST_FNAME
	then
		error 0 "$TEST_FNAME: unable to load"

		return TEST_ERROR
	fi

	# Show the description if provided
	if [ ! -z $DESCRIPTION ]
	then
		echo $DESCRIPTION | fold -sw77 | sed 's/^/* /'
	fi
	echo

	# Skip the test if marked as broken
	if [ ! -z $TEST_MARK_BROKEN ]
	then
		return TEST_BROKEN
	fi

	# Skip the test if requested
	if [ ! -z $TEST_MARK_SKIP ]
	then
		return TEST_SKIPPED
	fi

	# Initialize environment for the test
	TEST_DATA="$DATA_DIR/$TEST_FSTEM"
	TEST_TMP="$TMP_DIR/$TEST_FSTEM"
	TEST_STDIN="$TEST_DATA/stdin"
	TEST_STDOUT="$TEST_TMP/stdout"
	TEST_STDERR="$TEST_TMP/stderr"

	# If stdin file for test does not exist, ensure stdin redirection from it
	# wouldn't be made
	if [ ! -f $TEST_STDIN ]
	then
		REDIR_STDIN=
	else
		REDIR_STDIN="<$TEST_STDIN"
	fi

	# If the test has chosen to merge stderr with stdout, ensure it would be
	# made
	if [ -z $STDERR_MERGE ]
	then
		REDIR_STDOUT=">$TEST_STDOUT"
		REDIR_STDERR="2>$TEST_STDERR"
	else
		REDIR_STDOUT="&>$TEST_STDOUT"
		REDIR_STDERR=""

		TEST_STDERR=$TEST_STDOUT
	fi

	# Create tmp directory for the test
	if ! mkdir $TEST_TMP
	then
		error 0 "$TEST_TMP: unable to mkdir"

		return TEST_ERROR
	fi

	# Perform the setup phase of the test
	if ! setup
	then
		cleanup

		error 0 "$TEST_FNAME: setup failed"

		return TEST_ERROR
	fi

	# Perform the proper test phase of the test
	if ! eval test $REDIR_STDIN $REDIR_STDOUT $REDIR_STDERR
	then
		cleanup

		error 0 "$TEST_FNAME: test phase failed"

		return TEST_ERROR
	fi

	# Perform the verification phase
	verify
	RESULT=$?
	cleanup

	if [ $RESULT -eq 0 ]
	then
		[ -z $TEST_MARK_FAIL ] && return TEST_SUCCESS || return TEST_SUCC_FAIL
	else
		[ -z $TEST_MARK_FAIL ] && return TEST_FAILURE || return TEST_FAIL_OK
	fi
}


# ================================
# Launch all tests from the tests directory
#
function launch_tests
{
	# Get filenames of tests and number of them
	if [ -z $TEST_PATTERN ]
	then
		set -A TEST_FNAMES $TESTS_DIR/*
	else
		set -A TEST_FNAMES $TESTS_DIR/${~TEST_PATTERN}
	fi
	N_TEST_FNAMES=${#TEST_FNAMES}

	# Avoid troubles with non-existent tests
	if [ $N_TEST_FNAMES -eq 0 ]
	then
		error 0 "no tests were found in $TESTS_DIR"

		return 0
	fi

	# Initialize counters
	N_SUCC=0
	N_FAIL=0
	N_ERR=0
	N_SKIPPED=0
	N_BROKEN=0
	N_FAIL_OK=0
	N_SUCC_FAIL=0

	# Graphical representation of each test status,
	# e.g. ....F..FF...E..FEE..
	STATUS_GRAPH=

	echo "$N_TEST_FNAMES tests found"
	echo

	for TEST_FNAME in $TEST_FNAMES
	do
		echo "================================"
		echo "Test: $TEST_FNAME"

		# Launch the test in the subshell...
		(perform_test $TEST_FNAME)
		# ... and decide what to do next
		case $? in
			($TEST_SUCCESS)
				N_SUCC=$((N_SUCC + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[1]}

				echo "Status: SUCCESS"
				;;

			($TEST_FAILURE)
				N_FAIL=$((N_FAIL + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[2]}

				echo "Status: FAILURE"
				;;

			($TEST_ERROR)
				N_ERR=$((N_ERR + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[3]}

				echo "Status: ERROR"
				;;

			($TEST_SKIPPED)
				N_SKIPPED=$((N_SKIPPED + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[4]}

				echo "Status: SKIPPED"
				;;

			($TEST_BROKEN)
				N_BROKEN=$((N_BROKEN + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[5]}

				echo "Status: BROKEN"
				;;

			($TEST_FAIL_OK)
				N_FAIL_OK=$((N_FAIL_OK + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[6]}

				echo "Status: EXPECTED FAILURE"
				;;

			($TEST_SUCC_FAIL)
				N_SUCC_FAIL=$((N_SUCC_FAIL + 1))
				STATUS_GRAPH=${STATUS_GRAPH}${PATTERN_SYMBOLS[7]}

				echo "Status: UNEXPECTED SUCCESS"
				;;
		esac

		echo
	done

	echo "================================"
	echo "$STATUS_GRAPH"
	echo

	echo "Tests total: $N_TEST_FNAMES"
	echo "Tests passed: $N_SUCC ($((100*N_SUCC/N_TEST_FNAMES))%)"
	echo "Tests failed: $N_FAIL ($((100*N_FAIL/N_TEST_FNAMES))%)"
	echo "Tests errors: $N_ERR ($((100*N_ERR/N_TEST_FNAMES))%)"
	if [ $N_SKIPPED -ne 0 ]
	then
		echo "Tests skipped: $N_SKIPPED ($((100*N_SKIPPED/N_TEST_FNAMES))%)"
	fi
	if [ $N_BROKEN -ne 0 ]
	then
		echo "Tests broken: $N_BROKEN ($((100*N_BROKEN/N_TEST_FNAMES))%)"
	fi
	if [ $N_FAIL_OK -ne 0 ]
	then
		echo "Tests failed (expected):"\
			"$N_FAIL_OK ($((100*N_FAIL_OK/N_TEST_FNAMES))%)"
	fi
	if [ $N_SUCC_FAIL -ne 0 ]
	then
		echo "Tests passed (unexpected):"\
			"$N_SUCC_FAIL ($((100*N_SUCC_FAIL/N_TEST_FNAMES))%)"
	fi
}


# ================================
# Default entry point for this framework
#
function main
{
	init
	launch_tests
}


# Check if this framework is used as a lib - if not, call `main()`
if [ -z $LIBRARY ]
then
	main
fi
