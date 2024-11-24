use v5.36.0;
package Sieve::Generator::Lines::PrettyCommand;

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

has identifier  => (is => 'ro', required => 1);

has _arg_groups => (is => 'ro', required => 1, init_arg => 'arg_groups');
sub arg_groups { $_[0]->_arg_groups->@* }

sub args ($self) {
  return map {; _ARRAY0($_) ? @$_ : $_ } $self->arg_groups;
}

sub as_sieve ($self, $i = undef) {
  my $indent  = q{  } x ($i // 0);
  my $indent2 = q{ } x (1 + length $self->identifier);

  my $str = $indent . $self->identifier;
  my $n = 0;

  my @queue = $self->arg_groups;
  while (@queue) {
    my @next = shift @queue;
    @next = $next[0]->@* if _ARRAY0($next[0]);

    my $hunk = join q{ }, map {; ref ? $_->as_sieve(0) : $_ } @next;
    $hunk .= ";" unless @queue;
    $hunk .= "\n";

    $str .= $n++ ? "$indent$indent2$hunk" : " $hunk";
  }

  return $str;
}

no Moo;
1;
