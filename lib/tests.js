(function() {
  var CND, DS, LODASH, alert, badge, collect_and_check, debug, echo, get_index, help, info, log, rpr, settings, test, urge, warn, whisper;

  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'PIPEDREAMS2/tests';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  LODASH = CND.LODASH;

  test = require('guy-test');

  DS = require('./densort');

  get_index = function(element, key) {
    if (CND.isa_function(key)) {
      return key(element);
    } else {
      return element[key];
    }
  };

  collect_and_check = function(T, key, first_idx, input, max_buffer_size) {
    var collection, ds, element_count, i, idx, input_element, j, last_idx, len, len1, output, output_idxs, ref, target, target_idxs;
    if (max_buffer_size == null) {
      max_buffer_size = null;
    }
    output = [];
    target = LODASH.sortBy(LODASH.cloneDeep(input), key);
    element_count = input.length;
    ds = DS.new_densort(key, first_idx, function(stats) {
      if (max_buffer_size != null) {
        return T.eq(stats, [element_count, max_buffer_size]);
      }
    });
    ref = [input, [null]];
    for (i = 0, len = ref.length; i < len; i++) {
      collection = ref[i];
      for (j = 0, len1 = collection.length; j < len1; j++) {
        input_element = collection[j];
        ds(input_element, function(error, output_element) {
          if (error != null) {
            throw error;
          }
          if (output_element != null) {
            return output.push(output_element);
          } else {
            return T.eq(output, target);
          }
        });
      }
    }
    last_idx = element_count + first_idx - 1;
    target_idxs = (function() {
      var k, ref1, ref2, results;
      results = [];
      for (idx = k = ref1 = first_idx, ref2 = last_idx; k <= ref2; idx = k += +1) {
        results.push(idx);
      }
      return results;
    })();
    output_idxs = (function() {
      var k, ref1, ref2, ref3, results;
      results = [];
      for (idx = k = ref1 = first_idx, ref2 = last_idx; k <= ref2; idx = k += +1) {
        results.push(get_index((ref3 = output[idx]) != null ? ref3 : [], key));
      }
      return results;
    })();
    T.eq(output_idxs, target_idxs);
    return output;
  };

  this["densort 0"] = function(T, done) {
    var first_idx, input, key, max_buffer_size, output;
    key = 0;
    first_idx = 0;
    max_buffer_size = 0;
    input = [];
    output = collect_and_check(T, key, first_idx, input, max_buffer_size);
    return done();
  };

  this["densort 1"] = function(T, done) {
    var first_idx, input, key, max_buffer_size, output;
    key = 0;
    first_idx = 0;
    max_buffer_size = 0;
    input = [[0, 'A'], [1, 'B'], [2, 'C']];
    output = collect_and_check(T, key, first_idx, input, max_buffer_size);
    return done();
  };

  this["densort 2"] = function(T, done) {
    var first_idx, i, input, inputs, key, len, max_buffer_size, output, ref;
    key = 0;
    first_idx = 0;
    inputs = [[[[0, 'A'], [1, 'B'], [2, 'C']], 0], [[[0, 'A'], [2, 'C'], [1, 'B']], 2], [[[1, 'B'], [0, 'A'], [2, 'C']], 2], [[[1, 'B'], [2, 'C'], [0, 'A']], 3], [[[2, 'C'], [0, 'A'], [1, 'B']], 2], [[[2, 'C'], [1, 'B'], [0, 'A']], 3]];
    for (i = 0, len = inputs.length; i < len; i++) {
      ref = inputs[i], input = ref[0], max_buffer_size = ref[1];
      output = collect_and_check(T, key, first_idx, input, max_buffer_size);
    }
    return done();
  };

  this["densort 3"] = function(T, done) {
    var chr, count, error, first_idx, idx, input, input_txt, key, message, messages;
    key = 0;
    first_idx = 0;
    input = [[0, 'a'], [1, 'b'], [2, 'c'], [3, 'd'], [4, 'e'], [5, 'f'], [6, 'g']];
    count = 0;
    messages = [];
    while (true) {
      count += +1;
      if (count % 1e5 === 0) {
        whisper(count);
      }
      input_txt = ((function() {
        var i, len, ref, results;
        results = [];
        for (i = 0, len = input.length; i < len; i++) {
          ref = input[i], idx = ref[0], chr = ref[1];
          results.push("" + idx);
        }
        return results;
      })()).join('');
      try {
        collect_and_check(T, key, first_idx, input);
      } catch (_error) {
        error = _error;
        message = error['message'] + ": " + input_txt;
        messages.push(message);
        warn(input_txt);
        T.fail(message);
      }
      if (!CND.ez_permute(input)) {
        break;
      }
    }
    return done();
  };

  this["densort 4"] = function(T, done) {
    var chr, error, first_idx, i, input, input_txt, inputs, key, len, message, output;
    key = 0;
    first_idx = 0;
    inputs = ['012345', '102354', '1032', '10243'];
    for (i = 0, len = inputs.length; i < len; i++) {
      input = inputs[i];
      input_txt = input;
      input = (function() {
        var j, len1, results;
        results = [];
        for (j = 0, len1 = input.length; j < len1; j++) {
          chr = input[j];
          results.push([parseInt(chr, 10)]);
        }
        return results;
      })();
      try {
        output = collect_and_check(T, key, first_idx, input);
      } catch (_error) {
        error = _error;
        message = error['message'] + ": " + input_txt;
        warn(input_txt);
        T.fail(message);
      }
    }
    return done();
  };

  this["densort 5"] = function(T, done) {
    var first_idx, input, key, max_buffer_size, output;
    key = 0;
    first_idx = 0;
    max_buffer_size = 13;
    input = [[1, 'B'], [2, 'C'], [3, 'D'], [4, 'E'], [5, 'F'], [6, 'G'], [7, 'H'], [8, 'I'], [9, 'J'], [10, 'K'], [11, 'L'], [12, 'M'], [0, 'A']];
    output = collect_and_check(T, key, first_idx, input, max_buffer_size);
    return done();
  };

  this["densort 6"] = function(T, done) {
    var first_idx, input, key, max_buffer_size, output;
    key = 0;
    first_idx = 0;
    max_buffer_size = 7;
    input = [[2, 'C'], [3, 'D'], [4, 'E'], [5, 'F'], [6, 'G'], [1, 'B'], [0, 'A'], [7, 'H'], [8, 'I'], [9, 'J'], [10, 'K'], [11, 'L'], [12, 'M']];
    output = collect_and_check(T, key, first_idx, input, max_buffer_size);
    return done();
  };

  this["densort 7"] = function(T, done) {
    var first_idx, input, key, max_buffer_size;
    key = 0;
    first_idx = 1;
    max_buffer_size = null;
    input = [[0, 'A'], [1, 'B'], [2, 'C'], [3, 'D'], [4, 'E']];
    T.throws('index too small: 0', function() {
      return collect_and_check(T, key, first_idx, input, max_buffer_size);
    });
    return done();
  };

  this["densort 7"] = function(T, done) {
    var first_idx, input, key, max_buffer_size;
    key = 0;
    first_idx = 0;
    max_buffer_size = null;
    input = [[0, 'A'], [1, 'B'], [2, 'C'], [4, 'E']];
    T.throws('detected missing elements', function() {
      return collect_and_check(T, key, first_idx, input, max_buffer_size);
    });
    return done();
  };

  settings = {
    'timeout': 2500
  };

  test(this, settings);

}).call(this);

//# sourceMappingURL=../sourcemaps/tests.js.map