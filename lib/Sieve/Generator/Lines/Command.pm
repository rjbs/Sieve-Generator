use v5.36.0;
package Sieve::Generator::Lines::Command;
# ABSTRACT: a single Sieve command statement

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

=head1 DESCRIPTION

A command is a single semicolon-terminated Sieve statement, such as C<stop;>,
C<keep;>, or C<fileinto "Spam";>.  It consists of an identifier followed by
zero or more arguments.

=attr identifier

This attribute holds the name of the Sieve command, such as C<stop>,
C<fileinto>, or C<require>.

=cut

has identifier  => (is => 'ro', required => 1);

=attr semicolon

This attribute can be set to false during construction to suppress its trailing
semicolon.  This is useful for making tests, which are just commands without
semicolons or blocks after them.

=cut

has semicolon => (
  is => 'ro',
  default => 1,
);

=attr tagged_args

This attribute holds the list of tagged arguments to the command, given as a
hashref.  The values in the hashref will be array references of objects doing
L<Sieve::Generator::Text>, which will follow the tag name.

The accessor will return a list of pairs.

=cut

has _tagged_args => (
  is => 'ro',
  default  => sub {  {}  },
  init_arg => 'tagged_args'
);

sub tagged_args ($self) {
  my $tagged_args = $self->_tagged_args;
  return $tagged_args->%{ sort keys %$tagged_args };
}

=attr positional_args

This attribute holds the list of positional arguments to the command.  Each
argument should be an object doing L<Sieve::Generator::Text>.

=cut

has _positional_args => (
  is => 'ro',
  default => sub {  []  },
  init_arg => 'positional_args'
);

sub positional_args { $_[0]->_positional_args->@* }

sub as_sieve ($self, $i = undef) {
  my $oneline = $self->_as_sieve_oneline($i);

  if (length $oneline < 72) {
    return $oneline;
  }

  return $self->_as_sieve_multiline($i);
}

sub _as_sieve_oneline ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);

  my $str = $indent . $self->identifier;

  my @tagged_pairs = $self->tagged_args;
  while (my ($name, $values) = splice @tagged_pairs, 0, 2) {
    $str .= " :$name";
    if (@$values) {
      $str .= " " . join(q{ }, map {; $_->as_sieve(0) } @$values);
    }
  }

  $str .= ' ' . (ref $_ ? $_->as_sieve(0) : $_) for $self->positional_args;

  $str .= ";" if $self->semicolon;
  $str .= "\n";

  return $str;
}

sub _as_sieve_multiline ($self, $i = undef) {
  my $indent  = q{  } x ($i // 0);
  my $indent2 = q{ } x (1 + length $self->identifier);

  my $str = $indent . $self->identifier;
  my $n = 0;

  my @pair_queue = $self->tagged_args;
  for my $i (grep {; $_ % 2 == 0 } keys @pair_queue) {
    $pair_queue[$i] = ":$pair_queue[$i]";
  }

  push @pair_queue, map {; $_->as_sieve(0), [] } $self->positional_args;

  while (my ($name, $values) = splice @pair_queue, 0, 2) {
    $str .= $n++ ? "$indent$indent2" : q{ };
    $str .= "$name";

    if (@$values) {
      $str .= " " . join(q{ }, map {; ref ? $_->as_sieve(0) : $_ } @$values);
    }

    $str .= ";" if $self->semicolon && !@pair_queue;
    $str .= "\n";
  }

  return $str;
}

no Moo;
1;
