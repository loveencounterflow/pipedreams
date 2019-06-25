

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SELECT-BENCHMARK'
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
PD                        = require '../..'
{ select }                = PD
#...........................................................................................................
{ datoms
  selectors }             = require './data-for-select-benchmark'



#-----------------------------------------------------------------------------------------------------------
@[ "benchmark" ] = ( T, done ) ->
  count     = 0
  hits      = 0
  misses    = 0
  t0        = Date.now()
  #.........................................................................................................
  for d in datoms
    for selector in selectors
      count++
      whisper 'µ34411', count if ( count %% 10000 ) is 0
      if select d, selector
        hits++
      else
        misses++
  #.........................................................................................................
  t1        = Date.now()
  dt        = t1 - t0
  dts       = dt / 1000
  ops       = ( count / dt ) * 1000
  score     = ops / 100000
  dts_txt   = dts.toFixed 1
  ops_txt   = ops.toFixed 1
  score_txt = score.toFixed 3
  debug 'µ34422', "#{hits} hits, #{misses} misses"
  debug 'µ34422', "needed #{dts_txt} s for #{count} operations"
  debug 'µ34422', "#{ops_txt} operations per second"
  debug 'µ34422', "score #{score_txt} (bigger is better)"
  done()
  return null



############################################################################################################
unless module.parent?
  test @[ "benchmark" ], { timeout: 20, }

  f = ->
    RandExp   = require 'randexp'
    randomize = require 'randomatic'

    reshape_re_for_randexp = ( re ) ->
      pattern = re.source.replace /\?<[^>]+>/g, ''
      return new RegExp pattern

    generate_keys_from_patterns = ->
      keys = [
        '_datom_keypattern'
        '_selector_keypattern'
        '_tag_pattern' ]
      n = 3
      for key in keys
        rex = new RandExp reshape_re_for_randexp PD[ key ]
        for _ in [ 1 .. n ]
          probe = rex.gen()
          if ( match = probe.match PD[ key ] )?
            info key, probe, { match.groups..., }
          else
            warn key, probe
      return null

    generate_keys_or_selectors = ->
      n = 3
      for _ in [ 1 .. n ]
        prefix  = ( randomize '?', 1, { chars: '<>^~[]', } )
        suffix  = ( randomize 'aA0', length )
        length  = CND.random_integer 1, 50
        debug prefix + suffix
      return null


