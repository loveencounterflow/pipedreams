

############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'PIPEDREAMS2/tests'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
# ### https://github.com/rvagg/through2 ###
# through2                  = require 'through2'
#...........................................................................................................
BNP                       = require 'coffeenode-bitsnpieces'
# TYPES                     = require 'coffeenode-types'
# # TEXT                      = require 'coffeenode-text'
#...........................................................................................................
# ### https://github.com/dominictarr/event-stream ###
# ES                        = require 'event-stream'
test                      = require './_XXX_TEST'
# A                         = T.asynchronous


#-----------------------------------------------------------------------------------------------------------
read_file = ( route, handler ) ->
  ( require 'fs' ).readFile route, { encoding: 'utf-8' }, ( error, text ) ->
    return handler error, text

#-----------------------------------------------------------------------------------------------------------
@[ 'your description here' ] = ( T ) ->
  R = 40 + 2
  T.eq R, 43

# #-----------------------------------------------------------------------------------------------------------
# @[ 'testing an asynchronous method' ] = ( T, done ) ->
#   read_file '/tmp/xy.txt', ( error, result ) ->
#     return T.fail error if error?
#     T.ok result.length > 0
#     done()

# #-----------------------------------------------------------------------------------------------------------
# @[ 'testing an asynchronous method with automatic error check' ] = ( T, done ) ->
#   read_file '/tmp/xy.txt', T.rsvp ( result ) ->
#     T.ok result.length > 0
#     done()

#-----------------------------------------------------------------------------------------------------------
test @

# TEXT                      = require 'coffeenode-text'

# locator = '/Volumes/Storage/cnd/node_modules/pipedreams2/lib/tests.js/null#50:9'

# urge "at #{locator}:"
# warn BNP.source_line_from_locator locator
# [ prefix, line, suffix, ] = BNP.source_line_from_locator locator, 3
# echo()
# echo TRM.grey prefix
# echo TRM.red  line
# echo TRM.grey suffix





