use v5.36.0;
package Sieve::Text::QstrList {
  use Moo;
  with 'Sieve::Text';

  has strs => (is => 'ro', init_arg => 'strs', required => 1);

  sub as_sieve ($self, $i = undef) {
    state $JSON = JSON::MaybeXS->new->utf8(0)->allow_nonref;

    my $str = join q{, }, map {;
      defined || Carp::confess("can't encode undef"); # XXX
      $JSON->encode($_)
    } $self->strs->@*;

    return (q{  } x ($i // 0)) . "[ $str ]";
  }

  no Moo;
}
1;
