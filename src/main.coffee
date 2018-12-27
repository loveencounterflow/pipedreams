
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
acquire = ( target, patterns ) ->
  settings  = { cwd: ( PATH.join __dirname ), deep: false, absolute: true, }
  paths     = glob.sync patterns, settings
  #.........................................................................................................
  for path in paths
    module = require path
    for key, value of module
      # urge '23233', "#{path}##{key}"
      throw new Error "duplicate key #{rpr key}" if L[ key ]?
      module[ key ] = method = value.bind module if CND.isa_function value
      L[      key ] = method unless key.startsWith '_'
  return null


############################################################################################################
### Gather methods from submodules, bind all methods to respective submodule, reflect public names into
main module. ###
acquire L,            [ '*.js', '!main.js', '!_*', '!recycle.js' ]
acquire ( L.R = {} ), 'recycle.js'



