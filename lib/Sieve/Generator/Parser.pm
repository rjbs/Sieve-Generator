use v5.36.0;
package Sieve::Generator::Parser;
# ABSTRACT: parse Sieve scripts into Element trees

use Carp;

use Sieve::Generator::Element::Block;
use Sieve::Generator::Element::BracketComment;
use Sieve::Generator::Element::Command;
use Sieve::Generator::Element::Comment;
use Sieve::Generator::Element::Document;
use Sieve::Generator::Element::Heredoc;
use Sieve::Generator::Element::Junction;
use Sieve::Generator::Element::Num;
use Sieve::Generator::Element::Qstr;
use Sieve::Generator::Element::QstrList;

=head1 SYNOPSIS

  use Sieve::Generator::Parser;

  my $doc = Sieve::Generator::Parser->parse($sieve_text);
  print $doc->as_sieve;

=head1 DESCRIPTION

This module parses a Sieve script (RFC 5228) into a tree of
L<Sieve::Generator::Element> objects.  The resulting tree can be inspected,
modified, and re-rendered via C<as_sieve>.

The parser is schema-unaware: it handles any syntactically valid Sieve without
knowing which commands or extensions are in use.  C<if>/C<elsif>/C<else> are
bundled into L<Sieve::Generator::Element::IfElse>, and C<allof>/C<anyof> into
L<Sieve::Generator::Element::Junction>; all other commands produce
L<Sieve::Generator::Element::Command>.

=method parse

  my $doc = Sieve::Generator::Parser->parse($sieve_text);

Parses the given Sieve script text and returns a
L<Sieve::Generator::Element::Document>.

=cut

sub parse ($class, $text) {
  my $self = bless { text => $text, peeked => undef }, $class;
  pos($self->{text}) = 0;

  my @things = $self->_parse_commands;

  my $tok = $self->_peek_token;
  Carp::croak("unexpected token $tok->[0] at end of input") if $tok;

  return Sieve::Generator::Element::Document->new({ things => \@things });
}

# -- Token peek/consume --------------------------------------------------

sub _peek_token ($self) {
  $self->{peeked} //= $self->_next_token;
  return $self->{peeked};
}

sub _consume_token ($self) {
  my $tok = $self->{peeked} // $self->_next_token;
  $self->{peeked} = undef;
  return $tok;
}

sub _expect_token ($self, $type) {
  my $tok = $self->_consume_token;
  my $got = $tok ? $tok->[0] : 'EOF';
  Carp::croak("expected $type, got $got") unless $got eq $type;
  return $tok;
}

sub _skip_comments ($self) {
  while (my $tok = $self->_peek_token) {
    last unless $tok->[0] eq 'HASH_COMMENT' || $tok->[0] eq 'BRACKET_COMMENT';
    $self->_consume_token;
  }
}

# -- Lexer ----------------------------------------------------------------

sub _next_token ($self) {
  # Skip whitespace (not comments -- those are tokens)
  $self->{text} =~ /\G[ \t\r\n]+/gc;

  return undef if (pos($self->{text}) // 0) >= length($self->{text});

  # Hash comment: one or more # followed by content to end of line
  if ($self->{text} =~ /\G(#+)[ \t]?([^\r\n]*)/gc) {
    return [ 'HASH_COMMENT', $2, length($1) ];
  }

  # Bracket comment
  if ($self->{text} =~ /\G\/\*(.*?)\*\//gcs) {
    my $content = $1;
    $content =~ s/\A\s+//;
    $content =~ s/\s+\z//;
    return [ 'BRACKET_COMMENT', $content ];
  }

  # Identifier (or text: multiline string)
  if ($self->{text} =~ /\G([a-zA-Z_][a-zA-Z0-9_]*)/gc) {
    my $id = $1;
    if ($id eq 'text' && $self->{text} =~ /\G:/gc) {
      return $self->_lex_multiline;
    }
    return [ 'IDENTIFIER', $id ];
  }

  # Tag
  if ($self->{text} =~ /\G:([a-zA-Z_][a-zA-Z0-9_]*)/gc) {
    return [ 'TAG', $1 ];
  }

  # Number (digits with optional K/M/G suffix)
  if ($self->{text} =~ /\G(\d+)([KMGkmg])?/gc) {
    return [ 'NUMBER', $1, $2 ? uc($2) : undef ];
  }

  # Quoted string
  if ($self->{text} =~ /\G"/gc) {
    return $self->_lex_quoted_string;
  }

  # Punctuation
  if ($self->{text} =~ /\G([{}(),;\[\]])/gc) {
    my %type = (
      '{' => 'LBRACE',    '}' => 'RBRACE',
      '(' => 'LPAREN',    ')' => 'RPAREN',
      '[' => 'LBRACKET',  ']' => 'RBRACKET',
      ',' => 'COMMA',     ';' => 'SEMICOLON',
    );
    return [ $type{$1} ];
  }

  my $pos  = pos($self->{text}) // 0;
  my $near = substr($self->{text}, $pos, 20);
  Carp::croak("unexpected character at position $pos near '$near'");
}

sub _lex_multiline ($self) {
  # "text:" already consumed; skip optional whitespace and hash-comment, then
  # expect a line break.
  $self->{text} =~ /\G[ \t]*(?:#[^\r\n]*)?\r?\n/gc
    or Carp::croak("expected newline after text:");

  my $body = '';
  while ($self->{text} =~ /\G([^\r\n]*)\r?\n/gc) {
    my $line = $1;
    if ($line eq '.') {
      return [ 'MULTILINE', $body ];
    }
    $line =~ s/\A\.//;  # dot-unstuffing
    $body .= "$line\n";
  }

  Carp::croak("unterminated multiline string");
}

sub _lex_quoted_string ($self) {
  # Opening " already consumed.
  my $str = '';
  while (1) {
    if ($self->{text} =~ /\G([^"\\]+)/gc) {
      $str .= $1;
    } elsif ($self->{text} =~ /\G"/gc) {
      return [ 'STRING', $str ];
    } elsif ($self->{text} =~ /\G\\(.)/gcs) {
      $str .= $1;
    } else {
      Carp::croak("unterminated quoted string");
    }
  }
}

# -- Parse methods --------------------------------------------------------

sub _parse_commands ($self) {
  my @things;

  while (my $tok = $self->_peek_token) {
    if ($tok->[0] eq 'HASH_COMMENT') {
      $self->_consume_token;
      push @things, Sieve::Generator::Element::Comment->new({
        content => $tok->[1],
        ($tok->[2] > 1 ? (hashes => $tok->[2]) : ()),
      });
    } elsif ($tok->[0] eq 'BRACKET_COMMENT') {
      $self->_consume_token;
      push @things, Sieve::Generator::Element::BracketComment->new({
        content => $tok->[1],
      });
    } elsif ($tok->[0] eq 'IDENTIFIER') {
      push @things, $self->_parse_command;
    } else {
      last;
    }
  }

  return @things;
}

sub _parse_command ($self) {
  my $tok = $self->_consume_token;
  my $id  = $tok->[1];

  Carp::croak("unexpected '$id' without preceding 'if'")
    if $id eq 'elsif' || $id eq 'else';

  return $self->_parse_if if $id eq 'if';

  my ($tagged, $positional) = $self->_parse_arguments;

  $self->_skip_comments;
  my $next = $self->_peek_token;

  if ($next && $next->[0] eq 'SEMICOLON') {
    $self->_consume_token;
    return Sieve::Generator::Element::Command->new({
      identifier      => $id,
      tagged_args     => $tagged,
      positional_args => $positional,
    });
  }

  if ($next && $next->[0] eq 'LBRACE') {
    my $block = $self->_parse_block;
    return Sieve::Generator::Element::Command->new({
      identifier      => $id,
      tagged_args     => $tagged,
      positional_args => $positional,
      block           => $block,
    });
  }

  my $got = $next ? $next->[0] : 'EOF';
  Carp::croak("expected ; or { after command '$id', got $got");
}

sub _parse_if ($self) {
  # "if" already consumed
  my $cond = $self->_parse_test;
  my $true = $self->_parse_block;

  my @elsifs;
  my $else;

  while (1) {
    $self->_skip_comments;
    my $tok = $self->_peek_token;
    last unless $tok && $tok->[0] eq 'IDENTIFIER';

    if ($tok->[1] eq 'elsif') {
      $self->_consume_token;
      my $elsif_cond  = $self->_parse_test;
      my $elsif_block = $self->_parse_block;
      push @elsifs, $elsif_cond, $elsif_block;
    } elsif ($tok->[1] eq 'else') {
      $self->_consume_token;
      $else = $self->_parse_block;
      last;
    } else {
      last;
    }
  }

  return Sieve::Generator::Element::IfElse->new({
    cond   => $cond,
    true   => $true,
    elsifs => \@elsifs,
    ($else ? (else => $else) : ()),
  });
}

sub _parse_block ($self) {
  $self->_skip_comments;
  $self->_expect_token('LBRACE');
  my @things = $self->_parse_commands;
  $self->_expect_token('RBRACE');
  return Sieve::Generator::Element::Block->new({ things => \@things });
}

sub _parse_arguments ($self) {
  my (%tagged, @positional);

  while (1) {
    $self->_skip_comments;
    my $tok = $self->_peek_token;
    last unless $tok;

    if ($tok->[0] eq 'TAG') {
      $self->_consume_token;
      my $tag_name = $tok->[1];
      my @values;

      # Greedy: associate next value-like token with this tag
      $self->_skip_comments;
      my $next = $self->_peek_token;
      if ($next && $next->[0] =~ /\A(?:STRING|NUMBER|MULTILINE)\z/) {
        push @values, $self->_parse_atom;
      } elsif ($next && $next->[0] eq 'LBRACKET') {
        push @values, $self->_parse_string_list;
      }

      $tagged{$tag_name} = \@values;
    } elsif ($tok->[0] =~ /\A(?:STRING|NUMBER|MULTILINE)\z/) {
      push @positional, $self->_parse_atom;
    } elsif ($tok->[0] eq 'LBRACKET') {
      push @positional, $self->_parse_string_list;
    } elsif ($tok->[0] eq 'IDENTIFIER') {
      # Trailing test in argument position
      push @positional, $self->_parse_test;
      last;
    } elsif ($tok->[0] eq 'LPAREN') {
      # Trailing test-list in argument position
      my @tests = $self->_parse_test_list;
      push @positional, @tests;
      last;
    } else {
      last;
    }
  }

  return (\%tagged, \@positional);
}

sub _parse_atom ($self) {
  my $tok = $self->_consume_token;

  if ($tok->[0] eq 'STRING') {
    return Sieve::Generator::Element::Qstr->new({ str => $tok->[1] });
  }

  if ($tok->[0] eq 'NUMBER') {
    return Sieve::Generator::Element::Num->new({
      value => $tok->[1],
      ($tok->[2] ? (suffix => $tok->[2]) : ()),
    });
  }

  if ($tok->[0] eq 'MULTILINE') {
    return Sieve::Generator::Element::Heredoc->new({ text => $tok->[1] });
  }

  Carp::croak("expected string, number, or multiline; got $tok->[0]");
}

sub _parse_test ($self) {
  $self->_skip_comments;
  my $tok = $self->_peek_token;
  Carp::croak("expected test, got " . ($tok ? $tok->[0] : 'EOF'))
    unless $tok && $tok->[0] eq 'IDENTIFIER';

  $self->_consume_token;
  my $id = $tok->[1];

  # not <test>
  if ($id eq 'not') {
    my $inner = $self->_parse_test;

    if ( ref $inner eq 'Sieve::Generator::Element::Junction'
      && $inner->type eq 'anyof'
    ) {
      return Sieve::Generator::Element::Junction->new({
        type   => 'noneof',
        things => [ $inner->things ],
      });
    }

    return Sieve::Generator::Element::Command->new({
      autowrap        => 0,
      semicolon       => 0,
      identifier      => 'not',
      positional_args => [ $inner ],
    });
  }

  # allof/anyof <test-list>
  if ($id eq 'allof' || $id eq 'anyof') {
    my @tests = $self->_parse_test_list;
    return Sieve::Generator::Element::Junction->new({
      type   => $id,
      things => \@tests,
    });
  }

  # Regular test
  my ($tagged, $positional) = $self->_parse_arguments;
  return Sieve::Generator::Element::Command->new({
    autowrap        => 0,
    semicolon       => 0,
    identifier      => $id,
    tagged_args     => $tagged,
    positional_args => $positional,
  });
}

sub _parse_test_list ($self) {
  $self->_skip_comments;
  $self->_expect_token('LPAREN');

  my @tests;
  push @tests, $self->_parse_test;

  while (1) {
    $self->_skip_comments;
    my $tok = $self->_peek_token;
    last unless $tok && $tok->[0] eq 'COMMA';
    $self->_consume_token;
    push @tests, $self->_parse_test;
  }

  $self->_skip_comments;
  $self->_expect_token('RPAREN');
  return @tests;
}

sub _parse_string_list ($self) {
  $self->_expect_token('LBRACKET');

  my @strs;

  $self->_skip_comments;
  my $tok = $self->_consume_token;
  Carp::croak("expected string in string list, got $tok->[0]")
    unless $tok->[0] eq 'STRING' || $tok->[0] eq 'MULTILINE';
  push @strs, $tok->[1];

  while (1) {
    $self->_skip_comments;
    my $next = $self->_peek_token;
    last unless $next && $next->[0] eq 'COMMA';
    $self->_consume_token;
    $self->_skip_comments;
    $tok = $self->_consume_token;
    Carp::croak("expected string in string list, got $tok->[0]")
      unless $tok->[0] eq 'STRING' || $tok->[0] eq 'MULTILINE';
    push @strs, $tok->[1];
  }

  $self->_skip_comments;
  $self->_expect_token('RBRACKET');
  return Sieve::Generator::Element::QstrList->new({ strs => \@strs });
}

1;
