use v5.36.0;
package Sieve::Generator::Element::Comment;
# ABSTRACT: a Sieve comment line

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A comment renders as one or more C<#>-prefixed lines of Sieve code.  The
number of hash characters is configurable.

=attr content

This attribute holds the content of the comment.  It may be a plain string
or an object doing L<Sieve::Generator::Element>.

=cut

has content => (is => 'ro', required => 1);

=attr hashes

This attribute controls how many C<#> characters prefix each comment line.
It defaults to C<1>.

=cut

has hashes  => (is => 'ro', default  => 1);

sub children ($self) { ref $self->content ? ($self->content) : () }

sub as_sieve ($self, $i = undef) {
  $i //= 0;

  my $sieve = ref $self->content
            ? $self->content->as_sieve(0)
            : $self->content;

  my $indent = q{  } x $i;
  my $hashes = q{#} x $self->hashes;
  $sieve =~ s/^/$indent$hashes /gm;

  return $sieve;
}

no Moo;
1;
