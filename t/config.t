use Test::More;
use lib qw{ lib };
use App::Tom::Utils qw{ path };
use App::Tom::Config qw{ defconfig config setconfig };

use POSIX qw{ strftime };

defconfig(
  HOME  => sub { $ENV{HOME} },
  ROOT  => sub { path config('HOME') => 'test' },
  PLAIN => 'plain'
);

is config('PLAIN'), 'plain';

is config('HOME'), $ENV{HOME};
is config('ROOT'), path $ENV{HOME} => 'test';

setconfig('TEST' => 'this is a test');
is config('TEST') => 'this is a test';

setconfig 'CLOSURE' => sub { 'closure' };
is config('CLOSURE'), 'closure';

# content is closures is evaluated lazily
my $before = strftime('%s', localtime);

setconfig 'LAZY' => sub { sleep 5 };
my $after_assign = strftime('%s', localtime);

config('LAZY'); # force evaluation
my $after_eval = strftime('%s', localtime);

ok (($after_assign - $before) < 5), "LAZY param not evaluated on assignment";
ok (($after_eval - $after_assign) >= 5), "LAZY param evaluated when accessed";

done_testing;
