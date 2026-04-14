#!perl
use v5.36.0;
use lib 't/lib';

use Sieve::Generator::Sugar '-all';
use Sieve::Generator::Parser;
use Test::GeneratedSieve '-all';

use Test::More;

my sub parses_as ($input, $expected, $desc) {
  element_eq(
    Sieve::Generator::Parser->parse($input),
    $expected,
    $desc,
  );
}

# -- bare commands --------------------------------------------------------

parses_as('stop;',    sieve(command('stop')),    "bare stop");
parses_as('keep;',    sieve(command('keep')),    "bare keep");
parses_as('discard;', sieve(command('discard')), "bare discard");

parses_as(
  "stop;\nkeep;\n",
  sieve(command('stop'), command('keep')),
  "two commands"
);

# -- string arguments -----------------------------------------------------

parses_as(
  'require "fileinto";',
  sieve(command('require', 'fileinto')),
  "command with string arg"
);

parses_as(
  'fileinto "Spam";',
  sieve(command('fileinto', 'Spam')),
  "fileinto with string"
);

# -- string lists ---------------------------------------------------------

parses_as(
  'require ["fileinto", "imap4flags"];',
  sieve(command('require', qstr(['fileinto', 'imap4flags']))),
  "command with string list"
);

# -- tagged arguments -----------------------------------------------------

parses_as(
  'fileinto :create "Archive";',
  sieve(command('fileinto', { create => undef }, 'Archive')),
  "tagged arg with no value"
);

parses_as(
  'redirect :copy "alice@example.com";',
  sieve(command('redirect', { copy => undef }, 'alice@example.com')),
  "redirect with flag tag"
);

# -- numbers --------------------------------------------------------------

parses_as(
  'if size :over 100K { stop; }',
  sieve(ifelse(test(size => { over => undef }, number(100, 'K')), block(command('stop')))),
  "number with suffix"
);

parses_as(
  'if size :over 42 { stop; }',
  sieve(ifelse(test(size => { over => undef }, number(42)), block(command('stop')))),
  "number without suffix"
);

# -- multiline strings ----------------------------------------------------

parses_as(
  "reject text:\r\nGo away.\r\n.\r\n;",
  sieve(command('reject', heredoc("Go away.\n"))),
  "command with heredoc arg"
);

parses_as(
  "reject text:\nGo away.\n.\n;",
  sieve(command('reject', heredoc("Go away.\n"))),
  "heredoc with LF line endings"
);

parses_as(
  "reject text: # a note\nGo away.\n.\n;",
  sieve(command('reject', Sieve::Generator::Element::Heredoc->new({
    text => "Go away.\n", comment => "a note",
  }))),
  "heredoc with comment on text: line"
);

parses_as(
  "reject text:\n..dot-stuffed\nnormal\n.\n;",
  sieve(command('reject', heredoc(".dot-stuffed\nnormal\n"))),
  "heredoc dot-unstuffing"
);

# -- simple if ------------------------------------------------------------

parses_as(
  'if true { stop; }',
  sieve(ifelse(test('true'), block(command('stop')))),
  "if true"
);

parses_as(
  'if exists "X-Spam" { discard; }',
  sieve(ifelse(test(exists => 'X-Spam'), block(command('discard')))),
  "if with test"
);

# -- if/else --------------------------------------------------------------

parses_as(
  'if true { stop; } else { keep; }',
  sieve(ifelse(test('true'), block(command('stop')), block(command('keep')))),
  "if/else"
);

# -- if/elsif/else --------------------------------------------------------

parses_as(
  'if true { stop; } elsif false { keep; } else { discard; }',
  sieve(ifelse(
    test('true'), block(command('stop')),
    test('false'), block(command('keep')),
    block(command('discard')),
  )),
  "if/elsif/else"
);

# -- junctions ------------------------------------------------------------

parses_as(
  'if allof(true, false) { stop; }',
  sieve(ifelse(allof(test('true'), test('false')), block(command('stop')))),
  "allof junction"
);

parses_as(
  'if anyof(exists "X-Spam", exists "X-Virus") { discard; }',
  sieve(ifelse(
    anyof(test(exists => 'X-Spam'), test(exists => 'X-Virus')),
    block(command('discard')),
  )),
  "anyof junction"
);

# -- negation -------------------------------------------------------------

parses_as(
  'if not exists "X-Spam" { keep; }',
  sieve(ifelse(negate(test(exists => 'X-Spam')), block(command('keep')))),
  "not test"
);

parses_as(
  'if not anyof(exists "X-Spam", exists "X-Virus") { keep; }',
  sieve(ifelse(
    noneof(test(exists => 'X-Spam'), test(exists => 'X-Virus')),
    block(command('keep')),
  )),
  "not anyof becomes noneof"
);

# -- nested blocks --------------------------------------------------------

parses_as(
  'if true { if false { stop; } }',
  sieve(ifelse(test('true'), block(ifelse(test('false'), block(command('stop')))))),
  "nested if"
);

# -- hash comments --------------------------------------------------------

parses_as(
  "# a comment\nstop;",
  sieve(comment("a comment"), command('stop')),
  "hash comment"
);

parses_as(
  "### triple hash\nstop;",
  sieve(comment("triple hash", { hashes => 3 }), command('stop')),
  "multi-hash comment"
);

# -- bracket comments -----------------------------------------------------

parses_as(
  "/* hello */\nstop;",
  sieve(
    Sieve::Generator::Element::BracketComment->new({ content => 'hello' }),
    command('stop'),
  ),
  "bracket comment"
);

# -- command with block (non-if) ------------------------------------------

parses_as(
  'foreverypart { discard; }',
  sieve(Sieve::Generator::Element::Command->new({
    identifier => 'foreverypart',
    block      => block(command('discard')),
  })),
  "command with block"
);

# -- round trip: a real-looking script ------------------------------------

{
  my $script = <<~'SIEVE';
  require ["fileinto", "imap4flags"];

  # spam handling
  if exists "X-Spam" {
    addflag "$Junk";
    fileinto "Spam";
  }

  if true {
    keep;
  }
  SIEVE

  my $parsed = Sieve::Generator::Parser->parse($script);
  my $rendered = $parsed->as_sieve;
  my $reparsed = Sieve::Generator::Parser->parse($rendered);

  element_eq($parsed, $reparsed, "round-trip: parse-render-reparse is stable");
}

# -- tag value followed by positional arg (valid) -------------------------

parses_as(
  'cmd :tag "v1" "v2";',
  sieve(command('cmd', { tag => 'v1' }, 'v2')),
  "tag with value followed by positional arg"
);

# -- error: tag after positional arguments --------------------------------

{
  my $ok = eval {
    Sieve::Generator::Parser->parse('cmd :tagA "v1" "v2" :tagB "v3";');
    1;
  };
  ok(!$ok, "tag after positional args croaks");
  like($@, qr/tagged argument :tagB after positional/, "error message names the offending tag");
}

# -- parse_test -----------------------------------------------------------

my sub test_parses_as ($input, $expected, $desc) {
  element_eq(
    Sieve::Generator::Parser->parse_test($input),
    $expected,
    $desc,
  );
}

test_parses_as(
  'exists "X-Spam"',
  test(exists => 'X-Spam'),
  "parse_test: simple test"
);

test_parses_as(
  'not exists "X-Spam"',
  negate(test(exists => 'X-Spam')),
  "parse_test: negated test"
);

test_parses_as(
  'allof (address :is :all "x-delivered-to" "bruce@example.com", header :contains "from" ["postmaster", "daemon"])',
  allof(
    test(address => { is => undef, all => undef }, 'x-delivered-to', 'bruce@example.com'),
    test(header  => { contains => undef }, 'from', qstr(['postmaster', 'daemon'])),
  ),
  "parse_test: the real-world allof that motivated this"
);

test_parses_as(
  'not anyof (true, false)',
  noneof(test('true'), test('false')),
  "parse_test: not anyof becomes noneof"
);

done_testing;
