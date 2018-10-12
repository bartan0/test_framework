DESCRIPTION="Turn merging stderr with stdout on and verify if it works"

STDERR_MERGE=yes


function test
{
	echo "This one goes to stdout..."
	echo "... and this one goes to stderr" >&2
}


function verify
{
	if [ $TEST_STDERR != $TEST_STDOUT ]
	then
		error 0 "TEST_STDERR is not equal to TEST_STDOUT"
		return 1
	fi

	diff $TEST_STDOUT - <<EOF
This one goes to stdout...
... and this one goes to stderr
EOF
}
