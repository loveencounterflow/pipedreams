// Generated by CoffeeScript 2.5.1
(function() {
  'use strict';
  var CND, L, PD, badge, debug, declare, echo, help, info, isa, jr, rpr, size_of, test, type_of, types, urge, validate, warn, whisper;

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
  L = require('../select');

  PD = require('../..');

  // { $, $async, }            = PD
  //...........................................................................................................
  types = require('../_types');

  ({isa, validate, declare, size_of, type_of} = types);

  //-----------------------------------------------------------------------------------------------------------
  this["isa.pd_datom"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [{},
      false,
      null],
      [
        {
          "key": "^foo"
        },
        true,
        null
      ],
      [
        {
          "key": "^foo",
          "$stamped": false
        },
        true,
        null
      ],
      [
        {
          "key": "^foo",
          "$stamped": true
        },
        true,
        null
      ],
      [
        {
          "key": "^foo",
          "$dirty": true,
          "$stamped": true
        },
        true,
        null
      ],
      [
        {
          "key": "^foo",
          "$vnr": []
        },
        false,
        null
      ],
      [
        {
          "key": "^foo",
          "$vnr": [1,
        2,
        3]
        },
        true,
        null
      ],
      [
        {
          "key": "%foo",
          "$vnr": [1,
        2,
        3]
        },
        false,
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          resolve(isa.pd_datom(probe));
          return null;
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["freezing etc"] = function(T, done) {
    var d1, d2, d3, d4;
    //.........................................................................................................
    d1 = PD.new_datom('^something', 123);
    T.eq(d1.$stamped, void 0);
    d2 = PD.stamp(d1);
    T.eq(d2.$stamped, true);
    T.ok(d1 !== d2);
    debug('µ33444', d1);
    debug('µ33444', d2);
    d3 = PD.new_datom('^something', 123, {
      $fresh: true
    });
    T.eq(d3.key, '^something');
    T.eq(d3.value, 123);
    T.eq(d3.$fresh, true);
    d4 = PD.new_datom('^other', {
      x: 123
    });
    T.eq(d4.key, '^other');
    T.eq(d4.value, void 0);
    T.eq(d4.x, 123);
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

//# sourceMappingURL=types.test.js.map
