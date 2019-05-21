
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/FREEZE'
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
  declare
  size_of
  type_of }               = types
ICE                       = require 'icepick'

#-----------------------------------------------------------------------------------------------------------
@freeze = ( x       ) -> ICE.freeze x
@thaw   = ( x       ) -> ICE.thaw   x
@set    = ( x, k, v ) -> ICE.set    x, k, v
@unset  = ( x, k    ) -> ICE.unset  x, k

