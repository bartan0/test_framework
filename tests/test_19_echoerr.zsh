DESCRIPTION="Test if echoerr function works"


function verify
{
	echoerr "echoerr function works"
	echoerr "echoerr function exit code: $?"

	return 0
}
