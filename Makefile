NAME = 'test_framework'
VERSION = '1.0.1'

# Expected pattern to be outputted by the framework
TEST_PATTERN = F.F!!.......!...FF..F

# Distribution directory (created distarchives will be placed here)
DISTDIR = dist

# The distribution archive will contain these files and directories
# (recursively)
#
DISTFILES = \
	.git .gitignore Makefile \
	LICENSE README.rst REFERENCE.rst TODO.rst \
	test.zsh data tests

DISTNAME = $(NAME)-$(VERSION)

# Files to be copied into TARGET directory by `deploy` target
DEPLOY_FILES = \
	test.zsh

.PHONY: all clean test dist deploy version

all:

clean:
	rm -rfv dist
	rm -rfv tmp

test:
	zsh test.zsh
	@echo
	@echo "Expected tests status pattern:"
	@echo $(TEST_PATTERN)

dist:
	mkdir -p $(DISTDIR)
	mkdir $(DISTNAME)
	cp -rv $(DISTFILES) $(DISTNAME)
	tar -czf $(DISTDIR)/$(DISTNAME).tar.gz $(DISTNAME)
	rm -rf $(DISTNAME)

# Inject everything that is important into existing project
#
# Variable TARGET must be set to the path of appropriate target project test
# directory; it is an error if the directory does not exist.
#
deploy:
	$(if $(TARGET),, $(error Variable TARGET is not set))
	$(if $(shell [ -d $(TARGET) ] && echo true),, \
		$(error Directory $(TARGET) does not exist))
	cp -rv $(DEPLOY_FILES) $(TARGET)
	mkdir -p $(TARGET)/tests
