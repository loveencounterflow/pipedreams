
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/ADD_POSITION'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
{ jr, }                   = CND
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
@$add_position = ->
  ###

  ```
  {"value":1,"$first":true,"$last":true}
  ```

  ```
  {"value":1,"$first":true}
  {"value":2,"$last":true}
  ```

  ```
  {"value":1,"$first":true}
  {"value":2}
  {"value":3}
  {"value":4}
  {"value":5,"$last":true}
  ```

  ###
  is_first  = true
  prv_d     = null
  last      = Symbol 'last'
  #.........................................................................................................
  return @$ { last, }, ( d, send ) =>
    #.......................................................................................................
    if d is last
      if prv_d?
        if is_first then  prv_d = @lets prv_d, ( d ) -> d.$last = true; d.$first = true
        else              prv_d = @lets prv_d, ( d ) -> d.$last = true
        send prv_d
    #.......................................................................................................
    else
      if prv_d?
        send prv_d
      prv_d     = if ( isa.object d ) then d else @new_datom '^value', { value: d, }
      prv_d     = ( @lets prv_d, ( d ) -> d.$first = true) if is_first
      is_first  = false
    #.......................................................................................................
    return null




