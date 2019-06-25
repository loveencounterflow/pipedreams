
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/SELECT'
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
types                     = require './_types'
{ isa
  validate
  type_of }               = types


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@select = ( d, selector ) ->
  throw new Error "µ86606 expected a selector, got none" unless selector?
  return false unless ( ( isa.object d ) and ( d.key? ) )
  #.........................................................................................................
  stamped = false
  if selector.endsWith '#stamped'
    stamped   = true
    selector  = selector[ ... selector.length - 8 ]
    throw new Error "µ33982 selector cannot just contain tag '#stamped'" if selector is ''
  #.........................................................................................................
  throw new Error "µ37783 illegal selector #{rpr selector}" unless selector_pattern.test selector
  #.........................................................................................................
  return false if ( not stamped ) and ( d.$stamped ? false )
  return d.key is selector

selector_pattern = /^[<^>\[~\]][^<^>\[~\]]*$/



