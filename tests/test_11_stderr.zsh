DESCRIPTION="Write something to stderr, check if the right file contains the \
output"


function test
{
	echo "Some kind of weird message" >&2
}


function verify
{
	diff $TEST_STDERR - <<EOF
Some kind of weird message
EOF
}
