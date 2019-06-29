
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
LFT                       = require 'letsfreezethat'
LFT_nofreeze              = LFT.nofreeze
@_copy                    = LFT_nofreeze._copy.bind LFT
@_nofreeze                = false

#-----------------------------------------------------------------------------------------------------------
@freeze = ( d ) -> if @_nofreeze then LFT_nofreeze.freeze d else LFT.freeze d
@thaw   = ( d ) -> if @_nofreeze then LFT_nofreeze.thaw   d else LFT.thaw   d

#-----------------------------------------------------------------------------------------------------------
@lets = ( original, modifier ) ->
  if @_nofreeze
    draft = @_copy original
    if modifier?
      modifier draft
      draft.$dirty = true unless draft.$dirty isnt original.dirty
    return draft
  #.........................................................................................................
  draft = @thaw original
  if modifier?
    modifier draft
    draft.$dirty = true unless draft.$dirty isnt original.dirty
  return @freeze draft

#-----------------------------------------------------------------------------------------------------------
@set = ( d, k, P... ) ->
  if isa.text k
    throw new Error "µ67663 expected 1 value got #{count}" unless ( count = P.length ) is 1
    return @lets d, ( d ) -> d[ k ] = P[ 0 ]
  return @lets d, ( d ) -> d[ k ]  = v for k, v of assign {}, k, P...

#-----------------------------------------------------------------------------------------------------------
@unset = ( d, k ) -> @lets d, ( d ) -> delete d[ k ]

#-----------------------------------------------------------------------------------------------------------
@stamp = ( d, P... ) ->
  ### Set the `$stamped` attribute on datom to sigil it as processed. Stamped datoms will not be selected
  by the `select` method unless tag '#stamped' is used. ###
  return @lets d, ( d ) -> assign d, P..., { $stamped: true, }

#-----------------------------------------------------------------------------------------------------------
@unstamp = ( d ) ->
  return d unless d.$stamped
  return @lets d, ( d ) -> delete d.$stamped

#-----------------------------------------------------------------------------------------------------------
@is_system = ( d ) ->
  ### Return whether datom is a system datom (i.e. whether its `sigil` equals `'~'`). ###
  return d.key.match /^[~\[\]]/

#-----------------------------------------------------------------------------------------------------------
@is_stamped = ( d ) -> d.$stamped ? false ### i.e. already processed? ###
@is_fresh   = ( d ) -> d.$fresh   ? false ### i.e. created within stream? ###
@is_dirty   = ( d ) -> d.$dirty   ? false ### i.e. modified? ###

#-----------------------------------------------------------------------------------------------------------
@new_datom = ( key, value, other... ) ->
  ### TAINT should validate key ###
  ### When `other` contains a key `$`, it is treated as a hint to copy
  system-level attributes; if the value of key `$` is a POD that has itself a
  key `$`, then a copy of that value is used. This allows to write `new_datom
  ..., $: d` to copy system-level attributes such as source locations to a new
  datom. ###
  validate.pd_datom_key key
  if value?
    value = { value, } if not isa.object value
    R     = assign { key, }, value, other...
  else
    R     = assign { key, }, other...
  while ( isa.object R.$ ) and ( isa.object R.$.$ ) then R.$ = copy R.$.$
  return @freeze R

#-----------------------------------------------------------------------------------------------------------
@new_single_datom = ( key, value, other...  ) -> @new_datom         "^#{key}",  value, other...
@new_open_datom   = ( key, value, other...  ) -> @new_datom         "<#{key}",  value, other...
@new_close_datom  = ( key, value, other...  ) -> @new_datom         ">#{key}",  value, other...
@new_system_datom = ( key, value, other...  ) -> @new_datom         "~#{key}",  value, other...
@new_text_datom   = (      value, other...  ) -> @new_single_datom  'text',     value, other...
@new_end_datom    =                           -> @new_system_datom  'end'
# @new_flush_datom    =                           -> @new_system_datom  'flush'

#-----------------------------------------------------------------------------------------------------------
@new_warning = ( ref, message, d, other...  ) ->
  @new_system_datom 'warning', d, { ref, message, }, other...



