package App::Tom::Utils;
use v5.10;
use strict;
use warnings;

#
# Utilities
#
BEGIN {

sub path { File::Spec->join(@_) }

sub error {
    my ($code, @msg) = @_;

    say STDERR @msg if @msg;
    
    if ( $code && ref $code eq 'CODE' ) {
        $code->(@msg);
    }

    exit 1;
}

sub commands {
    my %cmds = @_;
    my $cmd  = shift @ARGV;

    if ( $cmd && $cmds{$cmd} ) { $cmds{$cmd}->() }
    else {
        $cmd = '' unless defined $cmd;
        if ( $cmd ) {
            error(\&help => "'$cmd' is an invalid command");
        }
        else {
            error(\&help);
        }
    }
}

sub parse_version {
    split /\./ => $_[0];
}

sub get_versions {
    my @versions = map { /(\d\.\d(?:\.\d\d)?)/g; $1 }
    glob "$INSTALL/apache-tomcat-*";
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
            grep { /^$v/ } get_versions
        },
        one => sub {
            my ($v, $fn) = @_;
            $fn->($v, path($INSTALL => "apache-tomcat-$v"));
        }
    )->(@_);
}

sub select_java($$) {
    selector(
        versions => sub {
            my ($v) = @_;
            grep { /$v/ } glob("$JAVA_BASE/jdk*");
        },
        less => sub {
            say "Java versions installed:";
            my $j = $ENV{JAVA_HOME}; $j =~ s/\\/\//g;
            for (glob "$JAVA_BASE/jdk*") {
                print;
                print " - JAVA_HOME" if /$j/;
                say '';
            }
        }
    )->(@_);
}

sub say_java_home {
    say "JAVA_HOME is set to '$ENV{JAVA_HOME}'";
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "can't read $file";
    local $/='';
    <$fh>;
}

# write content to file
sub write_to {
    my ($file, $content) = @_;
    open my $fh, '>', $file or die "can't write to $file";
    print $fh $content;
    $content;
}

# extract zip file or gzip tarball from file to a given path 
sub extract {
    my ($f, $dir) = @_;
    say "'$dir'";
    make_path($dir) unless -e $dir;
    say "Extracting...";
    if ( $^O =~ /win32/i ) {
        if ( -e $ZIP_PATH ) {
            system "\"$ZIP_PATH\" x -y -o\"$dir\" $f";
            say "ok";
        }
        else {
            say "Can't find 7zip at '$ZIP_PATH'";
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

# plural inflection
sub plural {
    my ($n, $str) = @_;
    if ( $n == 1 ) { "$n $str" }
    else {
        if ( $str =~ /[sz]$/i ) { "$n ${str}es" }
        else                    { "$n ${str}s"  }
    }
}

# fetch content from a url, cache HTTP::Tiny object
{
    my $t;
    sub fetch($$) {
        my ($url, $fn) = @_;
        $t //= HTTP::Tiny->new;
        my $res = HTTP::Tiny->new->get($url);
        if ( !$res->{success} ) { return 1 }
        else {
            $fn->(Mojo::DOM->new($res->{content}), $res);
        }
    }
}

# match the first
sub first(&@) {
    my ($fn, @list) = @_;
    for my $x (@list) {
        return $x if !!$fn->($x);
    }
    return undef;
}

# Say yes for a monkey!!
sub Mojo::Collection::to_a {
    my ($self) = @_;
    @$self;
}

sub get_available {
    my $t   = HTTP::Tiny->new;
    my $url = first { $t->get(@_)->{success} } @MIRRORS;
    if ( !$url ) { error(undef, "Couldn't reach mirrors") }
    else {
        fetch($url => sub {
            my ($dom) = @_;
            $dom->find('a')
                ->pluck('text')
                ->grep(qr/tomcat-\d/)
                ->map(sub {
                    my ($l) = @_;
                    fetch "$url/$l" => sub {
                        my ($dom) = @_;
                        $dom->find('a')
                            ->pluck('text')
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

sub fetch_install($$) {
    my ($version, $fn) = @_;

    my @urls = $fn->($version);

    my $work = path($ROOT => 'work');
    mkdir $work unless -e $work;

    say "Downloading...";

    my $t = HTTP::Tiny->new;
    for my $url (@urls) {
        my $f = path($work => basename $url);

        say $f;
        if ( -e $f ) {
            my $r = extract($f => $INSTALL);
            say "Installed Tomcat version $version.";
            return $r;
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
                my $r = extract($f => $INSTALL);
                say "Installed Tomcat version $version.";
                return $r;
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
    } @MIRRORS;
}

}

1;
