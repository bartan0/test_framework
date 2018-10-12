DESCRIPTION="Just print the contents of important variables"


function verify
{
	echo "TEST_DATA: $TEST_DATA"
	echo "TEST_TMP: $TEST_TMP"
	echo "TEST_STDIN: $TEST_STDIN"
	echo "TEST_STDOUT: $TEST_STDOUT"
	echo "TEST_STDERR: $TEST_STDERR"
}
