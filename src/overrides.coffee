
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
#...........................................................................................................
{ jr
  copy
  assign }                = CND
#...........................................................................................................
override_sym              = Symbol.for 'override'

#-----------------------------------------------------------------------------------------------------------
@$drain = ( P... ) ->
  pipeline = []
  pipeline.push @$ ( d, send ) ->
    if ( @select d, '~end' )
      send @symbols.end
    else
      send d
  pipeline.push PS.$drain P...
  return @pull pipeline...



############################################################################################################
L = @
do ->
  ### Mark all methods defined here as overrides: ###
  for key, value of L
    value[ override_sym ] = true
