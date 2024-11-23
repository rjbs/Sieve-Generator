#!perl
use v5.36.0;
use lib 't/lib';

use Sieve '-all';
use Sieve::Test '-all';

use Test::More;

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

done_testing;
