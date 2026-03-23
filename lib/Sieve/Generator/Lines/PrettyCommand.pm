use v5.36.0;
package Sieve::Generator::Lines::PrettyCommand;
# ABSTRACT: a Sieve command statement with arguments aligned across multiple lines

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

=head1 DESCRIPTION

A C<PrettyCommand> is like a L<Sieve::Generator::Lines::Command>, but renders
its arguments in groups, with each group on its own line and arguments within
a group aligned to the column after the command identifier.  This is useful
for commands with many tagged arguments, such as C<fileinto>.

=attr identifier

This attribute holds the name of the Sieve command.

=cut

has identifier  => (is => 'ro', required => 1);

=attr arg_groups

This attribute holds the list of argument groups.  Each group is either an
arrayref of arguments (rendered together on one line) or a single argument.
Groups are rendered on successive lines, aligned after the command name.

=cut

has _arg_groups => (is => 'ro', required => 1, init_arg => 'arg_groups');
sub arg_groups { $_[0]->_arg_groups->@* }

=method args

  my @args = $cmd->args;

This method returns the flat list of all arguments, with arrayref groups
expanded in place.

=cut

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
