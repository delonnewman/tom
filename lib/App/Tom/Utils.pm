package App::Tom::Utils;
use v5.10;
use strict;
use warnings;

use Exporter qw{ import };
our @EXPORT_OK = qw{
  path
  error
  is_win32
  is_linux
  slurp
  spit
  write_to
  read_from
  plural
  fetch
  first
  chomped
};

use Data::Dump qw{ dump };

use English;

use File::Basename;
use File::Copy;
use File::Path qw{ remove_tree make_path };
use File::Spec;

use HTTP::Tiny;

sub path { File::Spec->join(@_) }

sub error {
    my ($code, @msg) = @_;

    say STDERR @msg if @msg;
    
    if ( $code && ref $code eq 'CODE' ) {
        $code->(@msg);
    }

    exit 1;
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "can't read $file";
    local $/='';
    <$fh>;
}

# alias for slurp
{
  no strict;
  *{read_from} = \&slurp;
}

sub chomped {
  my ($in) = @_;
  local $_ = $in;
  s/\n$//;
  $_;
}

# write content to file
sub spit {
    my ($file, $content) = @_;
    open my $fh, '>', $file or die "can't write to $file";
    print $fh $content;
    $content;
}

# alias for spit
{
  no strict;
  *{write_to} = \&spit;
}

# plural inflection
sub plural {
  my ($n, $str) = @_;
  if ( $n == 1 ) { "$n $str" }
  else {
    if ( $str =~ /(s|z|x|sh|ch)$/i ) { "$n ${str}es" }
    else                             { "$n ${str}s"  }
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

1;
