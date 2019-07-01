(function() {
  'use strict';
  var CND, PATH, acquire_path, acquire_patterns, assign, badge, debug, echo, glob, help, info, is_bound, isa, jr, minimatch, override_sym, rpr, type_of, types, urge, validate, warn, whisper, xport;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/MAIN';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  glob = require('glob');

  minimatch = require('minimatch');

  ({assign, jr} = CND);

  override_sym = Symbol.for('override');

  //...........................................................................................................
  types = require('./_types');

  ({isa, validate, type_of} = types);

  //-----------------------------------------------------------------------------------------------------------
  is_bound = function(f) {
    return ((rpr(f)).match(/^\[Function: (?:bound )+\]$/)) != null;
  };

  //-----------------------------------------------------------------------------------------------------------
  acquire_patterns = function(target, patterns, include = null) {
    var i, len, path, paths, settings;
    if (include != null) {
      validate.function(include);
    }
    settings = {
      cwd: PATH.join(__dirname),
      deep: false,
      absolute: true
    };
    paths = glob.sync(patterns, settings);
//.........................................................................................................
    for (i = 0, len = paths.length; i < len; i++) {
      path = paths[i];
      if ((include != null) && !include(path)) {
        continue;
      }
      acquire_path(target, path);
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  acquire_path = function(target, path) {
    var is_sink, key, module, ref, value;
    module = require(path);
    for (key in module) {
      value = module[key];
      if ((target[key] != null) && !value[override_sym]) {
        throw new Error(`duplicate key ${rpr(key)}`);
      }
      if (isa.function(value)) {
        is_sink = (ref = value[Symbol.for('sink')]) != null ? ref : false;
        value = value.bind(target);
        if (is_sink) {
          value[Symbol.for('sink')] = true;
        }
      }
      target[key] = value;
    }
    return null;
  };

  //###########################################################################################################
  xport = function() {
    var R;
    R = {
      XE: {}
    };
    acquire_path(R, 'pipestreams');
    acquire_patterns(R, '*.js', function(path) {
      var name;
      name = PATH.basename(path);
      if (name.startsWith('_')) {
        return false;
      }
      if (name === 'main.js') {
        return false;
      }
      if (name === 'overrides.js') {
        // return false if name is 'recycle.js'
        return false;
      }
      if (name === 'xemitter.js') {
        return false;
      }
      return true;
    });
    // acquire_patterns  R.R,  'recycle.js'
    acquire_patterns(R.XE, 'xemitter.js');
    acquire_patterns(R, 'overrides.js');
    return R;
  };

  module.exports = xport();

  module.exports.create_nofreeze = function() {
    var R;
    R = xport();
    R._nofreeze = true;
    return R;
  };

}).call(this);
