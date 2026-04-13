use v5.36.0;
package Sieve::Generator::Element::QstrList;
# ABSTRACT: a Sieve string list (a bracketed list of quoted strings)

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A C<QstrList> renders a list of Perl strings as a Sieve string list -- a
comma-separated sequence of quoted strings enclosed in square brackets, as
defined in RFC 5228 section 2.4.2.

=attr strs

This attribute holds the arrayref of strings to be encoded.

=cut

has strs => (is => 'ro', init_arg => 'strs', required => 1);

sub as_sieve ($self, $i = undef) {
  state $JSON = JSON::MaybeXS->new->utf8(0)->allow_nonref;

  my $str = join q{, }, map {;
    defined || Carp::confess("can't encode undef"); # XXX
    $JSON->encode("$_")
  } $self->strs->@*;

  return (q{  } x ($i // 0)) . "[ $str ]";
}

no Moo;
1;
