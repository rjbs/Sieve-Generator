use v5.36.0;
package Sieve::Lines::Document {
  use Moo;
  with 'Sieve::Lines';

  has _things => (is => 'ro', init_arg => 'things', required => 1);
  sub things ($self) { $self->_things->@* }

  sub as_sieve ($self, $i = 0) {
    my $class = ref $self;

    my $str = q{};
    my $indent = q{  } x $i;
    for my $thing ($self->things) {
      my $text = ref $thing ? $thing->as_sieve($i)
               :              "$indent$thing";

      $text .= "\n" unless $text =~ /\n\z/;

      $str .= $text;
    }

    return $str;
  }

  no Moo;
}
1;
