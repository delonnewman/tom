use Test::More;
use lib qw{ lib };
use App::Tom::Utils qw{
  path
  error
  is_win32
  is_linux
  slurp
  spit
  read_from
  write_to
  plural
  fetch
  first
  chomped
};

use File::Spec;

# path
is path(qw{ a b c }), File::Spec->join(qw{ a b c}), 'testing path';

# is_win32
is is_win32, do { $^O =~ /win32/i }, 'is_win32';

# is_linux
is is_linux, do { $^O =~ /linux/i }, 'is_linux';

# spit and slurp, write_to and read_from
my $c1 = spit('./test.txt', 'this is a test');
is $c1 => 'this is a test';
is slurp('./test.txt') => 'this is a test';

# array context
spit './test-array-context.txt', "this\nis\na\nlist";
my @lines = slurp('./test-array-context.txt');
is_deeply \@lines, ["this\n", "is\n", "a\n", "list"];
is slurp('./test-array-context.txt') => "this\nis\na\nlist";

my $c2 = write_to('./test1.txt', 'this is another test');
is $c2 => 'this is another test';
is read_from('./test1.txt') => 'this is another test';

# plural
is plural(1, 'test')   => '1 test';
is plural(2, 'test')   => '2 tests';
is plural(3, 'sash')   => '3 sashes';
is plural(4, 'taz')    => '4 tazes',
is plural(5, 'sass')   => '5 sasses';
is plural(6, 'sax')    => '6 saxes';
is plural(7, 'search') => '7 searches';

# first
my $f = first { $_[0] % 2 == 0 } 1..5;
is $f, 2;

fetch 'http://google.com' => sub {
  my ($dom) = @_;
  ok $dom->isa('Mojo::DOM');
};

is chomped "hiya\n", "hiya";

done_testing;
