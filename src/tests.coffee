

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
LODASH                    = require 'lodash'
# TYPES                     = require 'coffeenode-types'
# # TEXT                      = require 'coffeenode-text'
#...........................................................................................................
# ### https://github.com/dominictarr/event-stream ###
# ES                        = require 'event-stream'
test                      = require 'guy-test'
# A                         = T.asynchronous
new_densort               = require './densort'

#-----------------------------------------------------------------------------------------------------------
collect_and_check = ( T, key, first_idx, input, max_buffer_size = null ) ->
  output        = []
  target        = LODASH.sortBy ( LODASH.cloneDeep input ), key
  element_count = input.length
  ds            = new_densort key, first_idx, ( stats ) ->
    # info "densort report:", stats
    T.eq stats, [ element_count, max_buffer_size, ] if max_buffer_size?
  #.........................................................................................................
  for collection in [ input, [ null, ], ]
    for input_element in collection
      ds input_element, ( _, output_element ) ->
        if output_element?
          output.push output_element
        else
          T.eq output, target
          return output

#-----------------------------------------------------------------------------------------------------------
@[ "densort 0" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  max_buffer_size = 0
  input           = []
  #.........................................................................................................
  output = collect_and_check T, key, first_idx, input, max_buffer_size
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 1" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  max_buffer_size = 0
  input           = [
    [ 0,  'A', ]
    [ 1,  'B', ]
    [ 2,  'C', ]
    ]
  #.........................................................................................................
  output = collect_and_check T, key, first_idx, input, max_buffer_size
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 2" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  inputs          = [
    [ [ [ 0, 'A' ], [ 1, 'B' ], [ 2, 'C' ] ], 0 ]
    [ [ [ 0, 'A' ], [ 2, 'C' ], [ 1, 'B' ] ], 2 ]
    [ [ [ 1, 'B' ], [ 0, 'A' ], [ 2, 'C' ] ], 2 ]
    [ [ [ 1, 'B' ], [ 2, 'C' ], [ 0, 'A' ] ], 3 ]
    [ [ [ 2, 'C' ], [ 0, 'A' ], [ 1, 'B' ] ], 2 ]
    [ [ [ 2, 'C' ], [ 1, 'B' ], [ 0, 'A' ] ], 3 ]
    ]
  #.........................................................................................................
  for [ input, max_buffer_size, ] in inputs
    output = collect_and_check T, key, first_idx, input, max_buffer_size
  #.........................................................................................................
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 3" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  input           = [
    [ 0,  'a', ]
    [ 1,  'b', ]
    [ 2,  'c', ]
    [ 3,  'd', ]
    [ 4,  'e', ]
    # [ 5,  'f', ]
    # [ 6,  'g', ]
    # [ 7,  'h', ]
    # [ 8,  'i', ]
    # [ 9,  'j', ]
    # [ 10, 'k', ]
    ]
  #.........................................................................................................
  count     = 0
  messages  = []
  loop
    count += +1
    whisper count if count % 1e5 is 0
    # input_txt = ( "#{idx}#{chr}" for [ idx, chr, ] in input ).join ' '
    input_txt = ( "#{idx}" for [ idx, chr, ] in input ).join ''
    try
      collect_and_check T, key, first_idx, input
      # help input_txt
    catch error
      message   = "#{error[ 'message' ]}: #{input_txt}"
      messages.push message
      warn input_txt
      T.fail message
    break unless BNP.ez_permute input
  #.........................................................................................................
  # help '\n' + messages.join '\n'
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 4" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  inputs          = [
    '012345'
    '102354'
    '01243'
    ]
  #.........................................................................................................
  for input in inputs
    input_txt = input
    input     = ( [ parseInt chr, 10 ] for chr in input )
    try
      output  = collect_and_check T, key, first_idx, input
    catch error
      message   = "#{error[ 'message' ]}: #{input_txt}"
      # messages.push message
      warn input_txt
      T.fail message
  #.........................................................................................................
  done()


# #-----------------------------------------------------------------------------------------------------------
# @[ "densort 1" ] = ( T, done ) ->
#   key       = 0
#   first_idx = 0
#   #.........................................................................................................
#   report_handler = ( [ element_count, max_buffer_size, ] ) ->
#     info "densort report:", [ element_count, max_buffer_size, ]
#   #.........................................................................................................
#   output  = []
#   input   = [
#     [ 0,  'A', ]
#     [ 1,  'B', ]
#     [ 2,  'C', ]
#     [ 3,  'D', ]
#     [ 4,  'E', ]
#     [ 5,  'F', ]
#     [ 6,  'G', ]
#     [ 7,  'H', ]
#     [ 8,  'I', ]
#     [ 9,  'J', ]
#     [ 10, 'K', ]
#     [ 11, 'L', ]
#     [ 12, 'M', ]
#     ]
#   #.........................................................................................................
#   ds = new_densort key, first_idx, report_handler
#   for input_element in input
#     ds input_element, ( _, output_element ) ->
#       if output_element is null
#       help output
#       done()
#       output.push output_element
#   #.........................................................................................................
#   return null





############################################################################################################
settings = 'timeout': 2500
test @, settings

