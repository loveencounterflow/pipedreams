

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'PIPEDREAMS2/tests'
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
LODASH                    = require 'lodash'
#...........................................................................................................
# ### https://github.com/dominictarr/event-stream ###
# ES                        = require 'event-stream'
test                      = require 'guy-test'
# A                         = T.asynchronous
DS                        = require './densort'

#-----------------------------------------------------------------------------------------------------------
get_index = ( element, key ) -> if ( CND.isa_function key ) then key element else element[ key ]

#-----------------------------------------------------------------------------------------------------------
collect_and_check = ( T, key, first_idx, input, max_buffer_size = null ) ->
  output        = []
  target        = LODASH.sortBy ( LODASH.cloneDeep input ), key
  element_count = input.length
  ds            = DS.new_densort key, first_idx, ( stats ) ->
    # info "densort report:", stats
    T.eq stats, [ element_count, max_buffer_size, ] if max_buffer_size?
  #.........................................................................................................
  for collection in [ input, [ null, ], ]
    for input_element in collection
      ds input_element, ( error, output_element ) ->
        throw error if error?
        if output_element?
          output.push output_element
        else
          T.eq output, target
  #.........................................................................................................
  last_idx    = element_count + first_idx - 1
  target_idxs = (                       idx                 for idx in [ first_idx .. last_idx ] by +1 )
  output_idxs = ( ( get_index ( output[ idx ] ? [] ), key ) for idx in [ first_idx .. last_idx ] by +1 )
  T.eq output_idxs, target_idxs
  #.........................................................................................................
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
    [ 5,  'f', ]
    [ 6,  'g', ]
    # [ 7,  'h', ]
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
    break unless CND.ez_permute input
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
    '1032'
    '10243'
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

#-----------------------------------------------------------------------------------------------------------
@[ "densort 5" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  max_buffer_size = 13
  input           = [
    [ 1,  'B', ]
    [ 2,  'C', ]
    [ 3,  'D', ]
    [ 4,  'E', ]
    [ 5,  'F', ]
    [ 6,  'G', ]
    [ 7,  'H', ]
    [ 8,  'I', ]
    [ 9,  'J', ]
    [ 10, 'K', ]
    [ 11, 'L', ]
    [ 12, 'M', ]
    [ 0,  'A', ]
    ]
  #.........................................................................................................
  output = collect_and_check T, key, first_idx, input, max_buffer_size
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 6" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  max_buffer_size = 7
  input           = [
    [ 2,  'C', ]
    [ 3,  'D', ]
    [ 4,  'E', ]
    [ 5,  'F', ]
    [ 6,  'G', ]
    [ 1,  'B', ]
    [ 0,  'A', ]
    [ 7,  'H', ]
    [ 8,  'I', ]
    [ 9,  'J', ]
    [ 10, 'K', ]
    [ 11, 'L', ]
    [ 12, 'M', ]
    ]
  #.........................................................................................................
  output = collect_and_check T, key, first_idx, input, max_buffer_size
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 7" ] = ( T, done ) ->
  key             = 0
  first_idx       = 1
  max_buffer_size = null
  input           = [
    [ 0, 'A', ], [ 1, 'B', ], [ 2, 'C', ], [ 3, 'D', ], [ 4, 'E', ], ]
  #.........................................................................................................
  T.throws 'index too small: 0', -> collect_and_check T, key, first_idx, input, max_buffer_size
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "densort 7" ] = ( T, done ) ->
  key             = 0
  first_idx       = 0
  max_buffer_size = null
  input           = [
    [ 0, 'A', ], [ 1, 'B', ], [ 2, 'C', ], [ 4, 'E', ], ]
  #.........................................................................................................
  T.throws 'detected missing elements', -> collect_and_check T, key, first_idx, input, max_buffer_size
  done()






############################################################################################################
settings = 'timeout': 2500
test @, settings

