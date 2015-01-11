// Generated by CoffeeScript 1.8.0
(function() {
  var TRM, TYPES, alert, badge, debug, echo, help, info, log, new_densort, rpr, urge, warn, whisper;

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'PIPEDREAMS2/densort';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  whisper = TRM.get_logger('whisper', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  help = TRM.get_logger('help', badge);

  urge = TRM.get_logger('urge', badge);

  echo = TRM.echo.bind(TRM);

  TYPES = require('coffeenode-types');

  module.exports = new_densort = function(key, first_idx, report_handler) {
    var buffer, buffer_element, buffer_size, element_count, key_is_function, max_buffer_size, min_legal_idx, previous_idx, send_buffered_elements, sent_count, smallest_idx;
    if (key == null) {
      key = 1;
    }
    if (first_idx == null) {
      first_idx = 0;
    }
    if (report_handler == null) {
      report_handler = null;
    }

    /* Given up to three arguments—a `key`, a `first_idx`, and a `report_handler`—return a function
    `densort = ( element, handler ) ->` that in turn accepts a series of indexed elements and a callback
    function which it will be called once for each element and in the order of the element indices.
    
    The `densort` function should be called one for each element; each element should be an object or
    primitive value. In case `key` is not callable, then indices will be retrieved as `element[ key ]`
    (`key` defaulting to `1`, because i often send 'event' lists similar to `[ type, idx, payload... ]` down
    the stream); in case `key` is a function, indices will be retrieved as `key element`. When the series
    of elements has ended, `densort` should be called once more with a `null` value to signal this.
    
    The `handler` argument to `densort` should be a NodeJS-style callback function, i.e. it should accept
    two arguments, `error` and `element`; it is sort of symmetric to `densort` as it will be called once
    as `handler null, element` for each element and once as `handler null, null` to signal exhaustion of the
    series.
     */
    key_is_function = TYPES.isa_function(key);
    buffer = [];
    buffer_size = 0;
    previous_idx = first_idx - 1;
    smallest_idx = Infinity;
    min_legal_idx = 0;
    max_buffer_size = 0;
    element_count = 0;
    sent_count = 0;
    buffer_element = (function(_this) {
      return function(idx, element) {
        if (buffer[idx] != null) {
          throw new Error("duplicate index " + (rpr(idx)));
        }
        smallest_idx = Math.min(smallest_idx, idx);
        buffer[idx] = element;
        buffer_size += +1;
        return null;
      };
    })(this);
    send_buffered_elements = (function(_this) {
      return function(handler) {

        /* Refuse to send anything unless all elements with smaller indexes have already been sent: */
        var element, _results;
        if (sent_count < (smallest_idx - first_idx)) {
          return;
        }
        _results = [];
        while (true) {

          /* Terminate loop in case nothing is in the buffer or we have reached an empty position: */
          if (buffer_size < 1 || ((element = buffer[smallest_idx]) == null)) {
            min_legal_idx = Math.max(min_legal_idx, smallest_idx);
            break;
          }

          /* Remove element to be sent from buffer (making it a sparse list in most cases), adjust sentinels and
          send element:
           */
          delete buffer[smallest_idx];
          previous_idx = smallest_idx;
          max_buffer_size = Math.max(max_buffer_size, buffer_size);
          smallest_idx += +1;
          buffer_size += -1;
          sent_count += +1;
          min_legal_idx = Math.max(min_legal_idx, smallest_idx);
          _results.push(handler(null, element));
        }
        return _results;
      };
    })(this);
    return (function(_this) {
      return function(element, handler) {
        var idx;
        if (element != null) {
          element_count += +1;
          idx = key_is_function ? key(element) : element[key];
          if (idx < min_legal_idx) {
            warn('buffer_size:      ', buffer_size);
            warn('max_buffer_size:  ', max_buffer_size);
            warn('min_legal_idx:    ', min_legal_idx);
            warn('previous_idx:     ', previous_idx);
            warn('smallest_idx:     ', smallest_idx);
            warn(buffer);
          }
          if (idx < min_legal_idx) {
            throw new Error("duplicate index " + (rpr(idx)));
          }
          if (buffer_size === 0 && idx === previous_idx + 1) {
            previous_idx = idx;
            min_legal_idx = idx + 1;
            sent_count += +1;
            if (buffer_size < 1) {
              smallest_idx = Infinity;
            }
            return handler(null, element);
          } else {
            buffer_element(idx, element);
            return send_buffered_elements(handler);
          }
        } else {
          send_buffered_elements(handler);
          if (buffer_size > 0) {
            warn('buffer_size:      ', buffer_size);
            warn('max_buffer_size:  ', max_buffer_size);
            warn('min_legal_idx:    ', min_legal_idx);
            warn('previous_idx:     ', previous_idx);
            warn('smallest_idx:     ', smallest_idx);
            warn(buffer);
          }
          if (buffer_size > 0) {
            throw new Error("detected missing elements");
          }
          if (report_handler != null) {
            report_handler([element_count, max_buffer_size]);
          }
          return handler(null, null);
        }
      };
    })(this);
  };

}).call(this);