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

=cut

requires 'as_sieve';

no Moo::Role;
1;
