use v5.36.0;
package Sieve::Generator::Text::Terms;

use Moo;
with 'Sieve::Generator::Text';

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
