use v5.36.0;

package Sieve;

use JSON::MaybeXS ();

use Sub::Exporter -setup => [ qw(
  blank
  block
  comment
  sieve
  heredoc
  ifelse

  allof
  anyof
  noneof

  fourpart
  qstr
  terms
) ];

use Sieve::Lines::Block;
use Sieve::Lines::Comment;
use Sieve::Lines::Document;
use Sieve::Lines::Heredoc;
use Sieve::Lines::IfElse;
use Sieve::Lines::Junction;
use Sieve::Text::Qstr;
use Sieve::Text::QstrList;
use Sieve::Text::Terms;

sub comment ($content) {
  return Sieve::Lines::Comment->new({
    content => $content,
  });
}

sub fourpart ($identifier, $tag, $arg1, $arg2) {
  return Sieve::Text::Terms->new({
    terms => [
      $identifier,
      ":$tag",
      qstr($arg1),
      qstr($arg2),
    ],
  });
}

sub ifelse ($cond, $if_true, @rest) {
  my $else = @rest % 2 ? (pop @rest) : undef;

  return Sieve::Lines::IfElse->new({
    cond  => $cond,
    true  => $if_true,
    elses => \@rest,
    ($else ? (else => $else) : ()),
  });
}

sub blank () {
  return Sieve::Lines::Document->new({ things => [] });
}

sub sieve (@things) {
  return Sieve::Lines::Document->new({ things => \@things });
}

sub block (@things) {
  return Sieve::Lines::Block->new({ things => \@things });
}

sub allof (@things) {
  return Sieve::Lines::Junction->new({
    type => 'allof',
    things => \@things,
  });
}

sub anyof (@things) {
  return Sieve::Lines::Junction->new({
    type => 'anyof',
    things => \@things,
  });
}

sub noneof (@things) {
  return Sieve::Lines::Junction->new({
    type => 'noneof',
    things => \@things,
  });
}

sub terms (@terms) {
  return Sieve::Text::Terms->new({ terms => \@terms });
}

sub heredoc ($text) {
  return Sieve::Lines::Heredoc->new({ text => $text });
}

sub qstr (@inputs) {
  return map {;
    ref ? Sieve::Text::QstrList->new({ strs => $_ })
        : Sieve::Text::Qstr->new({ str => $_ })
  } @inputs;
}

1;
