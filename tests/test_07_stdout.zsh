DESCRIPTION="Write something to stdout and then verify if it's really it"


function test
{
	cat <<EOF
Follow
the white
rabbit.
EOF
}


function verify
{
	diff $TEST_STDOUT - <<EOF
Follow
the white
rabbit.
EOF
}
