DESCRIPTION="Check if tmpcopy function works as expected"


function test
{
	tmpcopy foo
	tmpcopy foo bar
}


function verify
{
	if [ ! -e $TEST_TMP/foo ]
	then
		echoerr "there is no foo in tmpdir"
		return 1
	fi

	if [ ! -e $TEST_TMP/bar ]
	then
		echoerr "there is no bar in tmpdir"
		return 1
	fi
}
