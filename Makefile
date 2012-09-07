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

build: build/ build/$(BIN) build/$(BIN).bat build/$(MAN) build/README

build/:
	mkdir build

build/$(BIN):
	cp bin/$(BIN) build/

build/$(BIN).bat:
	cp bin/$(BIN).bat build/

build/$(MAN):
	cp doc/$(MAN) build/

build/README:
	cp README build/

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

doc: README $(BIN).1

README:
	pod2text bin/$(BIN) > README

$(BIN).1:
	pod2man -c $(BIN) bin/$(BIN) > doc/$(BIN).1

clean:
	rm -rf build
