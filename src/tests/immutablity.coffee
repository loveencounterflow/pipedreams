

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/IMMUTABILITY'
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

#-----------------------------------------------------------------------------------------------------------
@[ "datoms are frozen" ] = ( T, done ) ->
  d = PD.new_datom '^foo', { x: 42, }
  T.ok Object.isFrozen d
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "datoms are not frozen (nofreeze)" ] = ( T, done ) ->
  PDNF = PD.create_nofreeze()
  T.ok      Object.isFrozen   PD.new_datom '^foo', { x: 42, }
  T.ok not  Object.isFrozen PDNF.new_datom '^foo', { x: 42, }
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "PD.set() sets properties, returns copy" ] = ( T, done ) ->
  d = PD.new_datom '^foo', { x: 42, }
  e = PD.set    d, 'x', 108
  f = PD.unset  d, 'x'
  g = PD.lets f, ( d ) -> d.$fresh = true
  T.ok d.x is 42
  T.ok e.x is 108
  T.ok f.$fresh is undefined
  T.ok g.$fresh is true
  T.ok not Object.hasOwnProperty f, 'x'
  T.ok not Object.hasOwnProperty d, '$dirty'
  T.ok f.$dirty is true
  T.ok e.$dirty is true
  T.ok d isnt e
  T.ok d isnt f
  T.ok e isnt f
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "PD.set() sets properties, returns copy (nofreeze)" ] = ( T, done ) ->
  PDNF = PD.create_nofreeze()
  d = PDNF.new_datom '^foo', { x: 42, }
  e = PDNF.set    d, 'x', 108
  f = PDNF.unset  d, 'x'
  g = PDNF.lets f, ( d ) -> d.$fresh = true
  T.ok d.x is 42
  T.ok e.x is 108
  T.ok f.$fresh is undefined
  T.ok g.$fresh is true
  T.ok not Object.hasOwnProperty f, 'x'
  T.ok not Object.hasOwnProperty d, '$dirty'
  T.ok f.$dirty is true
  T.ok e.$dirty is true
  T.ok d isnt e
  T.ok d isnt f
  T.ok e isnt f
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "PD.set() accepts objects like assign()" ] = ( T, done ) ->
  d = PD.new_datom '^foo', { x: 42, }
  d = PD.set    d, { x: 556, vnr: [ 1, 2, 4, ], }
  T.ok d.x is 556
  T.eq d.vnr, [ 1, 2, 4, ]
  T.ok d.$dirty is true
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "PD.set() accepts objects like assign() (nofreeze)" ] = ( T, done ) ->
  PDNF = PD.create_nofreeze()
  d = PDNF.new_datom '^foo', { x: 42, }
  T.ok not Object.isFrozen d
  d = PDNF.set    d, { x: 556, vnr: [ 1, 2, 4, ], }
  T.ok d.x is 556
  T.eq d.vnr, [ 1, 2, 4, ]
  T.ok d.$dirty is true
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "PD.stamp() performs PD.set() with additional arguments" ] = ( T, done ) ->
  d = PD.new_datom '^foo', { x: 42, }
  d = PD.stamp d, { x: 556, vnr: [ 1, 2, 4, ], }
  T.ok d.x is 556
  T.eq d.vnr, [ 1, 2, 4, ]
  T.ok d.$dirty is true
  T.ok d.$stamped is true
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "PD.stamp() performs PD.set() with additional arguments (nofreeze)" ] = ( T, done ) ->
  PDNF = PD.create_nofreeze()
  d = PDNF.new_datom '^foo', { x: 42, }
  d = PDNF.stamp d, { x: 556, vnr: [ 1, 2, 4, ], }
  T.ok d.x is 556
  T.eq d.vnr, [ 1, 2, 4, ]
  T.ok d.$dirty is true
  T.ok d.$stamped is true
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "select ignores values other than PODs" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ null, '^number',],false]
    [[ 123, '^number',],false]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ d, selector, ] = probe
      try
        resolve PD.select d, selector
      catch error
        return resolve error.message
      return null
  done()
  return null





############################################################################################################
unless module.parent?
  test @
  # test @[ "datoms are not frozen (nofreeze)" ]
  # test @[ "PD.set() sets properties, returns copy (nofreeze)" ]
  # test @[ "selector keypatterns" ]
  # test @[ "select 2" ]


