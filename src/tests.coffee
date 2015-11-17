

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
LODASH                    = CND.LODASH
#...........................................................................................................
# ### https://github.com/dominictarr/event-stream ###
# ES                        = require 'event-stream'
test                      = require 'guy-test'
# A                         = T.asynchronous
DS                        = require './densort'
#...........................................................................................................
D                         = require './main'
$                         = D.remit.bind D
$async                    = D.remit_async.bind D


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

#-----------------------------------------------------------------------------------------------------------
@[ "create_fitting_from_pipeline accepts missing settings argument" ] = ( T, done ) ->
  create_frob_fitting = null
  #.........................................................................................................
  do ->
    create_frob_fitting = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      transforms    = [ multiply, add, unsquared, square, ]
      #.....................................................................................................
      return D.create_fitting_from_pipeline transforms
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    fitting             = create_frob_fitting()
    { input, output, }  = fitting
    #.......................................................................................................
    output
      .pipe $ ( data, send ) =>
        output_results.push data
        send data
      #.....................................................................................................
      # .pipe D.$show()
      #.....................................................................................................
      output.on 'end', =>
        T.eq output_results, output_matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "create_fitting_from_pipeline reflects extra settings" ] = ( T, done ) ->
  settings  =
    inputs:
      foo:    D.create_throughstream()
    bar:      []
    baz:      42
  pipeline  = [ D.$show(), ]
  fitting   = D.create_fitting_from_pipeline pipeline, settings
  T.eq fitting[ 'inputs' ][ 'foo' ], settings[ 'inputs' ][ 'foo' ]
  T.eq fitting[ 'bar' ], settings[ 'bar' ]
  T.eq fitting[ 'baz' ], settings[ 'baz' ]
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "create_fitting_from_pipeline" ] = ( T, done ) ->
  create_frob_fitting = null
  #.........................................................................................................
  do ->
    create_frob_fitting = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      inputs        = { add, }
      outputs       = { unsquared, }
      transforms    = [ multiply, add, unsquared, square, ]
      #.....................................................................................................
      return D.create_fitting_from_pipeline transforms, { inputs, outputs, }
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    unsquared_matchers  = [ 4, 6, 8, -8, 10, 12, 14, 16, 18, 20, ]
    unsquared_results   = []
    fitting             = create_frob_fitting()
    { input, output, inputs, outputs, } = fitting
    outputs[ 'unsquared' ].pipe $ ( data, send ) =>
      unsquared_results.push data
    #.......................................................................................................
    output
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        inputs[ 'add' ].write -10 if data is 100
        send data
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        output_results.push data
        send data
      #.....................................................................................................
      # .pipe D.$show()
      #.....................................................................................................
      output.on 'end', =>
        T.eq unsquared_results, unsquared_matchers
        T.eq    output_results,    output_matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "create_fitting_from_readwritestreams" ] = ( T, done ) ->
  create_frob_fitting       = null
  #.........................................................................................................
  do ->
    create_frob_fitting = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      inputs        = { add, }
      outputs       = { unsquared, }
      readstream    = D.create_throughstream()
      writestream   = D.create_throughstream()
      readstream
        .pipe multiply
        .pipe add
        .pipe unsquared
        .pipe square
        .pipe writestream
      #.......................................................................................................
      return D.create_fitting_from_readwritestreams readstream, writestream, { inputs, outputs, }
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    unsquared_matchers  = [ 4, 6, 8, -8, 10, 12, 14, 16, 18, 20, ]
    unsquared_results   = []
    fitting             = create_frob_fitting()
    { input, output, inputs, outputs, } = fitting
    outputs[ 'unsquared' ].pipe $ ( data, send ) =>
      unsquared_results.push data
    #.......................................................................................................
    output
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        inputs[ 'add' ].write -10 if data is 100
        send data
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        output_results.push data
        send data
      #.....................................................................................................
      # .pipe D.$show()
      #.....................................................................................................
      output.on 'end', =>
        # T.fail "not yet ready"
        T.eq unsquared_results, unsquared_matchers
        T.eq    output_results,    output_matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "stream_from_text" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input     = D.stream_from_text text
  count     = 0
  input
    .pipe $ ( data, send, end ) ->
      if data?
        T.eq data, text
        count += +1
      if end?
        T.eq count, 1
        end()
        done()
  input.resume()

#-----------------------------------------------------------------------------------------------------------
@[ "synchronous collect" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input   = D.stream_from_text text
  input   = input.pipe D.$split()
  result  = D.collect input
  input.resume()
  T.eq result, text.split '\n'
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "asynchronous collect" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input   = D.stream_from_text text
  #.........................................................................................................
  stream  = input
    .pipe D.$split()
    .pipe $async ( line, D_done ) => setTimeout ( => D_done line ), 200
  #.........................................................................................................
  D.collect stream, ( error, result ) =>
    T.eq result, text.split '\n'
    debug '©4D8tA', 'done'
    done()
  #.........................................................................................................
  input.resume()

# #-----------------------------------------------------------------------------------------------------------
# @[ "stream_from_text" ] = ( T, done ) ->
#   text = """
#     Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
#     codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
#     as five characters. Dictionaries will list 馬马 as 'one character with two variants’
#     and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
#     here.
#     """
#   input = D.stream_from_text text
#   input
#     .pipe D.$split()
#     .pipe D.$join '--\n'
#     .pipe D.$observe ( data ) -> urge data
#   input.resume()


############################################################################################################
@_main = ->
  settings = 'timeout': 2500
  test @, settings

@_main() unless module.parent?



