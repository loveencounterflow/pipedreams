
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
# glob                      = require 'globby'
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
  declare
  size_of
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
is_bound = ( f ) -> ( ( rpr f ).match /^\[Function: (?:bound )+\]$/ )?

#-----------------------------------------------------------------------------------------------------------
acquire_patterns = ( target, patterns, include = null ) ->
  validate.function include if include?
  settings  = { cwd: ( PATH.join __dirname ), deep: false, absolute: true, }
  paths     = glob.sync patterns, settings
  #.........................................................................................................
  for path in paths
    continue if include? and not include path
    acquire_path target, path
  return null

#-----------------------------------------------------------------------------------------------------------
acquire_path = ( target, path ) ->
  module = require path
  for key, value of module
    throw new Error "duplicate key #{rpr key}" if L[ key ]? and not value[ override_sym ]
    module[ key ] = ( value.bind module ) if ( CND.isa_function value ) and not is_bound value
    target[ key ] = module[ key ]
  return null


############################################################################################################
### Gather methods from submodules, bind all methods to respective submodule, reflect public names into
main module. ###
L.R   = {}
L.XE  = {}
acquire_path      L,    'pipestreams'
# acquire_patterns  L,    [ '*.js', '!main.js', '!_*', '!recycle.js', '!overrides.js', '!xemitter.js', ]
acquire_patterns  L,    '*.js', ( path ) ->
  name = PATH.basename path
  return false if name.startsWith '_'
  return false if name is 'main.js'
  return false if name is 'recycle.js'
  return false if name is 'overrides.js'
  return false if name is 'xemitter.js'
  return true
acquire_patterns  L.R,  'recycle.js'
acquire_patterns  L.XE, 'xemitter.js'
acquire_patterns  L,    'overrides.js'


