use v5.36.0;
package Sieve::Generator::Element::Heredoc;
# ABSTRACT: a Sieve multiline string (heredoc)

use Moo;
with 'Sieve::Generator::Element';

=head1 DESCRIPTION

A heredoc renders a block of text as a Sieve multiline string using the
C<text:>/C<.> syntax defined in RFC 5228.  It is typically used as an
argument to a command when the content is too large or complex for a simple
quoted string.

=attr text

This attribute holds the text content of the multiline string.  A trailing
newline is added automatically if absent, and any line beginning with C<.>
is escaped to C<..>.

=cut

has text => (is => 'ro', required => 1);

=attr comment

This attribute holds an optional hash comment that appears on the C<text:>
line, as allowed by RFC 5228.  If set, it renders as C<text: # comment>.

=cut

has comment => (is => 'ro');

sub as_sieve ($self, $i = undef) {
  $i //= 0;

  my $indent = q{  } x $i;
  my $str = "${indent}text:";
  $str .= " # " . $self->comment if defined $self->comment;
  $str .= "\n" . $self->text;
  $str .= "\n" unless $str =~ /\n\z/;
  $str =~ s/^\./../mg;
  return "$str.\n";
}

no Moo;
1;
