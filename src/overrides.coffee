
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
  collector = null
  defaults  = { select: null, key: 'collection', callback: null, value: null, }
  settings  = assign {}, defaults, settings
  send      = null
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
    debug '37763-1', collector
    return unless collector?
    if settings.callback? then  settings.callback collector
    else                        send PD.new_single_event settings.key, collector
    collector = null
  #.........................................................................................................
  collect = ( d ) ->
    collector ?= []
    collector.push ( get_value d ) ? null
    return null
  #.........................................................................................................
  return $ { last: PD.symbols.last, }, ( d, _send ) ->
    send = _send
    debug '37763-2', d
    #.......................................................................................................
    if d is PD.symbols.last
      debug '37763-3', d
      expedite()
      send PD.symbols.end
    #.......................................................................................................
    else if select d, '~collect'
      expedite()
      send d
    #.......................................................................................................
    else
      return collect d if ( not settings.select? ) and ( not PD.is_system d )
      return collect d if (     settings.select? ) and ( select d, settings.select )
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
