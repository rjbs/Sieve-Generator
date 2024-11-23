use v5.36.0;

package Sieve::Lines::Heredoc {
  use Moo;
  with 'Sieve::Lines';

  has text => (is => 'ro', required => 1);

  sub as_sieve ($self, $i = undef) {
    my $str = "text:\n" . $self->text;
    $str .= "\n" unless $str =~ /\n\z/;
    $str =~ s/^\./../mg;
    return "$str.\n";
  }

  no Moo;
}
1;
