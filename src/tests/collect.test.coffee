

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/COLLECT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
{ jr }                    = CND
#...........................................................................................................
L                         = require '../select'
PD                        = require '../..'
{ $
  $async
  select
  stamp }                 = PD
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }

#-----------------------------------------------------------------------------------------------------------
$add_data_region = ->
  is_first = true
  return $ { last: null, }, ( d, send ) ->
    if is_first
      send PD.new_event '[data'
      is_first = false
    if d? then  send d
    else        send PD.new_event ']data'

#-----------------------------------------------------------------------------------------------------------
$as_event = -> $ ( x, send ) ->
  type = CND.type_of x
  return send x                                 if ( type is 'pod' )
  return send PD.new_single_event 'number', x   if ( type is 'number' )
  return send PD.new_system_event x[ 1 .. ]     if ( type is 'text' ) and ( x.startsWith '~' )
  return send PD.new_single_event 'text', x     if ( type is 'text' )
  throw new Error "µ93883 unhandled type #{rpr type}"

#-----------------------------------------------------------------------------------------------------------
@[ "$collect 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[null,[1,2,3,4,5,6]],[{"key":"[data"},{"key":"^collection","value":[{"key":"^number","value":1},{"key":"^number","value":2},{"key":"^number","value":3},{"key":"^number","value":4},{"key":"^number","value":5},{"key":"^number","value":6}]},{"key":"]data"}],null]
    [[{"value":true},[1,2,3,4,5,6]],[{"key":"[data"},{"key":"^collection","value":[1,2,3,4,5,6]},{"key":"]data"}],null]
    [[{"value":true},[1,2,3,"~collect",4,5,6]],[{"key":"[data"},{"key":"^collection","value":[1,2,3]},{"key":"^collection","value":[4,5,6]},{"key":"]data"}],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      [ parameters
        inputs ]    = probe
      R             = []
      pipeline      = []
      pipeline.push PD.new_value_source inputs
      pipeline.push $add_data_region()
      pipeline.push $as_event()
      pipeline.push PD.$watch ( d ) -> whisper xrpr d
      pipeline.push PD.$collect parameters
      pipeline.push PD.$watch ( d ) -> urge xrpr d
      pipeline.push PD.$watch ( d ) -> R.push d
      pipeline.push PD.$drain -> help 'ok'; resolve R
      PD.pull pipeline...
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$collect with custom collector" ] = ( T, done ) ->
  probes_and_matchers = [
    [[1,2,3,4],["(",{"key":"^collection","value":[1,2,3,4]},")"],null]
    [[1,2,'~collect',3,4],["(",{"key":"^collection","value":[1,2,]},")"],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      values        = probe
      R             = []
      pipeline      = []
      pipeline.push PD.new_value_source values
      pipeline.push $ ( d, send ) -> send if d is '~collect' then PD.new_system_event 'collect' else d
      pipeline.push $as_event()
      # pipeline.push PD.$watch ( d ) -> whisper xrpr d
      pipeline.push PD.$collect { collector: R, value: true, }
      pipeline.push PD.$surround { first: '(', between: ',', last: ')', }
      pipeline.push PD.$watch ( d ) -> urge xrpr d
      pipeline.push PD.$watch ( d ) -> R.push d
      pipeline.push PD.$drain -> help 'ok'; resolve R
      PD.pull pipeline...
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$collect with callback" ] = ( T, done ) ->
  probes_and_matchers = [
    [[{"value":true},[1,2,3,4,5,6]],[[[1,2,3,4,5,6]],[{"key":"[data"},{"key":"]data"}]],null]
    [[{"value":true,"select":"number"},[1,2,3,"between",4,5,6]],[[[1,2,3],[4,5,6]],[{"key":"[data"},{"key":"^text","value":"between"},{"key":"]data"}]],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      new Promise ( resolve, reject ) ->
        [ parameters
          inputs ]          = probe
        collections         = []
        remaining           = []
        R                   = [ collections, remaining, ]
        #...................................................................................................
        parameters.callback = ( collection ) -> collections.push collection
        drainer             = -> resolve R
        #...................................................................................................
        pipeline            = []
        pipeline.push PD.new_value_source inputs
        pipeline.push $add_data_region()
        pipeline.push $as_event()
        # pipeline.push PD.$show()
        pipeline.push PD.$collect parameters
        pipeline.push PD.$watch ( d ) -> remaining.push d
        pipeline.push PD.$drain drainer
        PD.pull pipeline...
  done()
  return null



############################################################################################################
unless module.parent?
  test @
  # test @[ "$collect 1" ]
  # test @[ "$collect with callback" ]
  # test @[ "$collect with custom collector" ]
