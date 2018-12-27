
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
glob                      = require 'globby'
{ assign
  jr }                    = CND
L                         = @

#-----------------------------------------------------------------------------------------------------------
is_bound = ( f ) -> ( ( rpr f ).match /^\[Function: (?:bound )+\]$/ )?

#-----------------------------------------------------------------------------------------------------------
acquire_patterns = ( target, patterns ) ->
  settings  = { cwd: ( PATH.join __dirname ), deep: false, absolute: true, }
  paths     = glob.sync patterns, settings
  #.........................................................................................................
  for path in paths
    acquire_path target, path
  return null

#-----------------------------------------------------------------------------------------------------------
acquire_path = ( target, path ) ->
  module = require path
  for key, value of module
    throw new Error "duplicate key #{rpr key}" if L[ key ]?
    module[ key ] = ( value.bind module ) if ( CND.isa_function value ) and not is_bound value
    target[ key ] = module[ key ]         unless key.startsWith '_'
  return null


############################################################################################################
### Gather methods from submodules, bind all methods to respective submodule, reflect public names into
main module. ###
L.R = {}
acquire_path      L,    'pipestreams'
acquire_patterns  L,    [ '*.js', '!main.js', '!_*', '!recycle.js' ]
acquire_patterns  L.R,  'recycle.js'



