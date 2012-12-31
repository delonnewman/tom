package App::Tom;
use v5.10;
use strict;
use warnings;

use App::Tom::Commands;
use App::Tom::Utils;

use Data::Dump qw{ dump };

use English;

use File::Basename;
use File::Copy;
use File::Path qw{ remove_tree make_path };
use File::Spec;
use File::Tail;

use Getopt::Long;

use HTTP::Tiny;

use Mojo::DOM;

BEGIN {
    # Win32 requirements
    if ( $^O =~ /win32/i ) {
        require Win32::OLE;
        Win32::OLE->import();
    }
}

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

use Exporter 'import';
our @EXPORT_OK = qw{
    $HOME
    $ROOT
    $INSTALL
    $VFILE
    @MIRRORS
    $JAVA_BASE
    $ZIP_PATH
    $HOST
    $PORT
    $TIMEOUT
    $ADMIN
};

my $HOME = $ENV{HOME} // "$ENV{HOMEDRIVE}$ENV{HOMEPATH}";
my $ROOT = do {
    my $r = path($HOME => '.tom');
    mkdir $r unless -e $r;
    $r;
};

my $INSTALL   = path($ROOT => 'containers');
my $VFILE     = path($ROOT => 'version');
my @MIRRORS   = map { chomp; "$_/tomcat" } <DATA>;
my $JAVA_BASE = 'C:/Program\ Files/Java';
my $ZIP_PATH  = path($HOME => 'bin' => '7za.exe');

# ping defaults
my $HOST      = 'localhost';
my $PORT      = '8080';
my $TIMEOUT   = 2;

# install options
my $ADMIN     = 0;

GetOptions(
    'host=s'    => \$HOST,
    'port=s'    => \$PORT,
    'timeout=i' => \$TIMEOUT,
    'admin'     => \$ADMIN
);

sub run {
    my @args = @_;

    # Grab second arg after parsing flags
    my $VERSION = do {
        if ( $args[1] && $args[1] =~ /^\d{1,1}((\.\d{1,1})?\.\d{1,2})?$/ ) {
            $args[1];
        }
        else {
            write_to($VFILE => '') unless -e $VFILE;
            slurp($VFILE);
        }
    };
    
    commands(
        help      => \&help,
        install   => sub { exit install($VERSION) },
        uninstall => sub { exit uninstall($VERSION) },
        list      => sub { exit list($VERSION) },
        available => sub { exit available($VERSION) },
        ping      => sub { exit ping($HOST => $PORT, $TIMEOUT) },
        up        => sub { exit ctl(startup  => $VERSION) },
        down      => sub { exit ctl(shutdown => $VERSION) },
        version   => sub { exit default_version($VERSION) },
        restart   => sub { exit restart($VERSION) },
        apps      => sub { exit apps($VERSION) },
        deploy    => sub { exit deploy($VERSION, @args) },
        remove    => sub { exit remove($VERSION, @args) },
        tail      => sub { exit tail($VERSION, @args) },
        env       => sub { exit env($VERSION) },
        java      => sub { exit java($VERSION) }
    );
    
    error(\&help) unless @args;
}

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

1;

__DATA__
http://mirrors.gigenet.com/apache
http://apache.tradebit.com/pub
http://apache.mirrors.pair.com
http://mirror.cc.columbia.edu/pub/software/apache
http://apache.osuosl.org
http://mirrors.sonic.net/apache
