
############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/CIRCULAR-PIPELINES'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
PD                        = require '../..'
{ $
  $async
  select
  stamp }                 = PD
#...........................................................................................................
{ jr
  copy
  assign }                = CND
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout f, dts * 1000
defer                     = setImmediate
rprx                      = ( d ) -> "#{d.sigil} #{d.key}:: #{jr d.value ? null} #{jr d.stamped ? false}"
#...........................................................................................................
types                     = require '../_types'
{ isa
  validate
  declare
  size_of
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
provide_collatz = ->

  #-----------------------------------------------------------------------------------------------------------
  @new_number_datom = ( value, other... ) ->
    return PD.new_single_datom 'number', { value, }, other...

  #-----------------------------------------------------------------------------------------------------------
  @is_one  = ( n ) -> n is 1
  @is_odd  = ( n ) -> n %% 2 isnt 0
  @is_even = ( n ) -> n %% 2 is 0

  #-----------------------------------------------------------------------------------------------------------
  @$odd_numbers = ( S ) ->
    return $ ( d, send ) =>
      if ( select d, '^number' ) and ( not @is_one d.value ) and ( @is_odd d.value )
        ### If data datom matches condition, stamp and send it; then, send new data that has been computed
        from the datom: ###
        send stamp d
        send PD.R.recycling ( @new_number_datom ( d.value * 3 + 1 ), from: d.value )
      else
        ### If data datom doesn't match condition, just send it on; this will implicitly include
        any `~sync` datoms: ###
        send d
      return null

  #-----------------------------------------------------------------------------------------------------------
  @$even_numbers = ( S ) ->
    ### Same as `$odd_numbers()`, just simplified, and with a different condition for data selection: ###
    return $ ( d, send ) =>
      return send d unless ( select d, '^number' ) and ( @is_even d.value )
      send stamp d
      send PD.R.recycling @new_number_datom ( d.value / 2 ), from: d.value
      return null

  #-----------------------------------------------------------------------------------------------------------
  @$skip_known = ( S ) ->
    known = new Set()
    return $ ( d, send ) =>
      return send d unless select d, '^number'
      return null if known.has d.value
      send d
      known.add d.value

  #-----------------------------------------------------------------------------------------------------------
  @$terminate = ( S ) ->
    return $ ( d, send ) =>
      if ( select d, '^number', '#stamped' ) and ( @is_one d.value )
        send stamp d
        send PD.new_end_datom()
      else
        send d
      return null

  #-----------------------------------------------------------------------------------------------------------
  @$throw_on_illegal = -> PD.$watch ( d ) ->
    if ( select d, '^number', '#stamped' ) and ( type = type_of d.value ) isnt 'number'
      throw new Error "found an illegal #{type} in #{rpr d}"
    return null

  #-----------------------------------------------------------------------------------------------------------
  @$main = ( S ) ->
    pipeline = []
    pipeline.push COLLATZ.$skip_known           S
    # pipeline.push PD.$delay 0.1
    pipeline.push COLLATZ.$even_numbers         S
    pipeline.push COLLATZ.$odd_numbers          S
    pipeline.push COLLATZ.$throw_on_illegal     S
    # pipeline.push COLLATZ.$terminate            S
    return PD.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  return @
COLLATZ = provide_collatz.apply {}

#-----------------------------------------------------------------------------------------------------------
$collect_numbers = ( S ) ->
  collector = null
  return $ ( d, send ) ->
    collector ?= []
    if select d, '~collect' #, '#stamped'
      send stamp d
      send PD.new_single_datom 'numbers', collector
      collector = null
    else if select d, '^number', '#stamped'
      collector.push d.value
    else
      send d
    return null

#-----------------------------------------------------------------------------------------------------------
$call_back = ( S, callback ) ->
  collector       = null
  handler_called  = false
  return $ { last: null, }, ( d, send ) ->
    if d?
      if select d, '^numbers'
        collector ?= []
        collector.push d.value
      else if select d, '~call_back'
        handler_called  = true
        callback collector ? []
        collector       = null
    else
      if collector? or not handler_called
        handler_called  = true
        callback collector ? []
        collector       = null
    return null

#-----------------------------------------------------------------------------------------------------------
new_collatz_pipeline = ( S, callback ) ->
  S.source    = PD.new_push_source()
  pipeline    = []
  #.........................................................................................................
  pipeline.push S.source
  pipeline.push PD.R.$unwrap_recycled()
  # pipeline.push PD.$watch ( d ) -> help '37744-4', jr d
  # pipeline.push PD.$delay 0.25
  pipeline.push PD.$defer()
  pipeline.push COLLATZ.$main     S
  pipeline.push PD.R.$recycle     S.source.send
  pipeline.push PD.$show()
  pipeline.push $collect_numbers  S
  pipeline.push $call_back        S, callback
  pipeline.push PD.$drain -> help 'ok'
  PD.pull pipeline...
  #.........................................................................................................
  R       = ( value ) ->
    if CND.isa_number value then  S.source.send PD.new_single_datom 'number', value
    else                          S.source.send value
  R.end   = -> S.source.end()
  return R


#-----------------------------------------------------------------------------------------------------------
@[ "collatz-conjecture" ] = ( T, done ) ->
  S                   = {}
  probes_and_matchers = [
    [[2,3,4,5,6,7,8,9,10],[[2,1],[3,10,5,16,8,4],[],[],[6],[7,22,11,34,17,52,26,13,40,20],[],[9,28,14],[]]]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      callback = ( result ) ->
        help jr [ probe, result, ]
        # T.eq result, matcher
        resolve result
      #.......................................................................................................
      send = new_collatz_pipeline S, callback
      send PD.new_datom '[data'
      for n in probe
        do ( n ) ->
          send n
          send PD.new_system_datom 'collect', null, $: { n, }
      send PD.new_datom ']data'
      send PD.new_system_datom 'call_back'
  #.........................................................................................................
  done()
  return null

############################################################################################################
unless module.parent?
  # test @, { timeout: 30000, }
  test @[ "collatz-conjecture" ]

