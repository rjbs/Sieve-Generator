use v5.36.0;

package Sieve::Generator::Sugar;
# ABSTRACT: constructor functions for building Sieve generator objects

use JSON::MaybeXS ();
use Params::Util qw(_ARRAY0 _HASH0 _SCALAR0);

use experimental 'builtin', 'for_list';
use builtin 'blessed';

use Sub::Exporter -setup => [ qw(
  blank
  block
  command
  test
  comment
  set
  sieve
  heredoc
  ifelse

  allof
  anyof
  noneof

  bool
  hasflag
  negate
  qstr
  terms
  var_eq
  var_ne
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

=head1 SYNOPSIS

  use Sieve::Generator::Sugar '-all';

  my $script = sieve(
    command('require', [ qw(fileinto imap4flags) ]),
    blank(),
    ifelse(
      header_exists('X-Spam'),
      block(
        command('addflag', '$Junk'),
        command('fileinto', 'Spam'),
      ),
    ),
  );

  print $script->as_sieve;

=head1 DESCRIPTION

This module exports constructor functions for building
L<Sieve::Generator> object trees.  All functions can be imported at once
with the C<-all> tag.

Because many of the function names (C<block>, C<size>, C<terms>, and so on)
are common words that may clash with existing code, L<Sub::Exporter> allows
all imported symbols to be given a prefix:

  use Sieve::Generator::Sugar -all => { -prefix => 'sv_' };

With that import, each function is available under its prefixed name, e.g.
C<sv_sieve>, C<sv_ifelse>, C<sv_block>, and so on.

=func comment

  my $comment = comment($text);
  my $comment = comment($text, { hashes => 2 });

This function creates a L<Sieve::Generator::Lines::Comment> with the given
content.  The content may be a plain string or an object doing
L<Sieve::Generator::Text>.  The optional second argument is a hashref; its
C<hashes> key controls how many C<#> characters prefix each line, defaulting
to one.

=cut

sub comment ($content, $arg = undef) {
  return Sieve::Generator::Lines::Comment->new({
    ($arg ? %$arg : ()),
    content => $content,
  });
}

=func command

  my $cmd = command($identifier, (\%tagged?), @args);

This function creates a L<Sieve::Generator::Lines::Command> with the given
identifier and arguments.  Arguments may be plain strings or objects doing
L<Sieve::Generator::Text>.  The command renders as a semicolon-terminated
Sieve statement.

=cut

my sub _command ($identifier, $meta_arg, @args) {
  my $tagged_args;

  if (@args && _HASH0($args[0]) && !blessed($args[0])) {
    my $tagged_input = shift @args;

    for my ($k, $v) (%$tagged_input) {
      # The underlying data structure is designed so we can represent this:
      #
      #   :arg v1 v2 v3
      #
      # ...but there's currently
      $tagged_args->{$k} = !defined $v  ? []
                         : blessed($v)  ? [ $v ]
                         : !ref $v      ? [ Sieve::Generator::Text::Qstr->new({ str => $v }) ]
                         : _ARRAY0($v)  ? [ Sieve::Generator::Text::QstrList->new({ strs => $v }) ]
                         : _SCALAR0($v) ? [ Sieve::Generator::Text::Terms->new({ terms => [$$v] }) ]
                         : Carp::confess("unknown reference type $v passed in Sieve command sugar's tagged args");
    }
  }

  my @autoquoted_args = map {;
                           blessed($_)  ? $_
                         : !ref $_      ? Sieve::Generator::Text::Qstr->new({ str => $_ })
                         : _ARRAY0($_)  ? Sieve::Generator::Text::QstrList->new({ strs => $_ })
                         : _SCALAR0($_) ? Sieve::Generator::Text::Terms->new({ terms => [$$_] })
                         : Carp::confess("unknown reference type $_ passed in Sieve command sugar's positional args");
                        } @args;

  return Sieve::Generator::Lines::Command->new({
    %$meta_arg,

    identifier  => $identifier,
    tagged_args => $tagged_args // {},
    positional_args => \@autoquoted_args,
  });
}

sub command ($identifier, @args) {
  _command($identifier, {}, @args);
}

=func test

  my $test = test($identifier, (\%tagged?), @args);

This function creates a L<Sieve::Generator::Lines::Command> with the given
identifier and arguments -- and semicolon-at-the-end turned off.  In the
future, this might produce a distinct object, but for now, and really in Sieve,
commands and tests are I<nearly> the same thing.

=cut

sub test ($identifier, @args) {
  _command($identifier, { autowrap => 0, semicolon => 0 }, @args);
}

=func set

  my $cmd = set($variable, $value);

This function creates a L<Sieve::Generator::Lines::Command> for the Sieve
C<set> command (RFC 5229).  Both C<$variable> and C<$value> are automatically
quoted as Sieve strings.

=cut

sub set ($var, $val) {
  return Sieve::Generator::Lines::Command->new({
    identifier => 'set',
    positional_args => [
      Sieve::Generator::Text::Qstr->new({ str => $var }),
      Sieve::Generator::Text::Qstr->new({ str => $val }),
    ],
  });
}

=func ifelse

  my $if = ifelse($condition, $block);
  my $if = ifelse($cond, $if_block, [ $condN, $elsif_blockN ] ..., $else_block);

This function creates a L<Sieve::Generator::Lines::IfElse>.  The first two
arguments are the condition and the block to execute when it is true.
Additional condition/block pairs render as C<elsif> clauses.  If the total
number of trailing arguments is odd, the final argument is used as the plain
C<else> block.

=cut

sub ifelse ($cond, $if_true, @rest) {
  my $else = @rest % 2 ? (pop @rest) : undef;

  return Sieve::Generator::Lines::IfElse->new({
    cond   => $cond,
    true   => $if_true,
    elsifs => \@rest,
    ($else ? (else => $else) : ()),
  });
}

=func blank

  my $blank = blank();

This function creates an empty L<Sieve::Generator::Lines::Document>.  It is
typically used to insert a blank line between sections of a Sieve script.

=cut

sub blank () {
  return Sieve::Generator::Lines::Document->new({ things => [] });
}

=func sieve

  my $doc = sieve(@things);

This function creates a L<Sieve::Generator::Lines::Document> from the given
C<@things>.  The document is the top-level container for a Sieve script; its
C<as_sieve> method renders the full script as a string.

=cut

sub sieve (@things) {
  return Sieve::Generator::Lines::Document->new({ things => \@things });
}

=func block

  my $block = block(@things);

This function creates a L<Sieve::Generator::Lines::Block> containing the
given C<@things>.  A block renders as a brace-delimited, indented sequence of
statements, as used in Sieve C<if>/C<elsif>/C<else> constructs.

=cut

sub block (@things) {
  return Sieve::Generator::Lines::Block->new({ things => \@things });
}

=func allof

  my $test = allof(@tests);

This function creates a L<Sieve::Generator::Lines::Junction> that renders as
a Sieve C<allof(...)> test, which is true only when all of the given tests
are true.

=cut

sub allof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'allof',
    things => \@things,
  });
}

=func anyof

  my $test = anyof(@tests);

This function creates a L<Sieve::Generator::Lines::Junction> that renders as
a Sieve C<anyof(...)> test, which is true when any of the given tests is
true.

=cut

sub anyof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'anyof',
    things => \@things,
  });
}

=func noneof

  my $test = noneof(@tests);

This function creates a L<Sieve::Generator::Lines::Junction> that renders as
a Sieve C<not anyof(...)> test, which is true only when none of the given
tests are true.

=cut

sub noneof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'noneof',
    things => \@things,
  });
}

=func terms

  my $terms = terms(@terms);

This function creates a L<Sieve::Generator::Text::Terms> from the given
C<@terms>.  Each term may be a plain string or an object doing
L<Sieve::Generator::Text>; all terms are joined with single spaces when
rendered.  This is the general-purpose constructor for Sieve test expressions
and argument sequences.

=cut

sub terms (@terms) {
  return Sieve::Generator::Text::Terms->new({ terms => \@terms });
}

=func heredoc

  my $hd = heredoc($text);

This function creates a L<Sieve::Generator::Lines::Heredoc> containing the
given C<$text>.  The text renders using the Sieve C<text:>/C<.> multiline
string syntax.  Any line beginning with C<.> is automatically escaped to
C<..>.

=cut

sub heredoc ($text) {
  return Sieve::Generator::Lines::Heredoc->new({ text => $text });
}

=func qstr

  my $q    = qstr($string);
  my @qs   = qstr(@strings);
  my $list = qstr(\@strings);

This function creates Sieve string objects.  A plain scalar produces a
L<Sieve::Generator::Text::Qstr> that renders as a quoted Sieve string.  An
array reference produces a L<Sieve::Generator::Text::QstrList> that renders
as a bracketed Sieve string list.  When given a list of arguments, it maps
over each and returns a corresponding list of objects.

=cut

sub qstr (@inputs) {
  return map {;
    ref ? Sieve::Generator::Text::QstrList->new({ strs => $_ })
        : Sieve::Generator::Text::Qstr->new({ str => $_ })
  } @inputs;
}

=func hasflag

  my $test = hasflag($flag);

This function creates an RFC 5232 C<hasflag> test that is true if the message
has the given flag set.  The C<$flag> is automatically quoted as a Sieve
string.

=cut

sub hasflag ($flag) {
  return Sieve::Generator::Lines::Command->new({
    autowrap  => 0,
    semicolon => 0,

    identifier      => 'hasflag',
    positional_args => [ Sieve::Generator::Text::Qstr->new({ str => $flag }) ],
  });
}

=func negate

  my $test = negate($inner_test);

This function wraps C<$inner_test> in a Sieve C<not> test, producing output
like C<not foo :is "bar">.

=cut

sub negate ($test) {
  return Sieve::Generator::Lines::Command->new({
    autowrap  => 0,
    semicolon => 0,

    identifier      => 'not',
    positional_args => [ $test ],
  });
}

=func bool

  my $test = bool($value);

This function returns a Terms representing a literal C<true> or C<false>
depending on the truthiness of C<$value>.

=cut

sub bool ($value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ $value ? 'true' : 'false' ],
  });
}

=func var_eq

  my $test = var_eq($var, $value);

This produces a string "is" test checking that the given variable name equals
the given value, by producing something like C<string :is "${$var}" "$value">.

=cut

sub var_eq ($var, $value) {
  return Sieve::Generator::Lines::Command->new({
    autowrap  => 0,
    semicolon => 0,

    identifier  => 'string',
    tagged_args => { is => [] },
    positional_args => [
      Sieve::Generator::Text::Qstr->new({ str => "\${$var}" }),
      qstr($value),
    ],
  });
}

=func var_ne

  my $test = var_ne($var, $value);

This produces an inverted string "is" test checking that the given variable
name equals the given value, by producing something like C<not string :is
"${$var}" "$value">.

=cut

sub var_ne ($var, $value) {
  return Sieve::Generator::Lines::Command->new({
    autowrap  => 0,
    semicolon => 0,

    identifier  => 'not string',
    tagged_args => { is => [] },
    positional_args => [
      Sieve::Generator::Text::Qstr->new({ str => "\${$var}" }),
      qstr($value),
    ],
  });
}

1;
