use v5.36.0;
package Sieve::Generator::Element::BracketComment;
# ABSTRACT: a Sieve bracket comment (/* ... */)

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A bracket comment renders as a C</* ... */> comment block as defined in
RFC 5228.

=attr content

This attribute holds the text content of the comment.

=cut

has content => (is => 'ro', required => 1);

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);
  return "${indent}/* " . $self->content . " */";
}

no Moo;
1;
