use v5.36.0;
package Sieve::Generator::Text::Terms;
# ABSTRACT: a sequence of Sieve terms joined by spaces

use Moo;
with 'Sieve::Generator::Text';

=head1 DESCRIPTION

A C<Terms> object renders a sequence of terms as a space-joined inline Sieve
expression.  It is the general-purpose building block for Sieve test
expressions and argument sequences.

=attr terms

This attribute holds the arrayref of terms.  Each term may be a plain string or
an object doing L<Sieve::Generator::Text>; all terms are joined with single
spaces when rendered.

=cut

has terms => (is => 'ro', required => 1);

sub as_sieve ($self, $i = undef) {
  my $str = (q{  } x ($i // 0))
          . join q{ },
            map {; ref($_) ? $_->as_sieve : $_ }
            $self->terms->@*;

  return $str;
}

no Moo;
1;
