package App::Tom;
use v5.10;
use strict;
use warnings;

our $VERSION = '0.1';

use Getopt::Long;
use Data::Dump qw{ dump };

use lib qw{ lib };
use App::Tom::Config qw{ defconfig config setconfig };
use App::Tom::Utils qw{ path slurp write_to };
use App::Tom::Commands;

=pod

=head1 NAME

    tom - Control tomcat from the command line with simplicity

=head1 SYNOPSIS

    > tom available
    > tom install 5.5.35
    > tom list
    > tom up 5.5.35
    > tom down
    > tom restart
    > tom ping
    > tom version 6.0.35
    > tom uninstall 5.5.35

=cut

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

=pod

=head1 OPTIONS

=head2 C<-p>, C<--port>

Specify the port for pinging (used in C<ping>, C<restart>, C<up>,
and C<down> commands)

=head2 C<-h>, C<--host>

Specify the host for pinging (used in C<ping>, C<restart>, C<up>,
and C<down> commands)

=head2 C<-t>, C<--timeout>

Specify the timeout (in seconds) for pinging (used in C<ping>,
C<restart>, C<up>, and C<down> commands)

=cut

GetOptions(
  'host=s'    => sub { setconfig('HOST'    => $_[1]) },
  'port=s'    => sub { setconfig('PORT'    => $_[1]) },
  'timeout=i' => sub { setconfig('TIMEOUT' => $_[1]) },
  'admin'     => sub { setconfig('ADMIN'   => $_[1]) }
);

# Grab second arg after parsing flags
my $version = do {
  if ( $ARGV[1] && $ARGV[1] =~ /^\d{1,1}((\.\d{1,1})?\.\d{1,2})?$/ ) {
    $ARGV[1];
  }
  else {
    my $f = config('VFILE');
    write_to($f => '') unless -e $f;
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

=pod

=head1 COMMANDS

=head2 up

    tom up [VERSION]

Starts up the version of tomcat specified or the default version if
the version is omitted.

=head2 down

    tom down

Shutsdown the currently running tomcat instance

=head2 restart

    tom restart [VERSION] [OPTIONS]

Restarts a currently running instance of tomcat if one is running otherwise
it just starts a new instance.  Can specify the host, port and timeout (in
seconds) for testing if a tomcat instance is currently running.

=head2 list

    tom list

List all installed versions of Tomcat

=head2 ping

    tom ping [OPTIONS]

Test if a HTTP server is running at a given host and port combination,
can also specify a timeout in seconds.  The default host is "localhost",
the default port is 8080, and the default timeout is 2 seconds.

=head1 version

    tom version VERSION

Set a default version

=head2 available

    tom available

List all versions of Tomcat that are available for install

=head2 uninstall

    tom uninstall VERSION

Uninstalls a version of Tomcat

=head2 install

    tom install VERSION

Installs a version of Tomcat

=head2 tail
    
    tom tail [VERSION] [LOGFILE]

Display log entries as they are logged can optionally specify a Tomcat
version or a log file in CATALINA_HOME/logs.

=head2 apps
    
    tom apps [VERSION]

Deploy a web application to a given version of Tomcat via a warfile
or directory.

=head2 deploy
    
    tom deploy [VERSION] WARFILE|DIRECTORY

Deploy a web application to a given version of Tomcat via a warfile
or directory.

=head2 remove

    tom remove [VERSION] APPNAME

Remove a deployed app from a given version of Tomcat.

=head2 env
    
    tom env

Display environment information

=head2 java
    
    tom java [JAVA_VERSION]

Set and view JAVA_HOME environment variable

=head2 help

    tom help

Displays a help message

=head1 REQUIREMENTS

=head2 General

    perl 5.10 or greater
    HTTP::Tiny
    Mojo::DOM 3.38

=head2 Windows

    Win32::OLE

    7za (the command line version of 7zip) installed in C:\Users\[USERNAME]\bin
    for install command

=head2 Unix

    GNU tar (on PATH) for install command

=head1 AUTHOR

    Delon Newman <delon.newman@gmail.com>

=cut

__DATA__
http://mirrors.gigenet.com/apache
http://apache.tradebit.com/pub
http://apache.mirrors.pair.com
http://mirror.cc.columbia.edu/pub/software/apache
http://apache.osuosl.org
http://mirrors.sonic.net/apache
