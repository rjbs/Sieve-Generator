use v5.36.0;
package Sieve::Generator::Element;
# ABSTRACT: role for objects that render as Sieve code

use Moo::Role;

=head1 DESCRIPTION

This role is consumed by all objects that can render themselves as Sieve code.
It requires a single method, C<as_sieve>.

=method as_sieve

  my $sieve_text = $element->as_sieve;
  my $sieve_text = $element->as_sieve($indent_level);

This method renders the object as a string of Sieve code.  The optional
C<$indent_level> argument is a non-negative integer controlling the
indentation depth; each level adds two spaces.  If not given, no indenting is
added.

=method children

  my @children = $element->children;

Returns all child Elements of this node.  Leaf nodes return an empty list.
Container nodes return their direct children.  This is used by
C<find_elements> to walk the tree.

=cut

sub children ($self) { () }

=method find_elements

  my @found = $element->find_elements(\&predicate);

Walks the element tree depth-first, returning all elements (including
C<$element> itself) for which the predicate returns true.  Descends into
matching nodes, so all matches at any depth are returned.

=cut

sub find_elements ($self, $code) {
  my @found;
  push @found, $self if $code->($self);
  push @found, $_->find_elements($code) for $self->children;
  return @found;
}

requires 'as_sieve';

no Moo::Role;
1;
