use v5.36.0;
package Sieve::Generator::Lines::Heredoc;

use Moo;
with 'Sieve::Generator::Lines';

has text => (is => 'ro', required => 1);

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);
  my $str = "${indent}text:\n" . $self->text;
  $str .= "\n" unless $str =~ /\n\z/;
  $str =~ s/^\./../mg;
  return "$str.\n";
}

no Moo;
1;
