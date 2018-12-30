

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SELECT'
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
{ $
  $async
  select
  stamp }                 = PD

#-----------------------------------------------------------------------------------------------------------
$add_data_region = ->
  is_first = true
  return $ 'null', ( d, send ) ->
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
    [[[],[1,2,3,4,5,6]],[{"key":"[data"},{"key":"^collection","value":[{"key":"^number","value":1},{"key":"^number","value":2},{"key":"^number","value":3},{"key":"^number","value":4},{"key":"^number","value":5},{"key":"^number","value":6}]},{"key":"]data"}],null]
    [[[{"value":true}],[1,2,3,4,5,6]],[{"key":"[data"},{"key":"^collection","value":[1,2,3,4,5,6]},{"key":"]data"}],null]
    [[[{"value":true}],[1,2,3,"~collect",4,5,6]],[{"key":"[data"},{"key":"^collection","value":[1,2,3]},{"key":"~collect"},{"key":"^collection","value":[4,5,6]},{"key":"]data"}],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      new Promise ( resolve, reject ) ->
        R             = []
        pipeline      = []
        [ parameters
          inputs ]    = probe
        pipeline.push PD.new_value_source inputs
        pipeline.push $add_data_region()
        pipeline.push $as_event()
        pipeline.push PD.$watch ( d ) -> whisper jr d
        pipeline.push PD.$collect parameters...
        pipeline.push PD.$watch ( d ) -> urge jr d
        pipeline.push PD.$watch ( d ) -> R.push d
        pipeline.push PD.$drain -> resolve R
        PD.pull pipeline...
  done()
  return null



############################################################################################################
unless module.parent?
  # include = [
  #   "async 1"
  #   "async 1 paramap"
  #   "async 2"
  #   ]
  # @_prune()
  test @



