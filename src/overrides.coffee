
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/OVERRIDES'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
{ assign
  jr }                    = CND
#...........................................................................................................
PS                        = require 'pipestreams'
PD                        = require '..'
{ $
  $async
  select
  stamp }                 = PD
#...........................................................................................................
{ jr
  copy
  assign }                = CND
#...........................................................................................................
override_sym              = Symbol.for 'override'


#-----------------------------------------------------------------------------------------------------------
@$collect = ( settings ) ->
  defaults              = { select: null, key: 'collection', callback: null, value: null, collector: null, }
  settings              = assign {}, defaults, settings
  use_custom_collector  = settings.collector?
  send                  = null
  last_sym              = Symbol 'last'
  #.........................................................................................................
  switch ( type = CND.type_of settings.value ? null )
    when 'null'         then  get_value = ( d ) -> d
    when 'boolean'
      if settings.value then  get_value = ( d ) -> d.value
      else                    get_value = ( d ) -> d
    when 'text'         then  get_value = ( d ) -> d[ settings.value ]
    when 'function'     then  get_value = settings.value
    else throw new Error "µ20922 expected a boolean, a text or a function, got a #{type}"
  #.........................................................................................................
  expedite  = ->
    # debug '37763-1->', collector, settings.callback, settings.key
    return unless settings.collector?
    if settings.callback? then  settings.callback                       settings.collector
    else                        send PD.new_single_event settings.key,  settings.collector
    settings.collector = null
  #.........................................................................................................
  collect = ( d ) ->
    settings.collector ?= []
    settings.collector.push ( get_value d ) ? null
    return null
  #.........................................................................................................
  return $ { last: last_sym, }, ( d, _send ) ->
    send = _send
    #.......................................................................................................
    if d is last_sym
      expedite()
    #.......................................................................................................
    else if select d, '~collect'
      if use_custom_collector
        throw new Error "µ110299 unable to use `~collect` symbol with custom collector"
      expedite()
    #.......................................................................................................
    else
      return collect d if ( not settings.select? ) and ( not PD.is_system d )
      return collect d if (     settings.select? ) and ( select d, settings.select )
      ### At this point we know the current datom will not be collected, so we first send whatever we have
      collected, if anything, in order not to mess up the relative ordering of events. ###
      expedite()
      send d
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$drain = ( P... ) ->
  pipeline = []
  pipeline.push $ ( d, send ) ->
    if ( select d, '~end' )
      send PD.symbols.end
    else
      send d
  pipeline.push PS.$drain P...
  return PD.pull pipeline...



############################################################################################################
L = @
do ->
  ### Mark all methods defined here as overrides: ###
  for key, value of L
    value[ override_sym ] = true
