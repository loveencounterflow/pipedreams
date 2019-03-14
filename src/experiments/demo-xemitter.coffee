
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
PD 												= require '../..'
{ $
	$async
	XE }										= PD
# { emit
#   delegate
#   delegate_strict
#   listen_to_all
#   listen_to
#   contract }              = PD.XE


XE.listen_to_all @, ( key, event ) -> debug '28823', key, event

XE.emit 'foo', { value: 42, }





