Simple shell-based testing framework v1.0.0
===========================================

This framework simplifies writing tests for an application under development
and automates the testing process. It is best-suited to be used with command
line interface (CLI) applications. The tests are shell scripts that define
*handlers* for some *test phases*.


Features
--------

* tests are based on setup-test-verify-cleanup model

* every test has access to its own static and temporary data

* while verifing the results, an access to test *stdin*, *stdout* and *stderr*
  is provided

* global initialization script can be launched before every test

* selected tests can be skipped or marked as broken

* "expected failure" / "unexpected success" test results support

* printing tests statistics

* simple reconfiguration can turn this framework into library that can be
  used by a bigger project then


Requirements
------------

This framework is a shell script so a shell is required:

Z shell (zsh)
	It is recommended to use *zsh*. *zsh* was used during development and testing
	of this framework so everything should work as expected and be stable with
	this shell.

GNU Bourne-Again SHell (bash)
	This shell is not recommended, with an exception for testing purposes. With
	*bash*, some things may be unstable or broken. Support for *bash* will be
	added in the future. If you had decided to use *bash* and have encountered
	any bugs or something not working as it should, feel free to email me (see
	Authors_).

Other shells
	Support for shells other than *zsh* and *bash* is not currently planned. If you
	use other shell and decide to test how this framework works with it,
	I strongly encourage you to email me (see Authors_) and write your
	observations.


Installation
------------

This project repository can be obtained from GitHub::

	$ git clone 'https://github.com/bartan0/test_framework'

After downloaded this project is not intended to be installed in any way. You
can deploy it into your existing project (see `Deploying the framework`_).
After the framework is deployed you can either delete the downloaded repo or
leave it for deploying into another project.


Usage
-----

In order to use this framework you need to have a project you would like to
enable tests for. Let's say you have a project that looks like this::

	~/app
	├── main.c
	└── Makefile

*main.c*::

	#include <stdio.h>

	int main(void) {
		printf("Follow the white rabbit.\n");

		return 0;
	}

*Makefile*::

	.PHONY: all clean

	all: main

	clean:
		rm -fv *.o
		rm -fv main

	main: main.o

The specification of our *main* program would be like this:

* prints "Follow the white rabbit."

* returns 0 to the shell

These above are two things we need to test.


Deploying the framework
.......................

First thing to do is to *deploy* the testing framework into our project. Let's
create directory *test*, which will become the root dir of the framework::

	$ cd ~/app
	$ mkdir test

Now, cd into this project root directory (let's assume you have already
downloaded this project's tarball into *~/test_framework-X.Y.Z.tar.gz* and
extracted it into your home directory)::

	$ cd ~/test_framework-X.Y.Z

Deploy the framework into our project (the *TARGET* envvar must be set to the
project's *test* directory)::

	$ TARGET=~/app/test make deploy

The testing framework is now enabled for our project - let's cd into it::

	$ cd ~/app/test
	$ ls

The structure of the framework is quite simple right now - we have empty
directory *tests* and a file *test.zsh*. It is possible to make some
configuration to the framework by editing the *configuration* section of
*test.zsh*. For now, default configuration will be OK.

Let's run the framework::

	$ zsh test.zsh
	test.zsh: no tests were found in ./tests

We hadn't written any tests yet so the framework haven't had anything
interesting to do - it have just printed the message and exited. It's worth to
notice an empty directory *tmp* has been created. All temporary data created by
the tests as well as tests' *stdout* and *stderr* dumps will go there.


Writing tests
.............

We need to write two tests: one that tests if our *main* program prints "Follow
the white rabbit" message and the other that tests if the program returns
status code 0.

By default, tests are files placed in *test/tests* directory with filenames
like *test_<X>.<Y>sh*, where *<X>* and *<Y>* are any strings.

Create the first test::

	$ cd ~/app/test/tests
	$ cat >test_01_message.zsh
	DESCRIPTION="Test if the program prints the right message"

	function test
	{
		$ROOT_DIR/main

		return 0
	}

	function verify
	{
		diff $TEST_STDOUT - <<EOF
	Follow the white rabbit.
	EOF
	}

By setting *DESCRIPTION* variable, an description for the test can be given.
Once the framework is run, it will display description for each test that
provides one.

Every test should define some functions with specific names (also referred as
*handlers* here) - in our case, two handlers are defined: *test* and *verify*.

The role of the *test* handler is to perform actions being tested - in our case
lauching *main*. The *test* handler must not decide whether the test was passed
or not - its role is to *act*, not to *judge*. Return code of *test* handler
does matter - it must return 0 if test actions were performed without problems
or 1 otherwise (in our case - if *main* returns nonzero, that's not a problem -
maybe the right message was printed, maybe not - we don't know yet - hence,
*test* handler always returns 0 - a good reason for it to return 1 would be
non-existent or non-executable *main* file).

The second handler we defined is *verify* handler. This is the right place to
decide whether the test was passed or failed. *verify* handler should assume
all tested actions have been performed and all their results and side effects
are brought into life. The role of *verify* handler is to check if this
assumption is indeed correct and return 0 if everything's as expected or 1
otherwise. In our case, the *verify* handler checks if dump of *stdout* of
*main* contains the right thing (we use *diff* command here so the return code
will be right in any case).

The *verify* handler makes use of *TEST_STDOUT* variable. This variable is
available to every test script and contains path to a dump of *stdout* of the
*test* handler. It is only safe to use the dump file in the *verify* handler.
The important thing to note here is the contents of the dump file - it contains
**"stdout" of "test" handler**, not just *stdout* of some commands executed
there.  For example, if our *test* handler have executed *main* twice, the
*stdout* dump file would contain concatenation of *stdout* of each *main*
instance.

Let's go on and create the second test - the point is to test the return code
of *main* here::

	$ cat >test_02_return_code.zsh
	DESCRIPTION="Test if the program returns the right exit code"

	function test
	{
		$ROOT_DIR/main
		_EXIT_CODE=$?

		return 0
	}

	function verify
	{
		[ $_EXIT_CODE -eq 0 ]
	}

There's nothing new here except one thing: using variables to carry information
between handlers. If this is the best/simplest way to achive your goals, you
can do it - everything will work but there's one thing to remember about - the
order of calling handlers (see *REFERENCE.rst*, section *Handlers calling
order*).


Launching tests
...............

In order to be able to test anything, we need to build our project first::

	$ cd ~/app
	$ make

We can launch the tests now. It's very important to cd into testing framework
root directory::

	$ cd ~/app/test

The framework can be launched now::

	$ zsh test.zsh
	2 tests found

	================================
	Test: ./tests/test_01_message.zsh
	* Test if the program prints the right message

	Status: SUCCESS

	================================
	Test: ./tests/test_02_return_code.zsh
	* Test if the program returns the right exit code

	Status: SUCCESS

	================================
	..

	Tests total: 2
	Tests passed: 2 (100%)
	Tests failed: 0 (0%)
	Tests errors: 0 (0%)

A number of lines are printed. Let's explain what's going on.

First, we get informed that 2 tests were found. Since we created 2 tests,
everything seems to be OK.

A block of information about the test for each of the tests follows. The block
includes information such as:

* filename of the test

* description of the test (as specified by *DESCRIPTION* variable)

* anything printed by the test's handlers (except for the *test* handler - its
  output is dumped into a file - see *REFERENCE.rst* file, section *Test static
  and temporary data*)

* status of the test, e.g. success, failure, error, etc.

The last block contains summarized statistics about the tests. First, a tests
status pattern is printed - each letter refers to status of one test (in the
same order as the previous blocks). By default, '.' means the test's state was
one of "good" ones (by default it doesn't have to mean the test was passed -
see *configuration* section in *test.zsh* file), 'F' means the test failed and
'!' means some errors were encountered during the test and it couldn't be
launched properly. Next lines should be self-explanatory.

In order to make things better and faster we can add the following target to
our project's *Makefile*::

	test: main
		cd test; zsh test.zsh

It's nice to make this target *.PHONY* to make it executed always when ``make
test`` is run.

The *cd test* part is important because *make* would be executed from the
project's root directory and the testing framework must be launched from its
own root directory (*test* in our case).

Let's see if everything works well::

	$ cd ~/app
	$ make clean
	$ make test

Our project should be built and then the testing framework should be launched
resulting in output just like the one presented above.

If everything goes well, it's time to introduce some bugs into our code ;).
Make *main.c* look like this::

	#include <stdio.h>

	int main(void) {
		printf("Follow thewhite rabbit.\n");

		return 42;
	}

Let's test the project now::

	$ make test
	cc    -c -o main.o main.c
	cc   main.o   -o main
	cd test; zsh test.zsh
	2 tests found

	================================
	Test: ./tests/test_01_message.zsh
	* Test if the program prints the right message

	1c1
	< Follow thewhite rabbit.
	---
	> Follow the white rabbit.
	Status: FAILURE

	================================
	Test: ./tests/test_02_return_code.zsh
	* Test if the program returns the right exit code

	Status: FAILURE

	================================
	FF

	Tests total: 2
	Tests passed: 0 (0%)
	Tests failed: 2 (100%)
	Tests errors: 0 (0%)

Two failures - just as expected. In the first test we have used *diff* command
so we have pretty nice explanation on what went wrong, but the second failure
is quite cryptic - let's fix it. Make the *verify* function of the second test
look like this::

	function verify
	{
		if [ $_EXIT_CODE -ne 0 ]
		then
			echoerr "main: exit code: $_EXIT_CODE"
			return 1
		fi
	}

The framework provides the *echoerr* function that can be used by tests to
report errors or warnings. In our case, we use this function to print the exit
code if it's different than expected.

Launch the tests again::

	$ make test

The reason of the second failure is clear now.

--------------------------------

You know how to write basic tests now. If you would like to learn something
more about this framework, the next thing to read is *REFERENCE.rst* file - it
provides full description of every aspect of this framework from user
perspective.


Testing
-------

You can test if this framework works in your environment by typing (it may be a
good idea to pipe the output to *less*)::

	make test

The command above uses this framework to test itself - not very helpful if the
framework's "core" does not work well - hence the tests does not test the "core"
features at all. I belive it works and I can't prove it ;)

The command above adds some lines to the normal output of the framework - the
expected tests status pattern is printed (some of the tests must fail while the
others must throw error). Compare this pattern to the actual one printed by the
framework to have a quick info if everything's fine.

Once new tests are added, it is important to update *TEST_PATTERN* variable in
*Makefile*.

More tests are welcome (see Contributing_)!


Reference
---------

Refer to *REFERENCE.rst* file to see full description of all the features
available to test scripts and *test.zsh* configuration manual.


Contributing
------------

If you would like to add (or remove ;) ) anything to this project or just have
some nice thoughts or ideas on it - feel free to email me (see Authors_).

Check the *TODO.rst* file as well :)


Versioning
----------

This project uses SemVer_ for versioning.

When the version needs to be changed, there are several places to edit.

*Makefile*
	* value of *VERSION* variable

*README.rst*
	* version number in the top-level title

*REFERENCE.rst*
	* version number in the top-level title

*test.zsh*
	* value of *__VERSION__* variable

.. _SemVer: https://semver.org/


Authors
-------

This software was created by Bartłomiej Sługocki (0@bartan0.pl).


License
-------

This project is licensed under MIT License. See *LICENSE* for details.


Acknowledgments
---------------

This framework (the information it prints once run especially) was inspired by
`Python unittest framework`_.

.. _Python unittest framework: https://docs.python.org/3/library/unittest.html
