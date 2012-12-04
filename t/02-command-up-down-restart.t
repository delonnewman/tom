use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Command;

use File::Spec;
use File::Basename;

my $TOM_BIN = File::Spec->join(dirname(__FILE__) => '..', 'bin', 'tom');
say "Testing $TOM_BIN...";

# install a tom cat version
my $version = "5.5.36";
exit_is_num("$TOM_BIN install $version", 0);

exit_is_num("$TOM_BIN version $version", 0);

# check if it's indicated now
my $pat1 = qr/$version - installed/;
stdout_like("$TOM_BIN up", $pat1);

# clean up
exit_is_num("$TOM_BIN uninstall 5", 0);

done_testing;
