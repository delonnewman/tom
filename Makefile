.PHONY: all install uninstall doc build build-deps clean_doc install-deps

# files
BIN=tom
MAN=$(BIN).1

# dirs
DIR=/usr/local/bin
DOC=/usr/local/share/man/man1

# dependencies
CPAN_BIN=cpanm
PERL_DEPS=
PERL_DEV_DEPS=

all: build-deps

build:

build-deps:
	#$(CPAN_BIN) $(PERL_DEV_DEPS)

install: build build-deps install-deps doc
	cp $(BIN) $(DIR)
	cp $(MAN) $(DOC)
	cp $(SCRIPT) $(DIR)
	cp $(RULE) $(UDEV)

install-deps:
	#$(CPAN_BIN) $(PERL_DEPS)

uninstall:
	rm $(DIR)/$(BIN)
	rm $(DOC)/$(MAN)

doc: clean_doc README $(BIN).1

clean_doc:
	rm README # force update
	rm $(BIN).1 # force update

README:
	pod2text $(BIN) > README

$(BIN).1:
	pod2man -c $(BIN) $(BIN) > $(BIN).1
