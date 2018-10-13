Simple shell-based testing framework v1.0.1 - Reference
=======================================================

A reference for testing framework. All features available to the user of the
framework are either described here or a reference to a proper place is
provided.

You are strongly encouraged to read the *README.rst* file before reading this
document. The *README.rst* file includes a general description of the
framework and an introductory tutorial that should help you to learn the basics
in a quick'n'easy way.


*make* targets
--------------

The following *make* targets are supported:

*deploy*
	Deploy the testing framework into existing project. This target will work
	only if *TARGET* variable is set - it should be set to the intended root
	directory of the target project (*test* is common).

	Example::

		TARGET=~/app/test make deploy

*test*
	Launch self-tests. See *README.rst*, section *Testing* for details and
	discussion.

*dist*
	Make distribution tarball. By default the tarball is saved in *dist*
	directory.

*clean*
	Remove *dist* and *tmp* directories.

*all*
	Dummy default target - does nothing.

For details, see *Makefile*.


*test.zsh* configuration
------------------------

Configuration of the framework is possible by modifing variables in the
configuration section of the *test.zsh* file - see *test.zsh* for details
(documentation comments included).


Handlers
--------

Handlers are functions defined by tests that are (generally) called by the
framework. The framework uses return codes of the handlers in order to decide
what to do next (i.e. whether to continue performing given test or not).

All handlers are optional (i.e. the test does not have to define any of them).
If a handler is not defined, the default one will be used. For *setup*,
*cleanup* and *test* handlers, the defaults are empty functions (return code
0). For *verify* handler, the default one prints a warning message and returns
1 (failure - it's more common the test creator forgets to define the handler
than the test does not need one). The framework either calls no handlers at all
or calls the handlers (possibly not all) in a strictly specified order (see
`Handlers calling order`_).

*test*
	This handler should perform all the activities that are to be tested. This
	handler mustn't decide if the test is passed or failed.

	This handler must return 0 if tested activities were performed (without
	worring whether they failed or not) or 1 if the activities couldn't have
	been performed.

*verify*
	This is the right place for the code that would verify if the test is passed
	or failed. The role of this handler is to perform all the checks, print the
	errors and warnings and make the decision: either the test has been passed
	or not.

	Return codes: 0 - test passed, 1 - test failed.

*setup*
	The role of this handler is to set the environment for the test up. If the
	test require to perform some preparation steps before it can be launched -
	this is the right place to put the commands in.

	Return codes: 0 - setup completed, 1 - something went wrong, test can't be
	launched.

*cleanup*
	Some tests make some dirt. This includes interaction with the system and
	playing with the files outside the test's temporary directory provided by
	this framework. This handler is called for every test as a "last phase" to
	allow the test to sort out a mess it have made.

	Return code does not matter (at least for the framework).


Handlers calling order
----------------------

For every test, if any handlers are called, they are called in a specific
order:

1. *setup*

2. *test*

3. *verify*

4. *cleanup*

If *setup* or *test* handler fails, the *cleanup* handler is called and no more
handlers are called (for this test). *verify* handler will never fail - if it
returns 1, this means the test failed but no errors were encountered.


Global initialization script
----------------------------

If your tests need some common definitions or some special initialization, it
is possible to enable *global initialization script* feature. The *global
initialization script* would be launched just before every test script and all
variables and functions it defines would be provided to the test script.

By default, the feature is disabled. In order to enable it, edit the
configuration section of the *test.zsh* file. There's a variable
*TEST_INIT_SCRIPT* there. Change its value to the path to the initialization
script relative to the framework root directory (you will have to create this
script). The feature is now enabled and the script shall be executed once for
every test before the test and in the context of the test. It is a fatal error
if the feature is enabled and the script does not exist or can't be loaded.


Test control variables
----------------------

Every test can set a number of variables which control the way the test is
handled by the framework. For any variable below, if its default value is not
specified, the default value is empty string.

*DESCRIPTION*
	A description of the test. It is printed for each test when the framework
	is run. If set to empty string, no description would be printed for the
	test.

	::

		DESCRIPTION="The best test that tests the whole Universe"

*STDERR_MERGE*
	This variable controls whether test *stderr* shall be merged with its
	*stdout*. If this variable is non-empty, both the *test* handler *stdout*
	and *stderr* would be dumped into the *stdout* dump file of the test.

	::

		# stdout and stderr will be saved into separate files
		STDERR_MERGE=

		# stdout and stderr will be merged and saved into single file
		STDERR_MERGE=true

*TEST_MARK_BROKEN*
	Mark this test as broken. No handlers would be called for broken tests and
	their status would be either *BROKEN* or *ERROR* (if the test could not
	have been loaded). If the test is both marked as broken and "to skip", it
	would be considered broken.

	::

		# This test is OK, perform it
		TEST_MARK_BROKEN=

		# This test is broken - it will not be launched
		TEST_MARK_BROKEN=true

*TEST_MARK_FAIL*
	Mark this test as the one that should fail. Set this variable to "inverse"
	the sense of *success* and *failure*.

	::

		# This test is expected to succeed
		TEST_MARK_FAIL=

		# This test is expected to fail
		TEST_MARK_FAIL=true

*TEST_MARK_SKIP*
	Mark the test as the one to be skipped. No handlers would be called for
	this test and the status of this test would be either *SKIPPED* or *ERROR*
	(if e.g. syntax errors had been encountered on loading). If the test is
	both marked as "to skip" and broken, it would be considered broken.

	::

		# Do not skip this test
		TEST_MARK_SKIP=

		# Skip this test
		TEST_MARK_SKIP=true


Information available to tests
------------------------------

A number of variables is set for every test script. Value of any of these
variables should not be changed.

*ROOT_DIR*
	Path to the original project root directory relative to this framework root
	directory.

*TEST_DATA*
	Path to this test static data directory.

	For details, see `Test static and temporary data`_.

*TEST_FNAME*
	Path of the test script file (relative to the framework root directory).

*TEST_FSTEM*
	Stem of the test filename (filename with extension stripped off).

*TEST_STDIN*
	Path to a file which content shall be piped to *test* handler *stdin* of
	this test. Note that this file does not exist unless created by the test
	creator.

*TEST_STDOUT*
	Path to a dump of *stdout* of *test* handler of this test.

*TEST_STDERR*
	Path to a dump of *stderr* of *test* handler of this test. This file is not
	created if *STDERR_MERGE* variable is set.

*TEST_TMP*
	Path to this test temporary data directory.

	For details, see `Test static and temporary data`_.


Functions available to tests
----------------------------

Every test can execute any command available to the shell. This framework
provides two additional functions that are available to any test.

*echoerr (msg)*
	Print an error or warning message *msg* to *stderr*.

*tmpcopy (src, dst = src)*
	Copy (recursively) *src* from static data to temporary data as *dst*.


Test static and temporary data
------------------------------

Every test has access to its own static and temporary data. Static data is any
data the test needs to work properly and does not need to change (or remove)
it. Temporary data is any data created by the test during its runtime that
would not be needed after the test is performed.

Sometimes the test needs to modify some data that is provided to it (think of a
test that modifies database file - the file should be provided as static data
but would be modified as well). In that case, a temporary copy of the static
data should be made (something like ``tmpcopy foo``) and any changes should be
made to the temporary copy only.


Static data
...........

The framework does not create any static data for any test. It's the test
creator who decides what (if any) static data would be needed by the test and
then creates the data.

By default, all static data for the test must be placed in
*<root>/data/<test_stem>* directory (static data directory), where *<root>* is
the framework root directory and *<test_stem>* is the filename of the test
without the (last) extension. Subdirectories in the static data directory are
allowed. Names of the files in the static data directory does not matter - with
one exception: if the directory contains file named *stdin*, the content of
this file would be piped to test's *test* handler *stdin*.

Any test can get the path (relative) to its data directory from *TEST_DATA*
variable.

Examples:

All examples below assume default configuration of *test.zsh* is used.

* We have a test script *test_01_first.zsh* placed in *tests* directory. The
  test needs to read some data from *stdin*. We need to create file
  *data/test_01_first/stdin* and fill it with everything we would like to put
  on test's *test* handler *stdin*.

* We have a test script *test_02_second.zsh* placed in *tests* directory. The
  test needs to read some data from a file. We have to create this file and
  ensure the test refers to it properly. First thing to do is to create file
  *data/test_02_second/foo* and put some content into it. Next, we have to
  check how the test refers to the file. It should be something like
  *$TEST_DATA/foo*.

* We have a test script that does not need any static data. We don't have to do
  anything - no subdirectory in *data* is required.


Temporary data
..............

The framework creates temporary data directory for every test. A test can
create any files and directories in its temporary directory. The test's
*stdout* and *stderr* dumps would be placed in this directory by the framework.
The important thing to note is that the temporary directory would be cleared
every time the framework is run.

By default, the temporary data directory for a test is a subdirectory of the
*tmp* subdirectory of the framework root directory. The name of the directory
is the stem of name of the test.

Any test can get its temporary directory from *TEST_TMP* variable.

Examples:

All examples below assume no changes were made to configuration of *test.zsh*.

* We have a test that needs to create a file and then check if the file exists.
  Somewhere in the code we will need to specify the file's path. We should
  write something like *$TEST_TMP/foo*.

* Our test *test* handler writes something to its *stdout*. The *verify*
  handler shall then check if the *stdout* have been correct. It can refer to
  the *stdout* dump file in this way: *$TEST_TMP/stdout*. If we were interested
  in dump of *stderr*, we would use *$TEST_TMP/stderr*.


Test status
-----------

After the test has been performed its status is outputted. Every test can end
up in one of the states presented below. Some of the states require one of the
control variables to be set (see `Test control variables`_).

*SUCCESS*
	Everything went fine - the test was performed and it was passed.

*FAILURE*
	The test was performed without problems and it failed.

*ERROR*
	The test was either not passed nor failed - there were some errors during
	performing it.

*SKIPPED*
	The test was marked as the one to be skipped so it was skipped.

*BROKEN*
	The test was marked as broken one and was not performed.

*EXPECTED FAILURE*
	The test was expected to fail and it actually failed.

*UNEXPECTED SUCCESS*
	The test was expected to fail but it succeeded.
