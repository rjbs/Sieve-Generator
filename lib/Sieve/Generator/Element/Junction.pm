use v5.36.0;
package Sieve::Generator::Element::Junction;
# ABSTRACT: a Sieve allof/anyof/noneof test

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A junction renders a Sieve multi-test expression: C<allof(...)>,
C<anyof(...)>, or C<not anyof(...)> (for C<noneof>).  Each contained test is
rendered on its own indented line.

=attr type

This attribute holds the junction type.  It must be one of C<allof>,
C<anyof>, or C<noneof>.

=cut

=attr things

This attribute holds the list of tests in the junction.  Each may be a plain
string or an object doing L<Sieve::Generator::Element>.

=cut

has type => (is => 'ro', required => 1);

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);

  my $type  = $self->type;
  my $func  = $type eq 'anyof'  ? 'anyof'
            : $type eq 'allof'  ? 'allof'
            : $type eq 'noneof' ? 'not anyof'
            : die "unknown junction type";

  my $str = "${indent}$func(\n";

  my @strs;
  for my $thing ($self->things) {
    my $substr = $thing->as_sieve($i+1);
    push @strs, $substr;
  }

  $str .= join qq{,\n}, @strs;
  $str .= "\n${indent})";

  return $str;
}

no Moo;
1;
