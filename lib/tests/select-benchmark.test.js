// Generated by CoffeeScript 2.5.1
(function() {
  'use strict';
  var CND, PD, badge, datoms, debug, echo, f, help, info, jr, rpr, select, selectors, test, urge, warn, whisper,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/TESTS/SELECT-BENCHMARK';

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
  PD = require('../..');

  ({select} = PD);

  //...........................................................................................................
  ({datoms, selectors} = require('./data-for-select-benchmark'));

  //-----------------------------------------------------------------------------------------------------------
  this["benchmark"] = function(T, done) {
    var count, d, dt, dts, dts_txt, hits, i, j, len, len1, misses, ops, ops_txt, score, score_txt, selector, t0, t1;
    count = 0;
    hits = 0;
    misses = 0;
    t0 = Date.now();
//.........................................................................................................
    for (i = 0, len = datoms.length; i < len; i++) {
      d = datoms[i];
      for (j = 0, len1 = selectors.length; j < len1; j++) {
        selector = selectors[j];
        count++;
        if ((modulo(count, 100000)) === 0) {
          whisper('µ34411', count);
        }
        if (select(d, selector)) {
          hits++;
        } else {
          misses++;
        }
      }
    }
    //.........................................................................................................
    t1 = Date.now();
    dt = t1 - t0;
    dts = dt / 1000;
    ops = (count / dt) * 1000;
    score = ops / 100000;
    dts_txt = dts.toFixed(1);
    ops_txt = ops.toFixed(1);
    score_txt = score.toFixed(3);
    debug('µ34422', `${hits} hits, ${misses} misses`);
    debug('µ34422', `needed ${dts_txt} s for ${count} operations`);
    debug('µ34422', `${ops_txt} operations per second`);
    debug('µ34422', `score ${score_txt} (bigger is better)`);
    done();
    return null;
  };

  /*
  before:
    00:03 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 6889 hits, 243111 misses
    00:03 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 needed 1.9 s for 250000 operations
    00:03 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 134336.4 operations per second
    00:03 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 score 1.343 (bigger is better)

  after:
    00:00 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 0 hits, 250000 misses
    00:00 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 needed 0.2 s for 250000 operations
    00:00 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 1096491.2 operations per second
    00:00 PIPEDREAMS/TESTS/SELECT-BENCHMARK  ⚙  µ34422 score 10.965 (bigger is better)

  */
  //###########################################################################################################
  if (module.parent == null) {
    test(this["benchmark"], {
      timeout: 20
    });
    f = function() {
      var RandExp, generate_keys_from_patterns, generate_keys_or_selectors, randomize, reshape_re_for_randexp;
      RandExp = require('randexp');
      randomize = require('randomatic');
      reshape_re_for_randexp = function(re) {
        var pattern;
        pattern = re.source.replace(/\?<[^>]+>/g, '');
        return new RegExp(pattern);
      };
      generate_keys_from_patterns = function() {
        var _, i, j, key, keys, len, match, n, probe, ref, rex;
        keys = ['_datom_keypattern', '_selector_keypattern', '_tag_pattern'];
        n = 3;
        for (i = 0, len = keys.length; i < len; i++) {
          key = keys[i];
          rex = new RandExp(reshape_re_for_randexp(PD[key]));
          for (_ = j = 1, ref = n; (1 <= ref ? j <= ref : j >= ref); _ = 1 <= ref ? ++j : --j) {
            probe = rex.gen();
            if ((match = probe.match(PD[key])) != null) {
              info(key, probe, {...match.groups});
            } else {
              warn(key, probe);
            }
          }
        }
        return null;
      };
      return generate_keys_or_selectors = function() {
        var _, i, length, n, prefix, ref, suffix;
        n = 3;
        for (_ = i = 1, ref = n; (1 <= ref ? i <= ref : i >= ref); _ = 1 <= ref ? ++i : --i) {
          prefix = randomize('?', 1, {
            chars: '<>^~[]'
          });
          suffix = randomize('aA0', length);
          length = CND.random_integer(1, 50);
          debug(prefix + suffix);
        }
        return null;
      };
    };
  }

}).call(this);

//# sourceMappingURL=select-benchmark.test.js.map
