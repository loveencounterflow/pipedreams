// Generated by CoffeeScript 2.5.1
(function() {
  'use strict';
  var $, $async, CND, PD, badge, debug, echo, help, info, isa, jr, rpr, test, type_of, types, urge, validate, warn, whisper,
    indexOf = [].indexOf;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/TESTS/SELECT';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  jr = JSON.stringify;

  //...........................................................................................................
  types = require('../_types');

  ({isa, validate, type_of} = types);

  //...........................................................................................................
  PD = require('../..');

  ({$, $async} = PD);

  //-----------------------------------------------------------------------------------------------------------
  this["select ignores values other than PODs"] = async function(T, done) {
    var error, groupers, i, len, matcher, probe, probes_and_matchers;
    groupers = {
      odd_even: (function(x) {
        if (isa.odd(x)) {
          return 'odd';
        } else {
          return 'even';
        }
      }),
      vowel_consonant: (function(x) {
        var ref;
        if (ref = x[0], indexOf.call('aeiou', ref) >= 0) {
          return 'vowel';
        } else {
          return 'consonant';
        }
      })
    };
    probes_and_matchers = [
      [
        [[1,
        2,
        3,
        4,
        5],
        'odd_even'],
        [
          {
            "key": "^group",
            "name": "odd",
            "value": [1]
          },
          {
            "key": "^group",
            "name": "even",
            "value": [2]
          },
          {
            "key": "^group",
            "name": "odd",
            "value": [3]
          },
          {
            "key": "^group",
            "name": "even",
            "value": [4]
          },
          {
            "key": "^group",
            "name": "odd",
            "value": [5]
          }
        ],
        null
      ],
      [
        [[2,
        3,
        4,
        5],
        'odd_even'],
        [
          {
            "key": "^group",
            "name": "even",
            "value": [2]
          },
          {
            "key": "^group",
            "name": "odd",
            "value": [3]
          },
          {
            "key": "^group",
            "name": "even",
            "value": [4]
          },
          {
            "key": "^group",
            "name": "odd",
            "value": [5]
          }
        ],
        null
      ],
      [
        [[1,
        3,
        2,
        4,
        6,
        5,
        8,
        10],
        "odd_even"],
        [
          {
            "key": "^group",
            "name": "odd",
            "value": [1,
          3]
          },
          {
            "key": "^group",
            "name": "even",
            "value": [2,
          4,
          6]
          },
          {
            "key": "^group",
            "name": "odd",
            "value": [5]
          },
          {
            "key": "^group",
            "name": "even",
            "value": [8,
          10]
          }
        ],
        null
      ],
      [
        [["all",
        "odd",
        "things",
        "are",
        "unequal"],
        "vowel_consonant"],
        [
          {
            "key": "^group",
            "name": "vowel",
            "value": ["all",
          "odd"]
          },
          {
            "key": "^group",
            "name": "consonant",
            "value": ["things"]
          },
          {
            "key": "^group",
            "name": "vowel",
            "value": ["are",
          "unequal"]
          }
        ],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, grouper, pipeline, source, values;
          [values, grouper] = probe;
          grouper = groupers[grouper];
          source = PD.new_value_source(values);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(PD.$group_by(grouper));
          pipeline.push(PD.$collect({collector}));
          // pipeline.push PD.$show()
          pipeline.push(PD.$drain(function() {
            return resolve(collector);
          }));
          return PD.pull(...pipeline);
        });
      });
    }
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    test(this);
  }

  // test @[ "selector keypatterns" ]
// test @[ "select 2" ]

}).call(this);

//# sourceMappingURL=group-by.js.map
