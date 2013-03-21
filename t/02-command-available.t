use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Command;

use File::Spec;
use File::Basename;

my $TOM_BIN = File::Spec->join(dirname(__FILE__) => '..', 'bin', 'tom');
say "Testing $TOM_BIN...";

# nothing installed
my $pat1 = qr/Tomcat versions available for install:\n(\d.\d.\d\d\n)+/;
stdout_like("$TOM_BIN available", $pat1);

# install a tom cat version
my $version = "6.0.35";
exit_is_num("$TOM_BIN install $version", 0);

# check if it's indicated now
my $pat2 = qr/$version - installed/;
stdout_like("$TOM_BIN available", $pat2);

# clean up
exit_is_num("$TOM_BIN uninstall 5", 0);

done_testing;
