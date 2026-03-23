use v5.36.0;
package Sieve::Generator::Lines::Command;
# ABSTRACT: a single Sieve command statement

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

=head1 DESCRIPTION

A command is a single semicolon-terminated Sieve statement, such as C<stop;>,
C<keep;>, or C<fileinto "Spam";>.  It consists of an identifier followed by
zero or more arguments.

=attr identifier

This attribute holds the name of the Sieve command, such as C<stop>,
C<fileinto>, or C<require>.

=cut

has identifier  => (is => 'ro', required => 1);

=attr args

This attribute holds the list of arguments to the command.  Each argument may
be a plain string or an object doing L<Sieve::Generator::Text>.

=cut

has _args => (is => 'ro', required => 1, init_arg => 'args');
sub args { $_[0]->_args->@* }

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);

  my $str = $indent . $self->identifier;
  my $n = 0;

  $str .= ' ' . (ref $_ ? $_->as_sieve(0) : $_) for $self->args;
  $str .= ";\n";

  return $str;
}

no Moo;
1;
