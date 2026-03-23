package Sieve::Generator;
# ABSTRACT: generate Sieve email filter scripts

use v5.36.0;

=head1 SYNOPSIS

  use Sieve::Generator::Sugar '-all';

  my $script = sieve(
    command('require', qstr([ qw(fileinto imap4flags) ])),
    blank(),
    ifelse(
      header_exists('X-Spam'),
      block(
        command('addflag', qstr('$Junk')),
        command('fileinto', qstr('Spam')),
      ),
    ),
  );

  print $script->as_sieve;

=head1 DESCRIPTION

C<Sieve::Generator> is a library for generating Sieve (RFC 5228) email filter
programs.  With it, you build a tree of objects that can be rendered as a
complete, correctly-indented Sieve script.  These trees can be snipped apart
and stitched together, so you can generate subtrees and combined them into the
behavior you want.

The primary interface is L<Sieve::Generator::Sugar>, which exports short
constructor functions (C<sieve>, C<ifelse>, C<block>, C<command>, C<qstr>,
and so on) for building the object tree without referring to the underlying
class names directly.

The object tree will be made up of objects that expose an C<as_sieve> method,
which renders the object (and all its descendants) as Sieve.  Some of the
classes are meant to be suitable for direct use, and others are implementation
details that might change later.

=cut

1;
