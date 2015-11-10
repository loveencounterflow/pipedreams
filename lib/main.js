(function() {
  var $, $async, $map, CND, DS, ES, LODASH, PIPEDREAMS, alert, badge, combine, debug, echo, get_random_integer, help, info, log, rnd_from_seed, rpr, urge, warn, whisper,
    slice = [].slice;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS2';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);


  /* https://github.com/dominictarr/event-stream */

  ES = this._ES = require('event-stream');


  /* https://github.com/dominictarr/sort-stream */

  this.$sort = require('sort-stream');


  /* https://github.com/dominictarr/stream-combiner */

  combine = require('stream-combiner');

  this.new_densort = (DS = require('./densort')).new_densort.bind(DS);

  PIPEDREAMS = this;

  LODASH = CND.LODASH;

  this.$split = ES.split.bind(ES);

  $map = ES.map.bind(ES);

  this.remit = function(method) {
    var arity, get_send, on_data, on_end, send;
    send = null;
    on_end = null;
    get_send = function(self) {
      var R;
      R = function(data) {
        return self.emit('data', data);
      };
      R.error = function(error) {
        return self.emit('error', error);
      };
      R.end = function() {
        return self.emit('end');
      };
      R.pause = function() {
        return self.pause();
      };
      R.resume = function() {
        return self.resume();
      };
      R.read = function() {
        return self.read();
      };
      R.stream = self;
      return R;
    };
    on_data = function(data) {
      if (send == null) {
        send = get_send(this);
      }
      return method(data, send);
    };
    switch (arity = method.length) {
      case 2:
        null;
        break;
      case 3:
        on_end = function() {
          var end;
          if (send == null) {
            send = get_send(this);
          }
          end = (function(_this) {
            return function() {
              return _this.emit('end');
            };
          })(this);
          return method(void 0, send, end);
        };
        break;
      default:
        throw new Error("expected a method with an arity of 2 or 3, got one with an arity of " + arity);
    }
    return ES.through(on_data, on_end);
  };

  this.remit_async = function(method) {
    var arity;
    if ((arity = method.length) !== 2) {
      throw new Error("expected a method with an arity of 2, got one with an arity of " + arity);
    }
    return $map((function(_this) {
      return function(input_data, handler) {

        /* TAINT should add `done.end`, `done.pause` and so on */
        var done;
        done = function(output_data) {
          if (output_data != null) {
            return handler(null, output_data);
          } else {
            return handler();
          }
        };
        done.error = function(error) {
          return handler(error);
        };
        return method(input_data, done);
      };
    })(this));
  };

  $ = this.remit.bind(this);

  $async = this.remit_async.bind(this);

  this.combine = function() {
    var transforms;
    transforms = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return combine.apply(null, transforms);
  };

  this.$continue = function(stream) {
    return $((function(_this) {
      return function(data, send, end) {
        stream.write(data);
        if (end != null) {
          stream.end();
          return end();
        }
      };
    })(this));
  };

  this.$lockstep = function(input, settings) {

    /* Usage:
    
    ```coffee
    input_1
      .pipe D.$lockstep input_2 # or `.pipe D.$lockstep input_2, fallback: null`
      .pipe $ ( [ data_1, data_2, ], send ) =>
        ...
    ```
    
    `$lockstep` combines each piece of data coming down the stream with one piece of data emitted from the
    stream you passed in when calling the function. If the two streams turn out to have unequal lengths,
    an error is sent into the stream unless you called the function with an additional `fallback: value`
    argument.
     */
    var _end_1, _end_2, _send, buffer_1, buffer_2, fallback, flush, idx_1, idx_2;
    fallback = settings != null ? settings['fallback'] : void 0;
    idx_1 = 0;
    idx_2 = 0;
    buffer_1 = [];
    buffer_2 = [];
    _send = null;
    _end_1 = null;
    _end_2 = null;
    flush = (function(_this) {
      return function() {
        var data_1, data_2, i, idx, ref;
        if (_send != null) {
          while ((buffer_1.length > 0) && (buffer_2.length > 0) && idx_1 === idx_2) {
            _send([buffer_1.shift(), buffer_2.shift()]);
            idx_1 += +1;
            idx_2 += +1;
          }
        }
        if ((_end_1 != null) && (_end_2 != null)) {
          if ((buffer_1.length > 0) || (buffer_2.length > 0)) {
            for (idx = i = 0, ref = Math.max(buffer_1.length, buffer_2.length); 0 <= ref ? i < ref : i > ref; idx = 0 <= ref ? ++i : --i) {
              data_1 = buffer_1[idx];
              data_2 = buffer_2[idx];
              if (data_1 === void 0 || data_2 === void 0) {
                if (fallback === void 0) {
                  return _send.error(new Error("streams of unequal lengths and no fallback value given"));
                }
                if (data_1 === void 0) {
                  data_1 = fallback;
                }
                if (data_2 === void 0) {
                  data_2 = fallback;
                }
              }
              _send([data_1, data_2]);
            }
          }
          _end_1();
          return _end_2();
        }
      };
    })(this);
    input.on('data', (function(_this) {
      return function(data_2) {
        buffer_2.push(data_2);
        return flush();
      };
    })(this));
    input.pipe(this.$on_end((function(_this) {
      return function(end) {
        _end_2 = end;
        return flush();
      };
    })(this)));
    return $((function(_this) {
      return function(data_1, send, end) {
        _send = send;
        if (data_1 != null) {
          buffer_1.push(data_1);
          flush();
        }
        if (end != null) {
          _end_1 = end;
          return flush();
        }
      };
    })(this));
  };

  this.$skip_first = function(n) {
    var count;
    if (n == null) {
      n = 1;
    }
    count = 0;
    return $(function(data, send) {
      count += +1;
      if (count > n) {
        return send(data);
      }
    });
  };

  this.create_throughstream = function() {
    var P, R, end, write;
    P = 1 <= arguments.length ? slice.call(arguments, 0) : [];

    /* TAINT `end` events passed through synchronously even when `write` happens asynchronously */
    R = ES.through.apply(ES, P);
    write = R.write.bind(R);
    end = R.end.bind(R);
    R.write = function(data, handler) {
      if (handler != null) {
        return setImmediate(function() {
          return handler(null, write(data));
        });
      } else {
        return write(data);
      }
    };
    R.end = function(handler) {
      if (handler != null) {
        return setImmediate(function() {
          return handler(null, end());
        });
      } else {
        return end();
      }
    };
    R.setMaxListeners(0);
    return R;
  };

  this.$pass_through = function() {
    return $(function(data, send) {
      return send(data);
    });
  };

  this.$sub = function(sub_transformer) {
    var _send, cache, sink, source, state;
    _send = null;
    cache = void 0;
    source = this.create_throughstream();
    sink = this.create_throughstream();
    state = {};
    source.ended = false;
    sub_transformer(source, sink, state);
    sink.on('data', (function(_this) {
      return function(data) {
        return _send(data);
      };
    })(this));
    sink.on('end', (function(_this) {
      return function() {
        return _send.end();
      };
    })(this));
    return $((function(_this) {
      return function(data, send, end) {
        if (data != null) {
          _send = send;
          if (cache === void 0) {
            cache = data;
          } else {
            source.write(cache);
            cache = data;
          }
        }
        if (end != null) {
          source.ended = true;
          if (cache !== void 0) {
            return source.write(cache);
          }
        }
      };
    })(this));
  };

  this.$densort = function(key, first_idx, report_handler) {
    var ds, has_ended, signal_end;
    if (key == null) {
      key = 1;
    }
    if (first_idx == null) {
      first_idx = 0;
    }
    if (report_handler == null) {
      report_handler = null;
    }
    ds = this.new_densort(key, first_idx, report_handler);
    has_ended = false;
    signal_end = (function(_this) {
      return function(send) {
        if (!has_ended) {
          send.end();
        }
        return has_ended = true;
      };
    })(this);
    return $((function(_this) {
      return function(input_data, send, end) {
        if (input_data != null) {
          ds(input_data, function(error, output_data) {
            if (error != null) {
              return send.error(error);
            }
            return send(output_data);
          });
        }
        if (end != null) {
          return ds(null, function(error, output_data) {
            if (error != null) {
              return send.error(error);
            }
            if (output_data != null) {
              return send(output_data);
            } else {
              return signal_end(send);
            }
          });
        }
      };
    })(this));
  };

  this.$sample = function(p, options) {
    var count, headers, ref, ref1, rnd, seed;
    if (p == null) {
      p = 0.5;
    }

    /* Given a `0 <= p <= 1`, interpret `p` as the *p*robability to *p*ick a given record and otherwise toss
    it, so that `$sample 1` will keep all records, `$sample 0` will toss all records, and
    `$sample 0.5` (the default) will toss (on average) every other record.
    
    You can pipe several `$sample()` calls, reducing the data stream to 50% with each step. If you know
    your data set has, say, 1000 records, you can cut down to a random sample of 10 by piping the result of
    calling `$sample 1 / 1000 * 10` (or, of course, `$sample 0.01`).
    
    Tests have shown that a data file with 3'722'578 records (which didn't even fit into memory when parsed)
    could be perused in a matter of seconds with `$sample 1 / 1e4`, delivering a sample of around 370
    records. Because these records are randomly selected and because the process is so immensely sped up, it
    becomes possible to develop regular data processing as well as coping strategies for data-overload
    symptoms with much more ease as compared to a situation where small but realistic data sets are not
    available or have to be produced in an ad-hoc, non-random manner.
    
    **Parsing CSV**: There is a slight complication when your data is in a CSV-like format: in that case,
    there is, with `0 < p < 1`, a certain chance that the *first* line of a file is tossed, but some
    subsequent lines are kept. If you start to transform the text line into objects with named values later in
    the pipe (which makes sense, because you will typically want to thin out largeish streams as early on as
    feasible), the first line kept will be mis-interpreted as a header line (which must come first in CSV
    files) and cause all subsequent records to become weirdly malformed. To safeguard against this, use
    `$sample p, headers: true` (JS: `$sample( p, { headers: true } )`) in your code.
    
    **Predictable Samples**: Sometimes it is important to have randomly selected data where samples are
    constant across multiple runs:
    
    * once you have seen that a certain record appears on the screen log, you are certain it will be in the
      database, so you can write a snippet to check for this specific one;
    
    * you have implemented a new feature you want to test with an arbitrary subset of your data. You're
      still tweaking some parameters and want to see how those affect output and performance. A random
      sample that is different on each run would be a problem because the number of records and the sheer
      bytecount of the data may differ from run to run, so you wouldn't be sure which effects are due to
      which causes.
    
    To obtain predictable samples, use `$sample p, seed: 1234` (with a non-zero number of your choice);
    you will then get the exact same
    sample whenever you re-run your piping application with the same stream and the same seed. An interesting
    property of the predictable sample is that—everything else being the same—a sample with a smaller `p`
    will always be a subset of a sample with a bigger `p` and vice versa.
     */
    if (!((0 <= p && p <= 1))) {
      throw new Error("expected a number between 0 and 1, got " + (rpr(p)));
    }

    /* Handle trivial edge cases faster (hopefully): */
    if (p === 1) {
      return $((function(_this) {
        return function(record, send) {
          return send(record);
        };
      })(this));
    }
    if (p === 0) {
      return $((function(_this) {
        return function(record, send) {
          return null;
        };
      })(this));
    }
    headers = (ref = options != null ? options['headers'] : void 0) != null ? ref : false;
    seed = (ref1 = options != null ? options['seed'] : void 0) != null ? ref1 : null;
    count = 0;
    rnd = rnd_from_seed(seed);
    return $((function(_this) {
      return function(record, send) {
        count += 1;
        if ((count === 1 && headers) || rnd() < p) {
          return send(record);
        }
      };
    })(this));
  };

  this.$aggregate = function(initial_value, on_data, on_end) {
    var current_value;
    if (on_end == null) {
      on_end = null;
    }

    /* `$aggregate` allows to compose stream transformers that act on the entire stream. Aggregators may
    
    * replace all data items with a single item;
    * observe the entire stream and either add or print out summary values.
    
    `$aggregate` should be called with two or three arguments:
    * `initial_value` is the base value that represents the value of the aggregator when it never
      gets to see any data; for a count or a sum that would be `0`, for a list of all data items, that would
      be an empty list, and so on.
    * `on_data` is the handler for each data items. It will be called as `on_data data, send`. Whatever
      value the data handler returns becomes the next value of the aggregator. If you want to *keep* data
      ittems in the stream, you must call `send data`; if you want to *omit* data items (and maybe later on
      replace them with the aggregate), do not call `send data`.
    * `on_end`, when given, will be called as `on_end current_value, send` after the last data item has come
      down the stream, but before `end` is emitted on the stream. It gives you the chance to perform some
      data transformation on your aggregate. If `on_end` is not given, the default operation is to just send
      on the current value of the aggregate.
    
    See `$count` and `$collect` for examples of aggregators.
    
    Note that unlike `Array::reduce`, handlers will not be given much context; it is your obligation to do
    all the bookkeeping—which should be a simple and flexible thing to implement using JS closures.
     */
    current_value = initial_value;
    return $((function(_this) {
      return function(data, send, end) {
        if (data != null) {
          current_value = on_data(data, send);
        }
        if (end != null) {
          if (on_end != null) {
            on_end(current_value, send);
          } else {
            send(current_value);
          }
          return end();
        }
      };
    })(this));
  };

  this.$count = function(on_end) {
    var count, on_data;
    if (on_end == null) {
      on_end = null;
    }
    count = 0;
    on_data = function(data, send) {
      send(data);
      return count += +1;
    };
    return this.$aggregate(count, on_data, on_end);
  };

  this.$collect = function(on_end) {
    var collector, on_data;
    if (on_end == null) {
      on_end = null;
    }
    collector = [];
    on_data = function(data, send) {
      collector.push(data);
      return collector;
    };
    return this.$aggregate(collector, on_data, on_end);
  };

  this.$spread = function(settings) {
    var end, indexed, ref, ref1;
    indexed = (ref = settings != null ? settings['indexed'] : void 0) != null ? ref : false;
    end = (ref1 = settings != null ? settings['end'] : void 0) != null ? ref1 : false;
    return $((function(_this) {
      return function(data, send) {
        var i, idx, len, type, value;
        if (!(type = (CND.type_of(data)) === 'list')) {
          return send.error(new Error("expected a list, got a " + (rpr(type))));
        }
        for (idx = i = 0, len = data.length; i < len; idx = ++i) {
          value = data[idx];
          send(indexed ? [idx, value] : value);
        }
        if (end) {
          return send(null);
        }
      };
    })(this));
  };

  this.$batch = function(batch_size) {
    var buffer;
    if (batch_size == null) {
      batch_size = 1000;
    }
    if (batch_size < 0) {
      throw new Error("buffer size must be non-negative integer, got " + (rpr(batch_size)));
    }
    buffer = [];
    return $((function(_this) {
      return function(data, send, end) {
        if (data != null) {
          buffer.push(data);
          if (buffer.length >= batch_size) {
            send(buffer);
            buffer = [];
          }
        }
        if (end != null) {
          if (buffer.length > 0) {
            send(buffer);
          }
          return end();
        }
      };
    })(this));
  };

  this.$on_end = function(method) {

    /* TAINT use `$map` to turn this into an async method? */
    var arity;
    switch (arity = method.length) {
      case 0:
      case 1:
      case 2:
        null;
        break;
      default:
        throw new Error("expected method with arity 1 or 2, got one with arity " + arity);
    }
    return $(function(data, send, end) {
      if (data != null) {
        send(data);
      }
      if (end != null) {
        if (arity === 0) {
          method();
          return end();
        }
        if (arity === 1) {
          return method(end);
        }
        return method(send, end);
      }
    });
  };

  this.$on_start = function(method) {
    var is_first;
    is_first = true;
    return $(function(data, send) {
      if (is_first) {
        method(send);
      }
      is_first = false;
      return send(data);
    });
  };

  this.$filter = function(method) {
    return $((function(_this) {
      return function(data, send) {
        if (method(data)) {
          return send(data);
        }
      };
    })(this));
  };

  this.$show = function(badge) {
    var my_show;
    if (badge == null) {
      badge = null;
    }
    my_show = CND.get_logger('info', badge != null ? badge : '*');
    return $((function(_this) {
      return function(record, send) {
        my_show(rpr(record));
        return send(record);
      };
    })(this));
  };

  this.$observe = function(method) {

    /* Call `method` for each piece of data; when `method` has returned with whatever result, send data on.
    Essentially the same as a `$filter` transform whose method always returns `true`.
     */
    var arity;
    switch (arity = method.length) {
      case 1:
        return $((function(_this) {
          return function(data, send) {
            method(data);
            return send(data);
          };
        })(this));
      case 2:
        return $((function(_this) {
          return function(data, send, end) {
            if (data != null) {
              method(data, false);
              send(data);
            }
            if (end != null) {
              method(void 0, true);
              return end();
            }
          };
        })(this));
      default:
        throw new Error("expected method with arity 1 or 2, got one with arity " + arity);
    }
  };

  this.$stop_time = function(badge_or_handler) {
    var t0;
    t0 = null;
    return this.$observe((function(_this) {
      return function(data, is_last) {
        var dt, logger, type;
        if ((data != null) && (t0 == null)) {
          t0 = +new Date();
        }
        if (is_last) {
          dt = (new Date()) - t0;
          switch (type = CND.type_of(badge_or_handler)) {
            case 'function':
              return badge_or_handler(dt);
            case 'text':
            case 'jsundefined':
              logger = CND.get_logger('info', badge_or_handler != null ? badge_or_handler : 'stop time');
              return logger(((dt / 1000).toFixed(2)) + "s");
            default:
              throw new Error("expected function or text, got a " + type);
          }
        }
      };
    })(this));
  };

  this.$throttle_bytes = function(bytes_per_second) {
    var Throttle;
    Throttle = require('throttle');
    return new Throttle(bytes_per_second);
  };

  this.$throttle_items = function(items_per_second) {
    var _send, buffer, count, emit, has_ended, idx, start, timer;
    buffer = [];
    count = 0;
    idx = 0;
    _send = null;
    timer = null;
    has_ended = false;
    emit = function() {
      var data;
      if ((data = buffer[idx]) !== void 0) {
        buffer[idx] = void 0;
        idx += +1;
        count += -1;
        _send(data);
      }
      if (has_ended && count < 1) {
        clearInterval(timer);
        _send.end();
        buffer = _send = timer = null;
      }
      return null;
    };
    start = function() {
      return timer = setInterval(emit, 1 / items_per_second * 1000);
    };
    return $((function(_this) {
      return function(data, send, end) {
        if (data != null) {
          if (_send == null) {
            _send = send;
            start();
          }
          buffer.push(data);
          count += +1;
        }
        if (end != null) {
          return has_ended = true;
        }
      };
    })(this));
  };

  this.run = function(method, handler) {
    var domain;
    domain = (require('domain')).create();
    domain.on('error', function(error) {
      return handler(error);
    });
    setImmediate(function() {
      return domain.run(method);
    });
    return domain;
  };

  get_random_integer = function(rnd, min, max) {
    return (Math.floor(rnd() * (max + 1 - min))) + min;
  };

  rnd_from_seed = function(seed) {
    if (seed != null) {
      return CND.get_rnd(seed);
    } else {
      return Math.random;
    }
  };

}).call(this);

//# sourceMappingURL=../sourcemaps/main.js.map