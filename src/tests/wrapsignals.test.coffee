

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/WRAPSIGNALS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
L                         = require '../select'
PD                        = require '../..'
# { $, $async, }            = PD


#-----------------------------------------------------------------------------------------------------------
@[ "$wrapsignals() with values" ] = ( T, done ) ->
  probes_and_matchers = [
    [0,[{"$first":true,"value":1,"key":"^value","$dirty":true},{"$last":true,"value":0,"key":"^value","$dirty":true}],null]
    [1,[{"$dirty":true,"key":"^value","value":1,"$first":true,"$last":true}],null]
    [2,[{"$first":true,"value":1,"key":"^value","$dirty":true},{"$last":true,"value":2,"key":"^value","$dirty":true}],null]
    [3,[{"$first":true,"value":1,"key":"^value","$dirty":true},{"value":2,"key":"^value"},{"$last":true,"value":3,"key":"^value","$dirty":true}],null]
    ]
  #.........................................................................................................
  run = ( n ) -> new Promise ( resolve, reject ) =>
    source    = PD.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PD.$wrapsignals()
    # pipeline.push PD.$show()
    pipeline.push PD.$collect()
    pipeline.push PD.$watch ( collector ) -> resolve collector
    pipeline.push PD.$drain()
    PD.pull pipeline...
    source.send idx for idx in [ 1 .. n ]
    source.end()
    return null
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      result = await run probe
      resolve result
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wrapsignals() with datoms" ] = ( T, done ) ->
  probes_and_matchers = [
    [0,[{"$first":true,"key":"^foo","idx":1,"$dirty":true},{"$last":true,"key":"^foo","idx":0,"$dirty":true}],null]
    [1,[{"$dirty":true,"idx":1,"key":"^foo","$first":true,"$last":true}],null]
    [2,[{"$first":true,"key":"^foo","idx":1,"$dirty":true},{"$last":true,"key":"^foo","idx":2,"$dirty":true}],null]
    [3,[{"$first":true,"key":"^foo","idx":1,"$dirty":true},{"key":"^foo","idx":2},{"$last":true,"key":"^foo","idx":3,"$dirty":true}],null]
    ]
  #.........................................................................................................
  run = ( n ) -> new Promise ( resolve, reject ) =>
    source    = PD.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PD.$wrapsignals()
    # pipeline.push PD.$show()
    pipeline.push PD.$collect()
    pipeline.push PD.$watch ( collector ) -> resolve collector
    pipeline.push PD.$drain()
    PD.pull pipeline...
    source.send PD.new_datom '^foo', { idx, } for idx in [ 1 .. n ]
    source.end()
    return null
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      result = await run probe
      resolve result
      return null
  done()
  return null





############################################################################################################
unless module.parent?
  test @
  # test @[ "$wrapsignals() with values" ]
  # test @[ "$wrapsignals() with datoms" ]


