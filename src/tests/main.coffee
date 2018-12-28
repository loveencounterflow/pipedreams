

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/MAIN'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
glob                      = require 'globby'



############################################################################################################
L = @
do ->
  paths = glob.sync PATH.join __dirname, '*.test.js'
  for path in paths
    module = require path
    for key, value of module
      debug '20922', "#{path}##{key}"
      throw new Error "duplicate key #{rpr key}" if L[ key ]?
      L[ key ] = value.bind L
  test L


