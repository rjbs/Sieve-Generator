use v5.36.0;
package Sieve::Generator::Lines::Comment;

use Moo;
with 'Sieve::Generator::Lines';

has content => (is => 'ro', required => 1);
has hashes  => (is => 'ro', default  => 1);

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
