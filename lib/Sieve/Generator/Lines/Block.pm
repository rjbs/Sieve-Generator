use v5.36.0;
package Sieve::Generator::Lines::Block;
# ABSTRACT: a Sieve block (a brace-delimited sequence of statements)

use Moo;
with 'Sieve::Generator::Lines';

=head1 DESCRIPTION

A block is the brace-delimited body of a Sieve C<if>, C<elsif>, or C<else>
clause.  It contains an ordered list of things -- commands, nested
conditionals, comments, or plain strings -- each rendered on its own indented
line.

=attr things

This attribute holds the list of things that make up the block body.  Each
may be an object doing either L<Sieve::Generator::Lines> or
L<Sieve::Generator::Text>.

=cut

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }

sub as_sieve ($self, $i = 0) {
  my $class = ref $self;

  my $str = q{};
  my $indent = q{  } x $i;
  for my $thing ($self->things) {
    my $text = ref $thing ? $thing->as_sieve($i+1)
             :              "$indent  $thing";

    $text .= "\n" unless $text =~ /\n\z/;

    $str .= $text;
  }

  return "{\n$str$indent}\n";
}

1;
