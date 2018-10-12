DESCRIPTION="Check if content of some files in data directory is OK"


function verify
{
	if ! diff $TEST_DATA/foo - <<EOF
Follow the white
rabbit.
EOF
	then
		return 1
	fi

	if ! diff $TEST_DATA/bar - <<EOF
The white rabbit you follow.
EOF
	then
		return 1
	fi
}
