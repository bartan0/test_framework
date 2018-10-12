DESCRIPTION="Read something from stdin and verify it's what it should be"


function test
{
	read DATA
}


function verify
{
	echo $DATA | diff - $TEST_STDIN
}
