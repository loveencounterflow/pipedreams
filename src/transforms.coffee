

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TRANSFORMS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
PD                        = require '..'
#...........................................................................................................
{ $
  $async
  select
  stamp }                 = PD

#-----------------------------------------------------------------------------------------------------------
@$as_type_datoms = ->
  ### Given raw data events (RDEs), turn them into singleton datoms, using the results of `CND.type_of`
  for the keys, so `'xy'` turns into `{ key: 'text', value: 'xy', }`, and `42` turns into `{ key: 'number',
  value: 42, }`. ###
  return $ ( d, send ) =>
    return send d if CND.isa_pod d
    type = CND.type_of d
    send PD.new_event "^#{type}", d
    return null







