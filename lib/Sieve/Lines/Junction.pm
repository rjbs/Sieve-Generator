use v5.36.0;
package Sieve::Lines::Junction {
  use Moo;
  with 'Sieve::Lines';

  # anyof, allof, noneof
  has type => (is => 'ro', required => 1);

  has _things => (is => 'ro', init_arg => 'things', required => 1);
  sub things ($self) { $self->_things->@* }

  sub as_sieve ($self, $i = undef) {
    my $indent = q{  } x ($i // 0);

    my $type  = $self->type;
    my $func  = $type eq 'anyof'  ? 'anyof'
              : $type eq 'allof'  ? 'allof'
              : $type eq 'noneof' ? 'not anyof'
              : die "unknown junction type";

    my $str = "${indent}$func(\n";

    my @strs;
    for my $thing ($self->things) {
      my $substr = ref $thing ? $thing->as_sieve($i+1) : $thing;
      chomp $substr;
      push @strs, $substr;
    }

    $str .= join qq{,\n}, @strs;
    $str .= "\n${indent})\n";

    return $str;
  }

  no Moo;
}
1;
