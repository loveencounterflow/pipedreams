
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/EVENTS'
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

#-----------------------------------------------------------------------------------------------------------
@stamp = ( d ) ->
  ### Set the `stamped` attribute on event to sigil it as processed. Stamped events will not be selected
  by the `select` method unless tag '#stamped' is used. ###
  d.stamped = true
  return d

#-----------------------------------------------------------------------------------------------------------
@is_system = ( d ) ->
  ### Return whether event is a system event (i.e. whether its `sigil` equals `'~'`). ###
  return d.key.match /^[~\[\]]/

#-----------------------------------------------------------------------------------------------------------
@is_stamped = ( d ) ->
  ### Return whether event is stamped (i.e. already processed). ###
  return d.stamped ? false

#-----------------------------------------------------------------------------------------------------------
@new_event = ( key, value, other... ) ->
  ### TAINT should validate key ###
  ### When `other` contains a key `$`, it is treated as a hint to copy
  system-level attributes; if the value of key `$` is a POD that has itself a
  key `$`, then a copy of that value is used. This allows to write `new_event
  ..., $: d` to copy system-level attributes such as source locations to a new
  event. ###
  if value? then  R = assign { key, value, }, other...
  else            R = assign { key,        }, other...
  ### TAINT consider to resolve recursively ###
  if ( CND.isa_pod R.$ ) and ( CND.isa_pod R.$.$ ) then R.$ = copy R.$.$
  return R

#-----------------------------------------------------------------------------------------------------------
@new_single_event   = ( key, value, other...  ) -> @new_event         "^#{key}",  value, other...
@new_open_event     = ( key, value, other...  ) -> @new_event         "<#{key}",  value, other...
@new_close_event    = ( key, value, other...  ) -> @new_event         ">#{key}",  value, other...
@new_system_event   = ( key, value, other...  ) -> @new_event         "~#{key}",  value, other...
@new_text_event     = (      value, other...  ) -> @new_single_event  'text',     value, other...
@new_end_event      =                           -> @new_system_event  'end'
@new_flush_event    =                           -> @new_system_event  'flush'

#-----------------------------------------------------------------------------------------------------------
@new_warning = ( ref, message, d, other...  ) ->
  @new_system_event 'warning', d, { ref, message, }, other...



