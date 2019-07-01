(function() {
  'use strict';
  var CND, L, PS, assign, badge, copy, debug, echo, help, info, jr, override_sym, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/OVERRIDES';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  ({assign, jr} = CND);

  //...........................................................................................................
  PS = require('pipestreams');

  //...........................................................................................................
  ({jr, copy, assign} = CND);

  //...........................................................................................................
  override_sym = Symbol.for('override');

  //-----------------------------------------------------------------------------------------------------------
  this.$drain = function(...P) {
    var pipeline;
    pipeline = [];
    pipeline.push(this.$((d, send) => {
      if (this.select(d, '~end')) {
        return send(this.symbols.end);
      } else {
        return send(d);
      }
    }));
    pipeline.push(PS.$drain(...P));
    return this.mark_as_sink(this.pull(...pipeline));
  };

  //###########################################################################################################
  L = this;

  (function() {
    var key, results, value;
/* Mark all methods defined here as overrides: */
    results = [];
    for (key in L) {
      value = L[key];
      results.push(value[override_sym] = true);
    }
    return results;
  })();

}).call(this);
