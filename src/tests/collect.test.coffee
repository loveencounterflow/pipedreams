

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
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null


#-----------------------------------------------------------------------------------------------------------
f = ( T, method, probe, matcher, errmsg_pattern ) ->
  errmsg_pattern = if errmsg_pattern? then ( new RegExp errmsg_pattern ) else null
  try
    result = await method()
  catch error
    # throw error
    if errmsg_pattern? and ( errmsg_pattern.test error.message )
      echo CND.green jr [ probe, null, errmsg_pattern.source, ]
      T.ok true
    else
      echo CND.indigo "unexpected exception", ( jr [ probe, null, error.message, ] )
      T.fail "unexpected exception for probe #{jr probe}:\n#{error.message}"
      # return reject "failed with #{error.message}"
    return null
  if CND.equals result, matcher
    T.ok true
    echo CND.lime jr [ probe, result, null, ]
  else
    T.fail "neq: result #{jr result}, matcher #{jr matcher}"
    echo CND.red jr [ probe, result, null, ]
  # return resolve result
  return result

#-----------------------------------------------------------------------------------------------------------
$as_event = -> $ ( x, send ) ->
  type = CND.type_of x
  return send PD.new_single_event 'number', x  if ( type is 'number' )
  return send PD.new_system_event x[ 1 .. ]    if ( type is 'text' ) and ( x.startsWith '~' )
  return send PD.new_single_event 'text', x    if ( type is 'text' )
  throw new Error "unhandled type #{rpr type}"

#-----------------------------------------------------------------------------------------------------------
@[ "$collect 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[[],[1,2,3,4,5,6]],[{"key":"^collection","value":[{"key":"^number","value":1},{"key":"^number","value":2},{"key":"^number","value":3},{"key":"^number","value":4},{"key":"^number","value":5},{"key":"^number","value":6}]}],null]
    [[[{"value":true}],[1,2,3,4,5,6]],[{"key":"^collection","value":[1,2,3,4,5,6]}],null]
    [[[{"value":true}],[1,2,3,"~collect",4,5,6]],[{"key":"^collection","value":[1,2,3]},{"key":"^collection","value":[4,5,6]}],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      new Promise ( resolve, reject ) ->
        R             = []
        pipeline      = []
        [ parameters
          inputs ]    = probe
        pipeline.push PD.new_value_source inputs
        pipeline.push $as_event()
        pipeline.push PD.$watch ( d ) -> whisper jr d
        pipeline.push PD.$collect parameters...
        pipeline.push PD.$watch ( d ) -> urge jr d
        pipeline.push PD.$watch ( d ) -> R.push d unless select d, '~'
        pipeline.push PD.$drain -> resolve R
        PD.pull pipeline...
    await f T, method, probe, matcher, errmsg_pattern
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



