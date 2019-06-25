(function() {
  'use strict';
  var CND, FS, PATH, PD, badge, debug, echo, generate_key_or_selector, generate_keys_and_selectors, help, info, isa, jr, randomize, rpr, test, type_of, types, urge, validate, warn, whisper;

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
  PD = require('../..');

  PATH = require('path');

  FS = require('fs');

  //...........................................................................................................
  types = require('../_types');

  ({isa, validate, type_of} = types);

  randomize = require('randomatic');

  //-----------------------------------------------------------------------------------------------------------
  generate_key_or_selector = function(type) {
    var prefix, prefix_length, sigil, sigil_length, suffix, suffix_length, tag, use_prefix, use_sigil, use_suffix, use_tag;
    validate.true(type === 'key' || type === 'selector');
    use_prefix = false;
    //.........................................................................................................
    if (type === 'key') {
      use_sigil = true;
      use_suffix = true;
      use_tag = false;
      sigil_length = 1;
    } else {
      use_sigil = true;
      use_suffix = true;
      use_tag = false;
      sigil_length = 1;
    }
    //.........................................................................................................
    prefix_length = CND.random_integer(1, 15);
    suffix_length = CND.random_integer(3, 10);
    //.........................................................................................................
    sigil = use_sigil ? randomize('?', sigil_length, {
      chars: '^<>~[]'
    }) : '';
    prefix = use_prefix ? (randomize('a', prefix_length)) + ':' : '';
    suffix = use_suffix ? randomize('a', suffix_length) : '';
    tag = use_tag ? '#stamped' : '';
    return sigil + prefix + suffix + tag;
  };

  //-----------------------------------------------------------------------------------------------------------
  generate_keys_and_selectors = function() {
    var _, d, i, j, key, lines, n, path, ref, ref1, selector;
    path = PATH.join(__dirname, '../../src/tests/data-for-select-benchmark.coffee');
    lines = [];
    n = 1500;
    lines.push('@datoms = [');
    for (_ = i = 1, ref = n; (1 <= ref ? i <= ref : i >= ref); _ = 1 <= ref ? ++i : --i) {
      key = generate_key_or_selector('key');
      d = PD.new_datom(key);
      lines.push('  ' + (jr(d)));
    }
    lines.push('  ]');
    lines.push('@selectors = [');
    for (_ = j = 1, ref1 = n; (1 <= ref1 ? j <= ref1 : j >= ref1); _ = 1 <= ref1 ? ++j : --j) {
      selector = generate_key_or_selector('selector');
      lines.push('  ' + (jr(selector)));
    }
    lines.push('  ]');
    FS.writeFileSync(path, (lines.join('\n')) + '\n');
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    generate_keys_and_selectors();
  }

  // test @
// test @[ "selector keypatterns" ]
// test @[ "select 2" ]

}).call(this);
