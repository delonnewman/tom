use Test::More;
use lib qw{ lib };
use App::Tom::Utils qw{
  path
  error
  is_win32
  is_linux
  slurp
  spit
  plural
  fetch
  first
};

use File::Spec;

# path
is path(qw{ a b c }) => File::Spec->join(qw{ a b c}), 'testing path';

# is_win32
is is_win32, do { $^O =~ /win32/i }, 'is_win32';

# is_linux
is is_linux, do { $^O =~ /linux/i }, 'is_linux';

# spit and slurp
my $cont = spit('./test.txt', 'this is a test');
is $cont => 'this is a test';
is slurp('./test.txt') => 'this is a test';

# plural
is plural(1, 'test')   => '1 test';
is plural(2, 'test')   => '2 tests';
is plural(3, 'sash')   => '3 sashes';
is plural(4, 'taz')    => '4 tazes',
is plural(5, 'sass')   => '5 sasses';
is plural(6, 'sax')    => '6 saxes';
is plural(7, 'search') => '7 searches';

# first
#my $f = first { $_ == 5 } (1, 2, 3, 4, 5);
#print "\$f: $f";
#ok do { $f == 2 };

fetch 'http://google.com' => sub {
  my ($dom) = @_;
  ok $dom->isa('Mojo::DOM');
};

done_testing;
