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

package: tom.zip

tom.zip: build-win32
	zip tom.zip -rf build/*

build: build/ build/$(BIN) build/$(MAN) build/README

build-win32: clean-code build build/$(BIN).bat build/7zip build/perl build/install.bat build/install

build/install.bat:
	cp scripts/install.bat build/

build/install:
	cp scripts/install build/

build/7zip:
	unzip -o extra/7za920.zip -d build/7zip

build/perl:
	unzip -o extra/perl -d build/

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

clean-code:
	rm build/tom
	rm build/tom.bat
	rm build/install.bat
	rm build/install
