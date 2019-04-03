
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/EXPERIMENTS/XEMITTER'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
PD                        = require '../..'
jr                        = JSON.stringify
defer                     = setImmediate
{ $
  $async }                = PD
XE                        = PD.XE.new_scope()


############################################################################################################
do =>

  #---------------------------------------------------------------------------------------------------------
  add       = ( d ) -> XE.emit PD.new_event '^result', ( d.value.a + d.value.b )
  multiply  = ( d ) -> XE.emit PD.new_event '^result', ( d.value.a * d.value.b )

  #---------------------------------------------------------------------------------------------------------
  # XE.listen_to_all ( key, d ) -> info 'µ1', "#{key}: #{rpr d.value}"
  XE.listen_to '^compute', ( d ) -> help 'µ1', "^compute: #{rpr d.value}"
  XE.listen_to '^result',  ( d ) -> warn 'µ1', "^result: #{rpr d.value}"
  #.........................................................................................................
  whisper "subscribe add()"
  unsubscribe_add = XE.listen_to '^compute', add
  await XE.emit PD.new_event '^compute', { a: 42, b: 108, }
  #.........................................................................................................
  whisper "unsubscribe add()"
  unsubscribe_add()
  await XE.emit PD.new_event '^compute', { a: 42, b: 108, }
  #.........................................................................................................
  whisper "subscribe multiply()"
  unsubscribe_multiply = XE.listen_to '^compute', multiply
  await XE.emit PD.new_event '^compute', { a: 42, b: 108, }
  #.........................................................................................................
  whisper "unsubscribe multiply()"
  unsubscribe_multiply()
  await XE.emit PD.new_event '^compute', { a: 42, b: 108, }





