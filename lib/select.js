(function() {
  'use strict';
  var CND, assign, badge, debug, echo, help, info, isa, jr, rpr, selector_pattern, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/SELECT';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  ({assign, jr} = CND);

  //...........................................................................................................
  types = require('./_types');

  ({isa, validate, type_of} = types);

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.select = function(d, selector) {
    var ref, stamped;
    if (selector == null) {
      throw new Error("µ86606 expected a selector, got none");
    }
    if (!((isa.object(d)) && (d.key != null))) {
      return false;
    }
    //.........................................................................................................
    stamped = false;
    if (selector.endsWith('#stamped')) {
      stamped = true;
      selector = selector.slice(0, selector.length - 8);
      if (selector === '') {
        throw new Error("µ33982 selector cannot just contain tag '#stamped'");
      }
    }
    if (!selector_pattern.test(selector)) {
      //.........................................................................................................
      throw new Error(`µ37783 illegal selector ${rpr(selector)}`);
    }
    if ((!stamped) && ((ref = d.$stamped) != null ? ref : false)) {
      //.........................................................................................................
      return false;
    }
    return d.key === selector;
  };

  selector_pattern = /^[<^>\[~\]][^<^>\[~\]]*$/;

}).call(this);
