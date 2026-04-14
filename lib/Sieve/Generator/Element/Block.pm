use v5.36.0;
package Sieve::Generator::Element::Block;
# ABSTRACT: a Sieve block (a brace-delimited sequence of statements)

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A block is the brace-delimited body of a Sieve C<if>, C<elsif>, or C<else>
clause.  It contains an ordered list of things -- commands, nested
conditionals, or comments -- each rendered on its own indented line.

=attr things

This attribute holds the list of things that make up the block body.  Each
may be an object doing L<Sieve::Generator::Element>.

=cut

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }

sub as_sieve ($self, $i = 0) {
  my $class = ref $self;

  my $str = q{};
  my $indent = q{  } x $i;
  for my $thing ($self->things) {
    my $text = $thing->as_sieve($i+1);

    $str .= "$text\n";
  }

  return "{\n$str$indent}";
}

1;
