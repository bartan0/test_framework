DESCRIPTION="Check if init script was executed before this test"


function verify
{
	if [ -z $_INIT_SCRIPT_LOADED ]
	then
		return 1
	else
		return 0
	fi
}
