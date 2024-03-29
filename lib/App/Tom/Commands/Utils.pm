package App::Tom::Commands::Utils;
use v5.10;
use strict;
use warnings;

use Exporter qw{ import };
our @EXPORT = qw{
  determine_os
  determine_java
  parse_version
  get_versions
  select_version
  select_java
  get_javas
  extract
  get_available
  select_available
  fetch_install
  mirrormap
  open_browser
  registry
  write_registry
  say_java_home
};

use English qw{ -no_match_vars };

use File::Basename;
use File::Copy;
use File::Path qw{ remove_tree make_path };
use File::Spec;
use File::Tail;

use Mojo::DOM;

use App::Tom::Config qw{ config };
use App::Tom::Utils qw{ error slurp chomped path fetch first is_linux is_macos is_win32 };

sub determine_os {
  if ( $OSNAME ne 'linux' ) { $OSNAME // 'N/A' }
  else {
    my $redhat = '/etc/redhat-release';
    my $debian = '/etc/lsb-release';
    if ( -e $redhat ) { 
      local $_ = slurp($redhat);
      chomp;
      $_;
    }
    elsif ( -e $debian ) {
      my $desc = grep { /DESCRIPTION/ } split(/\n/, slurp($debian));
      $desc =~ /="([\w.\s]+)"/;
      $1;
    }
    else { $OSNAME }
  }
}

sub get_java_path {
  if ( my $path = $ENV{JAVA_HOME} ) { $path }
  else {
    if ( my $out = `which java` ) { chomped($out) }
    else {
      "N/A";
    }
  }
}

sub get_java_version {
  my ($path) = @_;
  if ( !-e $path ) { "N/A" }
  else {
    local $\='';
    open(my $info, "$path -version 2>&1 |") or die "Can't read from $path: $!"; 
    <$info> =~ /(\w+\sversion\s.*)/;
    $1;
  }
}

sub determine_java {
  my $path    = get_java_path();
  my $version = get_java_version($path);
  return $path unless $version;

  "$version ($path)";
}

sub parse_version {
    split /\./ => $_[0];
}

sub get_versions {
  my %reg = registry();
  keys %reg;
}

sub selector {
    my %args = @_;
    $args{versions} || die "versions callback is required";

    return sub {
        my ($version, $fn) = @_;

        my @versions = $args{versions}->($version);
        if ( @versions == 1 ) {
            if ( $args{one} ) { return $args{one}->($versions[0], $fn) }
            else {
                return $fn->($versions[0]);
            }
        }
        elsif ( @versions < 1 ) {
            if ( $args{less} ) { return $args{less}->($fn) }
            else {
                say "Version $version is not installed, use the install command to install it";
                return 1;
            }
        }
        else {
            if ( $args{more} ) { return $args{more}->(\@versions, $fn) }
            else {
                say "Which version?";
                say for @versions;
                return 1;
            }
        }
    
        undef;
    }
}

sub select_version($$) {
    selector(
        versions => sub {
            my ($v) = @_;
            if ( !$v ) { get_versions }
            else {
              grep { /^$v/ } get_versions
            }
        },
        one => sub {
            my ($v, $fn) = @_;
            $fn->($v, path(config('INSTALL') => "apache-tomcat-$v"));
        }
    )->(@_);
}

sub select_java($$) {
    selector(
        versions => sub {
            my ($v) = @_;
            if ( !$v ) { get_javas() }
            else {
              grep { /$v/ } get_javas();
            }
        },
        less => sub {
            say "Java versions installed:";
            say for get_javas();
        }
    )->(@_);
}

sub get_javas {
  grep { defined } map {
    my $path = $_;
    if ( -e && -d ) {
      opendir(my $dh, $_) || die "Can't read dir: $_";
      my @fs = map { path($path => $_) } grep { !/^\./ } readdir($dh);
      closedir $dh;
      @fs
    }
  } config('JAVA_PATH');
}

sub say_java_home {
    say "JAVA_HOME is set to '$ENV{JAVA_HOME}'" if $ENV{JAVA_HOME};
}

# extract zip file or gzip tarball from file to a given path 
sub extract {
    my ($f, $dir) = @_;
    make_path($dir) unless -e $dir;
    say "Extracting...";
    if ( $^O =~ /win32/i ) {
        my $zip = config('ZIP_PATH');
        if ( -e $zip ) {
            system "\"$zip\" x -y -o\"$dir\" $f";
            say "ok";
        }
        else {
            say "Can't find 7zip at '$zip'";
            return 1;
        }
    }
    else {
        chdir $dir;
        system "tar zxvf $f";
        say "ok"
    }
    return 0;
}

# Say yes for a monkey!!
sub Mojo::Collection::to_a {
    my ($self) = @_;
    @$self;
}

sub get_available {
    my $t   = HTTP::Tiny->new;
    my $url = first { $t->get(@_)->{success} } config('MIRRORS');
    if ( !$url ) { error(undef, "Couldn't reach mirrors") }
    else {
        fetch($url => sub {
            my ($dom) = @_;
            $dom->find('a')
                ->map(sub { shift->text })
                ->grep(qr/tomcat-\d/)
                ->map(sub {
                    my ($l) = @_;
                    fetch "$url/$l" => sub {
                        my ($dom) = @_;
                        $dom->find('a')
                            ->map(sub { shift->text })
                            ->grep(qr/v\d.\d.\d\d/);
                    };
                })->map(sub{ my ($x) = @_; @$x if ref $x });
        })->map(sub{ my ($x) = @_; $x =~ s/v//; $x =~ s/\///; $x })->to_a;
    }
}

sub select_available($$) {
    selector(versions => sub {
        my ($v) = @_;
        grep { /^$v/ } get_available
    })->(@_);
}

# non-destructive chomp
sub trim {
  my ($str) = @_;
  $str =~ s/\s+$//;
  $str;
}

sub registry {
  my $rfile = config('RFILE');

  if ( -e $rfile ) {
    map { split /\s-\s/ }
    map { trim($_) }
    slurp($rfile);
  }
  else {
    ();
  }
}

sub write_registry {
  my %reg = @_;
  my $rfile = config('RFILE');
  open my $fh, '>', $rfile or die "cannot write to '$rfile'";
  binmode $fh;
  foreach my $key (keys %reg) {
    say $fh "$key - $reg{$key}";
  }
  close $fh;

  0;
}

sub install {
  my ($version, $path, $f) = @_;
  my $r = extract($f => $path);
  say "Installed Tomcat version $version in $path.";
  my $dir = basename $f, qw{ .tar.gz .zip };
  return $r;
}

sub fetch_install {
    my ($path, $version, @urls) = @_;

    my $work = path(config('ROOT') => 'work');
    mkdir $work unless -e $work;

    my $t = HTTP::Tiny->new;
    for my $url (@urls) {
        say "Downloading from $url...";
        my $f = path($work => basename $url);

        if ( -e $f ) {
          return install($version, $path, $f);
        }
        else {
            my $res = $t->get($url);
            if ( $res->{success} ) {
                open my $fh, '>', $f or die "can't write to $f";
                binmode $fh;
                print $fh $res->{content};
                say "ok - downloaded to $f";
            }

            if ( -e $f ) {
                return install($version, $path, $f);
            }
        }
    }

    say "Can't find Tomcat version $version.";
    return 1;
}

sub mirrormap {
    my ($version, $pat) = @_;
    die "A pattern is required for matching remote files" unless $pat;
    
    my @v     = parse_version($version);
    my $major = $v[0];

    map {
        my $path = "$_/tomcat-$major/v$version/bin";
        if ( $^O =~ /win32/i ) { "$path/$pat.zip" }
        else                   { "$path/$pat.tar.gz" }
    } config('MIRRORS');
}

sub open_browser {
  my ($url) = @_;

  if ($ENV{BROWSER}) {
    exec $ENV{BROWSER} => $url;
  }
  elsif (is_win32()) {
    exec explorer => $url;
  }
  elsif (is_macos()) {
    exec open => $url;
  }
  else {
    die 'I don\'t know how to open a browser for you. Set "BROWSER" environment variable to your browsers executable';
  }
}

1;
