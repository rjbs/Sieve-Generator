use v5.36.0;

package Sieve::Generator::Sugar;

use JSON::MaybeXS ();

use Sub::Exporter -setup => [ qw(
  blank
  block
  command
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

use Sieve::Generator::Lines::Block;
use Sieve::Generator::Lines::Command;
use Sieve::Generator::Lines::Comment;
use Sieve::Generator::Lines::Document;
use Sieve::Generator::Lines::Heredoc;
use Sieve::Generator::Lines::IfElse;
use Sieve::Generator::Lines::Junction;
use Sieve::Generator::Text::Qstr;
use Sieve::Generator::Text::QstrList;
use Sieve::Generator::Text::Terms;

sub comment ($content) {
  return Sieve::Generator::Lines::Comment->new({
    content => $content,
  });
}

sub command ($identifier, @args) {
  return Sieve::Generator::Lines::Command->new({
    identifier => $identifier,
    args => \@args,
  });
}

sub ifelse ($cond, $if_true, @rest) {
  my $else = @rest % 2 ? (pop @rest) : undef;

  return Sieve::Generator::Lines::IfElse->new({
    cond  => $cond,
    true  => $if_true,
    elses => \@rest,
    ($else ? (else => $else) : ()),
  });
}

sub blank () {
  return Sieve::Generator::Lines::Document->new({ things => [] });
}

sub sieve (@things) {
  return Sieve::Generator::Lines::Document->new({ things => \@things });
}

sub block (@things) {
  return Sieve::Generator::Lines::Block->new({ things => \@things });
}

sub allof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'allof',
    things => \@things,
  });
}

sub anyof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'anyof',
    things => \@things,
  });
}

sub noneof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'noneof',
    things => \@things,
  });
}

sub terms (@terms) {
  return Sieve::Generator::Text::Terms->new({ terms => \@terms });
}

sub heredoc ($text) {
  return Sieve::Generator::Lines::Heredoc->new({ text => $text });
}

sub fourpart ($identifier, $tag, $arg1, $arg2) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ $identifier, ":$tag", qstr($arg1), qstr($arg2) ],
  });
}

sub qstr (@inputs) {
  return map {;
    ref ? Sieve::Generator::Text::QstrList->new({ strs => $_ })
        : Sieve::Generator::Text::Qstr->new({ str => $_ })
  } @inputs;
}

1;
