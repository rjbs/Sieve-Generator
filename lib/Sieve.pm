use v5.20.0;
use warnings;

package Sieve;

use experimental qw(lexical_subs postderef signatures);

use JSON::MaybeXS ();

use Safe::Isa ();
our $_isa   = $Safe::Isa::_isa;
our $_DOES  = $Safe::Isa::_DOES;

use Params::Util qw(_ARRAY0);

my sub _ARRAY0 { goto &Params::Util::_ARRAY0 }

sub encode ($input) {
  # Sieve strings and string lists are compatible with JSON
  #  https://tools.ietf.org/html/rfc5228#section-2.4.2
  # Keep everything as a unicode string
  state $JSON ||= JSON::MaybeXS->new->utf8(0)->allow_nonref;
  Carp::confess("can't encode undef") unless defined $input;

  return $JSON->encode($input);
}

use Sub::Exporter -setup => [ qw(
  comment
  cond
  lines
  textblock
  words
) ];

sub comment ($content) {
  return Sieve::Block::Comment->new({
    content => $content,
  });
}

sub cond ($cond, $true_lines, $false_lines = undef) {
  return Sieve::Block::Cond->new({
    cond  => $cond,
    true  => $true_lines,
    false => $false_lines,
  });
}

sub lines (@lines) {
  return Sieve::Block::Lines->new({ lines => \@lines });
}

sub textblock ($text) {
  return Sieve::Block::TextBlock->new({ text => $text });
}

sub words (@words) {
  return Sieve::Block::Words->new({ words => \@words });
}

package Sieve::Block {
  use Moo::Role;
  use experimental qw(postderef signatures);

  requires 'as_sieve';
  no Moo::Role;
}

package Sieve::Block::Comment {
  use Moo;
  use experimental qw(postderef signatures);
  with 'Sieve::Block';

  has content => (is => 'ro', required => 1);

  sub as_sieve ($self, $i = undef) {
    $i //= 0;
    my $sieve  = $self->content->as_sieve(0);
    my $indent = q{  } x $i;
    $sieve =~ s/^/$indent# /gm;

    return $sieve;
  }

  no Moo;
};

package Sieve::Block::Lines {
  use Moo;
  use experimental qw(postderef signatures);
  with 'Sieve::Block';

  has _lines => (is => 'ro', init_arg => 'lines', required => 1);
  sub lines ($self) { $self->_lines->@* }

  sub as_sieve ($self, $i = 0) {
    my $class = ref $self;

    my $str = q{};
    my $indent = q{  } x $i;
    for my $line ($self->lines) {
      # TODO: This is bogus.  We should have a word/line type distinction.
      $line = $line->$_DOES('Sieve::Block') ? $line->as_sieve($i)
            : _ARRAY0($line)                ? $class->new(lines => $line)->as_sieve($i+1)
            :                                 "$indent$line";

      $line .= "\n" unless $line =~ /\n\z/;

      $str .= $line;
    }

    return $str;
  }

  no Moo;
}

package Sieve::Block::TextBlock {
  use Moo;
  use experimental qw(postderef signatures);
  with 'Sieve::Block';

  has text => (is => 'ro', required => 1);

  sub as_sieve ($self, $i = undef) {
    my $str = "text:\n" . $self->text;
    $str .= "\n" unless $str =~ /\n\z/;
    $str =~ s/^\./../mg;
    return "$str.\n";
  }

  no Moo;
}

package Sieve::Block::Words {
  use Moo;
  use experimental qw(postderef signatures);
  with 'Sieve::Block';

  has _words => (is => 'ro', init_arg => 'words', required => 1);
  sub words ($self) { $self->_words->@* }

  sub as_sieve ($self, $i = undef) {
    my $str = (q{  } x ($i // 0))
            . join q{ },
              map {; ref($_) ? $_->as_sieve : $_ }
              $self->words;

    return $str;
  }

  no Moo;
}

package Sieve::Block::Cond {
  use Moo;
  use experimental qw(postderef signatures);
  with 'Sieve::Block';

  has cond    => (is => 'ro', required => 1);
  has _true   => (is => 'ro', required => 1, init_arg => 'true');
  has _false  => (is => 'ro',                init_arg => 'false');

  sub as_sieve ($self, $i = undef) {
    $i //= 0;
    my $indent = q{  } x $i;
    my $str = $indent
            . q{if } . (ref $self->cond ? $self->cond->as_sieve(0) : $self->cond). " {\n"
                     . $self->_true->as_sieve($i + 1);

    if ($self->_false) {
      $str .= "} else {\n";
      $str .= $self->_false->as_sieve($i + 1);
    }

    $str .= "}\n";

    return $str;
  }

  no Moo;
}

1;
