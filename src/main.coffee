
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
glob                      = require 'glob'
minimatch                 = require 'minimatch'
{ assign
  jr }                    = CND
override_sym              = Symbol.for 'override'
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
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
    throw new Error "duplicate key #{rpr key}" if target[ key ]? and not value[ override_sym ]
    value         = value.bind target if isa.function value
    target[ key ] = value
  return null


############################################################################################################
xport = ->
  R     = { XE: {}, }
  acquire_path      R,    'pipestreams'
  acquire_patterns  R,    '*.js', ( path ) ->
    name = PATH.basename path
    return false if name.startsWith '_'
    return false if name is 'main.js'
    # return false if name is 'recycle.js'
    return false if name is 'overrides.js'
    return false if name is 'xemitter.js'
    return true
  # acquire_patterns  R.R,  'recycle.js'
  acquire_patterns  R.XE, 'xemitter.js'
  acquire_patterns  R,    'overrides.js'
  return R

module.exports = xport()
module.exports.create_nofreeze = ->
  R           = xport()
  R._nofreeze = true
  return R




