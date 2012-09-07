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

build: build/ build/$(BIN) build/$(BIN).bat

build/:
	mkdir build

build/$(BIN):
	cp bin/$(BIN) build/

build/$(BIN).bat:
	cp bin/$(BIN).bat build/

build-deps:
	#$(CPAN_BIN) $(PERL_DEV_DEPS)

install: build build-deps install-deps doc $(DIR)/$(BIN) $(DOC)/$(MAN)

$(DIR)/$(BIN):
	cp build/$(BIN) $(DIR)

$(DOC)/$(MAN):
	cp $(MAN) $(DOC)

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

clean:
	rm -rf build
