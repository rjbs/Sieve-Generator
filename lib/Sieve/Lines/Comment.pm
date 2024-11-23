use v5.36.0;
package Sieve::Lines::Comment {
  use Moo;
  with 'Sieve::Lines';

  has content => (is => 'ro', required => 1);

  sub as_sieve ($self, $i = undef) {
    $i //= 0;
    my $sieve = ref $self->content
              ? $self->content->as_sieve(0)
              : $self->content;

    my $indent = q{  } x $i;
    $sieve =~ s/^/$indent# /gm;

    return $sieve;
  }

  no Moo;
};
1;
