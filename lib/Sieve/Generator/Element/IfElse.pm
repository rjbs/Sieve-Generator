use v5.36.0;
package Sieve::Generator::Element::IfElse;
# ABSTRACT: a Sieve if/elsif/else conditional construct

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

An C<IfElse> object renders a Sieve C<if>/C<elsif>/C<else> construct.  It
consists of a required condition and true-branch, optional additional
condition/branch pairs for C<elsif> clauses, and an optional final C<else>
branch.

=attr cond

This attribute holds the condition for the C<if> clause.  It may be a plain
string or an object doing L<Sieve::Generator::Element>.

=attr true

This attribute holds the block or command to execute when the C<if> condition
is true.  It should be an object doing L<Sieve::Generator::Element>.

=attr elsifs

This attribute holds an arrayref of alternating condition/block pairs for
C<elsif> clauses.  Each pair follows the same rules as C<cond> and C<true>.
If not provided, no C<elsif> clauses are rendered.

=attr else

This attribute holds the block or command for the plain C<else> clause.  If
not provided, no C<else> clause is rendered.

=cut

has cond    => (is => 'ro', required => 1);
has true    => (is => 'ro', required => 1, init_arg => 'true');
has elsifs  => (is => 'ro');
has else    => (is => 'ro');

sub as_sieve ($self, $i = undef) {
  $i //= 0;
  my $indent = q{  } x $i;

  my $str = q{};

  my $in_else;

  use experimental qw(for_list);
  for my ($cond, $block) ($self->cond, $self->true, ($self->elsifs ? $self->elsifs->@* : ())) {
    my $cond_str = ref $cond ? $cond->as_sieve($i) : $cond;
    $cond_str =~ s/\A\Q$indent\E// if ref $cond;

    if ($in_else) {
      $str .= " elsif $cond_str " . $block->as_sieve($i);
    } else {
      $str .= $indent . "if $cond_str " . $block->as_sieve($i);
    }
    $in_else = 1;
  }

  if ($self->else) {
    $str .= " else " . $self->else->as_sieve($i);
  }

  return $str;
}

no Moo;
1;
