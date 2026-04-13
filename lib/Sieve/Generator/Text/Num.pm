use v5.36.0;
package Sieve::Generator::Text::Num;
# ABSTRACT: a Sieve numeric literal

use Moo;
with 'Sieve::Generator::Text';

use Carp ();

=head1 DESCRIPTION

A C<Num> renders a non-negative integer, optionally followed by a size suffix
(C<K>, C<M>, or C<G>), as a Sieve number literal per RFC 5228 section 2.4.1.

=attr value

This attribute holds the non-negative integer value.

=cut

has value => (
  is  => 'ro',
  isa => sub {
    Carp::croak("value must be a non-negative integer")
      unless defined $_[0] && $_[0] =~ /\A[0-9]+\z/;
  },
  required => 1,
);

=attr suffix

This attribute holds an optional size suffix: C<K>, C<M>, or C<G> (case
insensitive on input, always rendered uppercase).  If not provided, no suffix
is appended.

=cut

has suffix => (
  is  => 'ro',
  isa => sub {
    return unless defined $_[0];
    Carp::croak("suffix must be K, M, or G")
      unless $_[0] =~ /\A[KMGkmg]\z/;
  },
  coerce => sub { defined $_[0] ? uc $_[0] : $_[0] },
);

sub as_sieve ($self, $i = undef) {
  return (q{  } x ($i // 0)) . $self->value . ($self->suffix // '');
}

no Moo;
1;
