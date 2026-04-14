use v5.36.0;
package Sieve::Generator::Element::Command;
# ABSTRACT: a single Sieve command statement

use Moo;
with 'Sieve::Generator::Element';

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

=attr autowrap

This attribute can be set false during construction to suppress automatic
multiline formatting if this command runs lone.

=cut

has autowrap => (
  is => 'ro',
  default => 1,
);

=attr block

This attribute holds an optional L<Sieve::Generator::Element::Block> to render
after the arguments instead of a semicolon.  This models the Sieve grammar rule
C<command = identifier arguments ( ";" / block )> for commands like
C<foreverypart> that take a block body.  When set, the C<semicolon> attribute
is ignored.

=cut

has block => (is => 'ro');

=attr tagged_args

This attribute holds the list of tagged arguments to the command, given as a
hashref.  The values in the hashref will be array references of objects doing
L<Sieve::Generator::Element>, which will follow the tag name.

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
argument should be an object doing L<Sieve::Generator::Element>.

=cut

has _positional_args => (
  is => 'ro',
  default => sub {  []  },
  init_arg => 'positional_args'
);

sub positional_args { $_[0]->_positional_args->@* }

sub children ($self) {
  my @children;

  my @tagged_pairs = $self->tagged_args;
  while (my ($name, $values) = splice @tagged_pairs, 0, 2) {
    push @children, @$values;
  }

  push @children, $self->positional_args;
  push @children, $self->block if $self->block;

  return @children;
}

sub as_sieve ($self, $i = undef) {
  my $oneline = $self->_as_sieve_oneline($i);

  if (!$self->autowrap || length $oneline < 72) {
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
    for my $v (@$values) {
      my $rendered = $v->as_sieve(0);
      $str .= $str =~ /\n\z/ ? $rendered : " $rendered";
    }
  }

  for my $arg ($self->positional_args) {
    my $rendered = $arg->as_sieve(0);
    $str .= $str =~ /\n\z/ ? $rendered : " $rendered";
  }

  if ($self->block) {
    my $blk = $self->block->as_sieve($i // 0);
    $str .= $str =~ /\n\z/ ? $blk : " $blk";
  } elsif ($self->semicolon) {
    $str .= ";";
  }

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
      $str .= " " . join(q{ }, map {; $_->as_sieve(0) } @$values);
    }

    if (@pair_queue) {
      $str .= "\n";
    } elsif ($self->block) {
      $str .= " " . $self->block->as_sieve($i // 0);
    } elsif ($self->semicolon) {
      $str .= ";";
    }
  }

  return $str;
}

no Moo;
1;
