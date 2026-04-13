use v5.36.0;
package Sieve::Generator::Element::Document;
# ABSTRACT: a sequence of Sieve lines forming a complete script or blank line

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A document is an ordered sequence of things, and renders as a flat sequence of
Sieve lines.  It serves as the top-level container for a complete Sieve script
(when constructed by L<Sieve::Generator::Sugar/sieve>) or as an empty separator
line (when constructed by L<Sieve::Generator::Sugar/blank>).

=attr things

This attribute holds the list of things that make up the document.  Each may
be a string or an object doing L<Sieve::Generator::Element>.

=cut

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }

=method append

  $doc->append(@things);

This method adds the given C<@things> to the end of the document's list.

=cut

sub append ($self, @things) {
  push $self->_things->@*, @things;
  return;
}

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
1;
