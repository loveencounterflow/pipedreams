

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SELECT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
L                         = require '../select'
PD                        = require '../..'
# { $, $async, }            = PD
#...........................................................................................................
types                     = require '../_types'
{ isa
  validate
  declare
  size_of
  type_of }               = types



#-----------------------------------------------------------------------------------------------------------
@[ "isa.pd_datom" ] = ( T, done ) ->
  probes_and_matchers = [
    [{},false,null]
    [{"key":"^foo"},true,null]
    [{"key":"^foo","$stamped":false},true,null]
    [{"key":"^foo","$stamped":true},true,null]
    [{"key":"^foo","$dirty":true,"$stamped":true},true,null]
    [{"key":"^foo","$vnr":[]},false,null]
    [{"key":"^foo","$vnr":[1,2,3]},true,null]
    [{"key":"%foo","$vnr":[1,2,3]},false,null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      resolve isa.pd_datom probe
      return null
  done()
  return null





############################################################################################################
unless module.parent?
  test @
  # test @[ "selector keypatterns" ]
  # test @[ "select 2" ]


