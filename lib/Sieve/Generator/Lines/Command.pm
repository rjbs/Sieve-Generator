use v5.36.0;
package Sieve::Generator::Lines::Command;

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

has identifier  => (is => 'ro', required => 1);

has _args => (is => 'ro', required => 1, init_arg => 'args');
sub args { $_[0]->_args->@* }

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);

  my $str = $indent . $self->identifier;
  my $n = 0;

  $str .= ' ' . (ref $_ ? $_->as_sieve(0) : $_) for $self->args;
  $str .= ";\n";

  return $str;
}

no Moo;
1;
