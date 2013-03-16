use Test::More;
use lib qw{ lib };
use App::Tom::Utils qw{ path };
use App::Tom::Config qw{ defconfig config setconfig };

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

done_testing;
