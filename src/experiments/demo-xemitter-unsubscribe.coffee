
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
  XE.listen_to '^result', ( d ) -> urge 'µ1', "result: #{rpr d.value}"
  unsubscribe_add = XE.listen_to '^compute', add
  urge 'µ2', await XE.emit PD.new_event '^compute', { a: 42, b: 108, }
  unsubscribe_add()
  urge 'µ3', await XE.emit PD.new_event '^compute', { a: 42, b: 108, }
  unsubscribe_multiply = XE.listen_to '^compute', multiply
  urge 'µ4', await XE.emit PD.new_event '^compute', { a: 42, b: 108, }
  unsubscribe_multiply()
  urge 'µ5', await XE.emit PD.new_event '^compute', { a: 42, b: 108, }






