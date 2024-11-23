#!perl
use v5.36.0;
use lib 'lib';
use Sieve '-all';

use Test2::API qw/context/;
use Test::Differences;
use Test::More;

unified_diff;

my $json = JSON::MaybeXS->new->pretty->canonical->encode({
  masks => 0,
  tea   => { ladygrey => 5, oolong => 0 },
  soup  => [ qw( clam clam clam corn ) ],
});

sub sieve_is ($sieve, $expect, $desc) {
  my $ctx = context();

  my $bool = eq_or_diff(
    $sieve->as_sieve,
    $expect,
    $desc,
  );

  $ctx->release;
  return $bool;
}

sieve_is(
  sieve(
    terms("require", qstr([ qw( food thanksgiving ) ]), ';'),
    blank(),
    ifelse(
      anyof(
        terms("pie :is baked"),
        terms("cake :is iced"),
      ),
      block(terms("print", qstr("dessert!"))),

      allof(
        terms("turkey :is carved"),
        anyof(
          terms("rolls", ":are", qstr("buttered")),
          fourpart(sides => are => [ qw(taters yams) ] => 'creamed'),
        ),
      ),
      block(terms("print", qstr("dinner"))),

      block(comment("...keep waiting...")),
    )
  ),
  <<~'END',
  require [ "food", "thanksgiving" ] ;

  if anyof(
    pie :is baked,
    cake :is iced
  ) {
    print "dessert!"
  }
  else if allof(
    turkey :is carved,
    anyof(
      rolls :are "buttered",
      sides :are [ "taters", "yams" ] "creamed"
    )
  ) {
    print "dinner"
  }
  else {
    # ...keep waiting...
  }
  END
  "long but simple composite"
);
