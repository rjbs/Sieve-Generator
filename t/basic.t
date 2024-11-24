#!perl
use v5.36.0;
use lib 't/lib';

use Sieve::Generator::Sugar '-all';
use Test::GeneratedSieve '-all';

use Test::More;

sieve_is(
  sieve(
    command("require", qstr([ qw( food thanksgiving ) ])),
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
  require [ "food", "thanksgiving" ];

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

sieve_is(
  ifelse(
    terms(specialuse_exists => qstr('\Snoozed')),
    block(
      command(snooze => ':tzid'      => qstr('America/New_York'),
                        ':mailboxid' => qstr("000-111-222"),
                        ':addflags'  => qstr([ '$new' ]),
                        ':weekdays'  => qstr([ 1, 2, 5 ]),
                        ':times'     => qstr([ '9:00', '12:00' ]),
      )
    )
  ),
  <<~'END',
  if specialuse_exists "\\Snoozed" {
    snooze :tzid "America/New_York" :mailboxid "000-111-222" :addflags [ "$new" ] :weekdays [ "1", "2", "5" ] :times [ "9:00", "12:00" ];
  }
  END
  "commands, generically formatted"
);

require Sieve::Generator::Lines::PrettyCommand;
sieve_is(
  ifelse(
    terms(specialuse_exists => qstr('\Snoozed')),
    block(
      Sieve::Generator::Lines::PrettyCommand->new({
        identifier => 'snooze',
        arg_groups => [
          [ ':tzid'      => qstr('America/New_York') ],
          [ ':mailboxid' => qstr("000-111-222")      ],
          [ ':addflags'  => qstr([ '$new' ])         ],
          [ ':weekdays'  => qstr([ 1, 2, 5 ])        ],
          [ ':times'     => qstr([ '9:00', '12:00' ])],
        ]
      }),
    )
  ),
  <<~'END',
  if specialuse_exists "\\Snoozed" {
    snooze :tzid "America/New_York"
           :mailboxid "000-111-222"
           :addflags [ "$new" ]
           :weekdays [ "1", "2", "5" ]
           :times [ "9:00", "12:00" ];
  }
  END
  "commands, prettily formatted"
);

sieve_is(
  ifelse(
    'true',
    block(command('stop'))
  ),
  <<~'END',
  if true {
    stop;
  }
  END
  "single-command if block"
);

sieve_is(
  ifelse('true', command('stop')),
  <<~'END',
  if true stop;
  END
  "single-command if, no block"
);

done_testing;
