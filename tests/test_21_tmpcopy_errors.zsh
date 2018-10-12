DESCRIPTION="Check if tmpcopy function does not work as not expected"


function setup
{
	# Argument is required
	tmpcopy
	# x does not exist
	tmpcopy x

	return 0
}
