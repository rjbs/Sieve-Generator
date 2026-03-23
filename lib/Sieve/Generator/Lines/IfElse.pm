use v5.36.0;
package Sieve::Generator::Lines::IfElse;

use Moo;
with 'Sieve::Generator::Lines';

has cond    => (is => 'ro', required => 1);
has true    => (is => 'ro', required => 1, init_arg => 'true');
has elses   => (is => 'ro');
has else    => (is => 'ro');

sub as_sieve ($self, $i = undef) {
  $i //= 0;
  my $indent = q{  } x $i;

  my $str = q{};

  my $in_else;

  use experimental qw(for_list);
  for my ($cond, $block) ($self->cond, $self->true, ($self->elses ? $self->elses->@* : ())) {
    my $cond_str = ref $cond ? $cond->as_sieve(0) : $cond;
    chomp $cond_str;

    if ($in_else) {
      chomp $str;
      $str .= " elsif $cond_str " . $block->as_sieve($i);
    } else {
      $str .= $indent . "if $cond_str " . $block->as_sieve($i);
    }
    $in_else = 1;
  }

  if ($self->else) {
    chomp $str;
    $str .= " else " . $self->else->as_sieve($i);
  }

  return $str;
}

no Moo;
1;
