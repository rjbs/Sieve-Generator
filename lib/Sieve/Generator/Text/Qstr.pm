use v5.36.0;
package Sieve::Generator::Text::Qstr;

use Moo;
with 'Sieve::Generator::Text';

has str => (is => 'ro', init_arg => 'str', required => 1);

sub as_sieve ($self, $i = undef) {
  # Sieve strings and string lists are compatible with JSON
  #  https://tools.ietf.org/html/rfc5228#section-2.4.2
  # Keep everything as a unicode string
  state $JSON = JSON::MaybeXS->new->utf8(0)->allow_nonref;
  Carp::confess("can't encode undef") unless defined $self->str; # XXX

  return (q{  } x ($i // 0)) . $JSON->encode($self->str);
}

no Moo;
1;
