use v5.36.0;
package Sieve::Generator::Lines;
# ABSTRACT: role for objects that render as lines of Sieve code

use Moo::Role;

=head1 DESCRIPTION

This role is consumed by all objects that render as one or more complete lines
of Sieve code.  It requires a single method, C<as_sieve>.

This role isn't really meant to be used directly, and should be considered an
implementation detail that may go away.

=method as_sieve

  my $sieve_text = $lines_obj->as_sieve;
  my $sieve_text = $lines_obj->as_sieve($indent_level);

This method renders the object as a string of Sieve code.  The optional
C<$indent_level> argument is a non-negative integer controlling the
indentation depth; each level adds two spaces.  If not given, no indenting is
added.

=cut

requires 'as_sieve';

no Moo::Role;
1;
