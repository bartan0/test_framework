DESCRIPTION="Copy files from data directory to tmp directory and check if \
they're OK"


function test
{
	cp $TEST_DATA/* $TEST_TMP
}


function verify
{
	if ! diff $TEST_TMP/foo $TEST_DATA/foo
	then
		return 1
	fi

	if ! diff $TEST_TMP/bar $TEST_DATA/bar
	then
		return 1
	fi
}
