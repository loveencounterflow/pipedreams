
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/DATOMS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
{ assign
  copy
  jr }                    = CND
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
  type_of }               = types
#...........................................................................................................
first                     = Symbol 'first'
last                      = Symbol 'last'

#-----------------------------------------------------------------------------------------------------------
@$group_by = ( grouper ) ->
  ### TAINT, simplify, generalize, implement as standard transform `$group_by()` ###
  prv_name  = null
  buffer    = null
  send      = null
  #.........................................................................................................
  flush = =>
    return unless buffer? and buffer.length > 0
    send @new_datom '^group', { name: prv_name, value: buffer[ .. ], }
    buffer = null
  #.........................................................................................................
  return @$ { last, }, ( d, send_ ) =>
    send = send_
    return flush() if d is last
    #.......................................................................................................
    if ( name = grouper d ) is prv_name
      return buffer.push d
    #.......................................................................................................
    flush()
    prv_name  = name
    buffer   ?= []
    buffer.push d
    return null
