// Generated by CoffeeScript 2.3.1
(function() {
  'use strict';
  var $, $as_type_datoms, $async, CND, PD, after, alert, badge, debug, defer, echo, every, help, info, inspect, is_empty, jr, log, rpr, select, urge, warn, whisper, wye_3, wye_4, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/EXPERIMENTS/VARIOUS-PULL-STREAMS';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PD = require('../..');

  ({$, select, $async} = PD);

  //...........................................................................................................
  after = function(dts, f) {
    return setTimeout(f, dts * 1000);
  };

  every = function(dts, f) {
    return setInterval(f, dts * 1000);
  };

  defer = setImmediate;

  ({jr, is_empty} = CND);

  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  // https://pull-stream.github.io/#pull-through
  // nope https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)

  // https://github.com/pull-stream/pull-cont
  // https://github.com/pull-stream/pull-defer
  // https://github.com/scrapjs/pull-imux

  //-----------------------------------------------------------------------------------------------------------
  $as_type_datoms = function() {
    /* Given raw data events (RDEs), turn them into signleton datoms, using the results of `CND.type_of`
    for the keys, so `'xy'` turns into `{ key: 'text', value: 'xy', }`, and `42` turns into `{ key: 'number',
    value: 42, }`. */
    return $((d, send) => {
      var type;
      debug('29209', d, CND.type_of(d));
      if (CND.isa_pod(d)) {
        return send(d);
      }
      type = CND.type_of(d);
      if (type === 'text' && d.startsWith('~')) {
        send(PD.new_event(d, null));
      } else {
        send(PD.new_event(`^${type}`, d));
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_3 = async function() {
    var demo, provide_$end;
    //.........................................................................................................
    provide_$end = function() {
      return this.$end = function() {
        // a sink function: accept a source...
        return function(read) {
          // ...but return another source!
          return function(abort, handler) {
            read(abort, function(error, data) {
              if (error) {
                // if the stream has ended, pass that on.
                return handler(error);
              }
              debug(this.symbols.end);
              if (data === this.symbols.end) {
                return handler(true);
              }
              handler(null, data);
              return null;
            });
            return null;
          };
          return null;
        };
      };
    };
    provide_$end.apply(PD);
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, bystream, mainline;
        bysource = PD.new_push_source();
        byline = [];
        // byline.push PD.new_value_source "JUST A FEW WORDS".split /\s/
        byline.push(bysource);
        byline.push($({
          last: null
        }, function(d, send) {
          debug(CND.red('22922', jr(d)));
          return send(d);
        }));
        // byline.push PD.$watch ( d ) -> whisper 'bystream', jr d
        byline.push($as_type_datoms());
        bystream = PD.pull(...byline);
        //.......................................................................................................
        mainline = [];
        mainline.push(PD.new_random_async_value_source("just a few words ~stop".split(/\s+/)));
        mainline.push($as_type_datoms());
        mainline.push($(function(d, send) {
          return send((select(d, '~stop')) ? PD.symbols.end : d);
        }));
        mainline.push(PD.$wye(bystream));
        // mainline.push $ { last: null, }, ( d, send ) ->
        //   debug CND.plum '10109', d
        //   send PD.new_event '~end' unless d?
        //   send d
        mainline.push($async({
          last: null
        }, function(d, send, done) {
          echo('33450', xrpr(d));
          if (d != null) {
            if (select(d, '^text')) {
              defer(function() {
                return bysource.send(d.value.length);
              });
              send(d);
              done();
            } else {
              send(d);
              done();
            }
          } else {
            defer(function() {
              return bysource.send(null);
            });
            // bysource.end()
            send(d);
            done();
          }
          return null;
        }));
        mainline.push(PD.$collect());
        mainline.push(PD.$show({
          title: 'mainstream'
        }));
        mainline.push(PD.$drain(function() {
          help('ok');
          return resolve();
        }));
        PD.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_4 = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, bystream, mainline;
        bysource = PD.new_push_source();
        byline = [];
        byline.push(bysource);
        byline.push(PD.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        bystream = PD.pull(...byline);
        //.......................................................................................................
        mainline = [];
        mainline.push(PD.new_value_source([5, 7]));
        mainline.push(PD.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PD.$wye(bystream));
        mainline.push(PD.$show({
          title: 'confluence'
        }));
        mainline.push($(function(d, send) {
          if (d < 1.001) {
            return send(null);
          } else {
            send(d);
            return bysource.send(Math.sqrt(d));
          }
        }));
        mainline.push(PD.$map(function(d) {
          return d.toFixed(3);
        }));
        mainline.push(PD.$collect());
        mainline.push(PD.$show({
          title: 'mainstream'
        }));
        mainline.push(PD.$drain(function() {
          help('ok');
          return resolve();
        }));
        PD.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    debug('finish');
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.wye_with_duplex_pair = function() {
    var client, clientline, extra_stream, new_duplex_pair, refillable, server, serverline;
    new_duplex_pair = require('pull-pair/duplex');
    [client, server] = new_duplex_pair();
    clientline = [];
    serverline = [];
    refillable = [];
    extra_stream = PS.new_refillable_source(refillable, {
      repeat: 10,
      show: true
    });
    // extra_stream        = PS.new_push_source()
    //.........................................................................................................
    // pipe the second duplex stream back to itself.
    serverline.push(PS.new_merged_source(server, extra_stream));
    // serverline.push client
    serverline.push(PS.$defer());
    serverline.push(PS.$watch(function(d) {
      return urge(d);
    }));
    serverline.push($(function(d, send) {
      return send(d * 10);
    }));
    serverline.push(server);
    PS.pull(...serverline);
    //.........................................................................................................
    clientline.push(PS.new_value_source([1, 2, 3]));
    // clientline.push PS.$defer()
    clientline.push(client);
    // clientline.push PS.$watch ( d ) -> extra_stream.send d if d < 30
    clientline.push(PS.$watch(function(d) {
      if (d < 30) {
        return refillable.push(d);
      }
    }));
    clientline.push(PS.$collect());
    clientline.push(PS.$show());
    // clientline.push client
    clientline.push(PS.$drain());
    PS.pull(...clientline);
    //.........................................................................................................
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    (async function() {
      return (await wye_3());
    })();
  }

  // await wye_4()
// wye_4()

}).call(this);

//# sourceMappingURL=wye-demos.js.map