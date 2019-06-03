
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/WRAPSIGNALS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
glob                      = require 'glob'
minimatch                 = require 'minimatch'
{ assign
  jr }                    = CND
override_sym              = Symbol.for 'override'
L                         = @
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
@$wrapsignals = ->
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
        prv_d         = @set prv_d, '$first', true if is_first
        prv_d         = @set prv_d, '$last',  true
        send prv_d
    #.......................................................................................................
    else
      if prv_d?
        send prv_d
      prv_d         = if ( isa.object d ) then d else @freeze { value: d, key: '^value', }
      prv_d         = @set prv_d, '$first', true if is_first
      is_first      = false
    #.......................................................................................................
    return null




