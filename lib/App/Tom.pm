package App::Tom;
use v5.10;
use strict;
use warnings;

our $VERSION = '0.1';

use Getopt::Long;
use Data::Dump qw{ dump };

use lib qw{ lib };
use App::Tom::Config qw{ defconfig config setconfig };
use App::Tom::Utils qw{ path slurp spit };
use App::Tom::Commands;

defconfig(
  HOME => sub { $ENV{HOME} // "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" },

  ROOT => sub {
    my $r = path(config('HOME') => '.tom');
    mkdir $r unless -e $r;
    $r;
  },

  INSTALL   => sub { path(config('ROOT') => 'containers') },
  VFILE     => sub { path(config('ROOT') => 'version') },
  MIRRORS   => sub { [map { chomp; "$_/tomcat" } <DATA>] },
  JAVA_ROOT => sub { path(config('ROOT') => 'javas') },

  ZIP_PATH  => sub { path(config('HOME') => 'bin' => '7za.exe') },

  JAVA_PATH => sub {
    ( '/usr/lib/jvm', config('JAVA_ROOT') );
  },

  # ping defaults
  HOST    => 'localhost',
  PORT    => '8080',
  TIMEOUT => 2,

  # install options
  ADMIN   => 0
);

GetOptions(
  'host=s'    => sub { setconfig('HOST'    => $_[1]) },
  'port=s'    => sub { setconfig('PORT'    => $_[1]) },
  'timeout=i' => sub { setconfig('TIMEOUT' => $_[1]) }
);

# Grab second arg after parsing flags
my $version = do {
  if ( $ARGV[1] && $ARGV[1] =~ /^\d{1,1}((\.\d{1,1})?\.\d{1,2})?$/ ) {
    $ARGV[1];
  }
  else {
    my $f = config('VFILE');
    spit($f => '') unless -e $f;
    slurp($f);
  }
};

sub MAIN {
  my @args = @_;

  commands(
    help      => \&help,
    install   => sub { exit install($version) },
    uninstall => sub { exit uninstall($version) },
    list      => sub { exit list($version) },
    available => sub { exit available($version) },
    ping      => sub { exit ping() },
    up        => sub { exit ctl(startup  => $version) },
    down      => sub { exit ctl(shutdown => $version) },
    version   => sub { exit default_version($version) },
    restart   => sub { exit restart($version) },
    apps      => sub { exit apps($version) },
    deploy    => sub { exit deploy($version, @args) },
    remove    => sub { exit remove($version, @args) },
    tail      => sub { exit tail($version, @args) },
    env       => sub { exit env($version) },
    java      => sub { exit java($version) },
    art       => \&art
  )->(@args);
  
  &help unless @args;
}

1;

__DATA__
http://mirrors.gigenet.com/apache
http://apache.tradebit.com/pub
http://apache.mirrors.pair.com
http://mirror.cc.columbia.edu/pub/software/apache
http://apache.osuosl.org
http://mirrors.sonic.net/apache
