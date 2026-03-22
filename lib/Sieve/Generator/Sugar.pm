use v5.36.0;

package Sieve::Generator::Sugar;

use JSON::MaybeXS ();

use Sub::Exporter -setup => [ qw(
  blank
  block
  command
  comment
  set
  sieve
  heredoc
  ifelse

  allof
  anyof
  noneof

  bool
  fourpart
  hasflag
  header_exists
  not_header_exists
  not_string_test
  qstr
  size
  string_test
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

sub comment ($content, $arg = undef) {
  return Sieve::Generator::Lines::Comment->new({
    ($arg ? %$arg : ()),
    content => $content,
  });
}

sub command ($identifier, @args) {
  return Sieve::Generator::Lines::Command->new({
    identifier => $identifier,
    args => \@args,
  });
}

sub set ($var, $val) {
  return Sieve::Generator::Lines::Command->new({
    identifier => 'set',
    args => [
      Sieve::Generator::Text::Qstr->new({ str => $var }),
      Sieve::Generator::Text::Qstr->new({ str => $val }),
    ],
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
    terms => [
      $identifier,
      ":$tag",
      (ref $arg1 ? Sieve::Generator::Text::QstrList->new({ strs => $arg1 })
                 : Sieve::Generator::Text::Qstr->new({ str => $arg1 })),
      (ref $arg2 ? Sieve::Generator::Text::QstrList->new({ strs => $arg2 })
                 : Sieve::Generator::Text::Qstr->new({ str => $arg2 })),
    ],
  });
}

sub qstr (@inputs) {
  return map {;
    ref ? Sieve::Generator::Text::QstrList->new({ strs => $_ })
        : Sieve::Generator::Text::Qstr->new({ str => $_ })
  } @inputs;
}

sub header_exists ($header) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ 'exists', Sieve::Generator::Text::Qstr->new({ str => $header }) ],
  });
}

sub not_header_exists ($header) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ 'not exists', Sieve::Generator::Text::Qstr->new({ str => $header }) ],
  });
}

sub hasflag ($flag) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ 'hasflag', Sieve::Generator::Text::Qstr->new({ str => $flag }) ],
  });
}

sub string_test ($comparator, $key, $value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ "string :$comparator", $key, $value ],
  });
}

sub not_string_test ($comparator, $key, $value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ "not string :$comparator", $key, $value ],
  });
}

sub size ($comparator, $value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ "size :$comparator", $value ],
  });
}

sub bool ($value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ $value ? 'true' : 'false' ],
  });
}

1;
