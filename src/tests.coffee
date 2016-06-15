

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
test                      = require 'guy-test'
D                         = require './main'
$                         = D.remit


#-----------------------------------------------------------------------------------------------------------
get_index = ( element, key ) -> if ( CND.isa_function key ) then key element else element[ key ]


#-----------------------------------------------------------------------------------------------------------
@[ "TEE.from_pipeline accepts missing settings argument" ] = ( T, done ) ->
  create_frob_tee = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      transforms    = [ multiply, add, unsquared, square, ]
      #.....................................................................................................
      return D.TEE.from_pipeline transforms
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    frob                = create_frob_tee()
    { input, output, }  = frob.tee
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
@[ "TEE.from_pipeline reflects extra settings" ] = ( T, done ) ->
  settings  =
    inputs:
      foo:    D.create_throughstream()
    bar:      []
    baz:      42
  pipeline  = [ D.$show(), ]
  frob      = D.TEE.from_pipeline pipeline, settings
  T.eq frob.tee[ 'inputs' ][ 'foo' ], settings[ 'inputs' ][ 'foo' ]
  T.eq frob.tee[ 'bar' ], settings[ 'bar' ]
  T.eq frob.tee[ 'baz' ], settings[ 'baz' ]
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "TEE.from_pipeline 1" ] = ( T, done ) ->
  create_frob_tee = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      inputs        = { add, }
      outputs       = { unsquared, }
      transforms    = [ multiply, add, unsquared, square, ]
      #.....................................................................................................
      return D.TEE.from_pipeline transforms, { inputs, outputs, }
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    unsquared_matchers  = [ 4, 6, 8, -8, 10, 12, 14, 16, 18, 20, ]
    unsquared_results   = []
    frob                = create_frob_tee()
    { input
      output
      inputs
      outputs }         = frob.tee
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
      .pipe D.$show()
      #.....................................................................................................
      output.on 'end', =>
        T.eq unsquared_results, unsquared_matchers
        T.eq    output_results,    output_matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "TEE.from_pipeline 2" ] = ( T, done ) ->
  create_frob_tee = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      inputs        = { add, }
      outputs       = { unsquared, }
      transforms    = [ multiply, add, unsquared, square, ]
      #.....................................................................................................
      return D.TEE.from_pipeline transforms, { inputs, outputs, }
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    matchers            = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    results             = []
    frob                = create_frob_tee()
    input               = D.create_throughstream()
    output              = D.create_throughstream()
    #.......................................................................................................
    input
      .pipe frob
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        results.push data
        send data
      #.....................................................................................................
      .pipe D.$show()
      .pipe output
      #.....................................................................................................
      .pipe D.$on_end =>
        T.eq results, matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "D.combine produces new stream from existing ones 1" ] = ( T, done ) ->
  probes      = [ 10 .. 20 ]
  matchers    = [20,22,24,26,28,30,32,34,36,38,40]
  results     = []
  input       = D.create_throughstream()
  output      = D.create_throughstream()
  confluence  = D.combine input, output
  input
    .pipe $ ( data, send ) => send n * 2
    .pipe $ ( data, send ) => results.push data; send data
    .pipe D.$show()
  for n in probes
    input.write n
  input.end()
  # debug '©ΧΞΩΞΒ', JSON.stringify results
  T.eq results, matchers
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "D.combine produces new stream from existing ones 2" ] = ( T, done ) ->
  probes      = [ 10 .. 20 ]
  matchers    = [20,22,24,26,28,30,32,34,36,38,40]
  results     = []
  input       = D.create_throughstream()
  # output      = D.create_throughstream()
  transforms = [
    ( $ ( data, send ) => send n + 2 )
    ( $ ( data, send ) => send n * 2 )
    ]
  confluence  = D.combine input, transforms...
  confluence
    .pipe $ ( data, send ) => results.push data; send data
    .pipe D.$show()
  for n in probes
    input.write n
  input.end()
  # debug '©ΧΞΩΞΒ', JSON.stringify results
  T.eq results, matchers
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "TEE.from_readwritestreams 1" ] = ( T, done ) ->
  create_frob_tee       = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
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
      return D.TEE.from_readwritestreams readstream, writestream, { inputs, outputs, }
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    unsquared_matchers  = [ 4, 6, 8, -8, 10, 12, 14, 16, 18, 20, ]
    unsquared_results   = []
    frob                = create_frob_tee()
    { input
      output
      inputs
      outputs }         = frob.tee
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
@[ "TEE.from_readwritestreams 2" ] = ( T, done ) ->
  create_frob_tee       = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
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
      return D.TEE.from_readwritestreams readstream, writestream, { inputs, outputs, }
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    matchers            = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    results             = []
    frob                = create_frob_tee()
    input               = D.create_throughstream()
    #.......................................................................................................
    input
      .pipe frob
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        results.push data
        send data
      #.....................................................................................................
      .pipe D.$show()
      #.....................................................................................................
      .pipe D.$on_end =>
        # T.fail "not yet ready"
        T.eq results, matchers
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
@[ "asynchronous collect" ] = ( T, T_done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input   = D.stream_from_text text
  stream  = input
    .pipe D.$split()
    .pipe D.$async ( line, send ) => setTimeout ( => send.done line ), 200
  #.........................................................................................................
  D.collect stream, ( error, result ) =>
    T.eq result, text.split '\n'
    debug '©4D8tA', 'T_done'
    T_done()
  #.........................................................................................................
  input.resume()

# #-----------------------------------------------------------------------------------------------------------
# @[ "$async with stream end detection" ] = ( T, T_done ) ->
#   ###
#   input   = D.create_throughstream()
#   #.........................................................................................................
#   D.remit_async_v2 = ( method ) ->
#     pipeline = [
#       ]
#   $async_v2 = D.remit_async_v2.bind D
#   #.........................................................................................................
#   input
#     .pipe $async_v2 ( n, done, end ) =>
#       if n?
#         return "item ##{n}" if ( n / 2 ) is parseInt ( n / 2 ), 10
#       if end?
#         send "That's all, folks"
#         setTimeout ( => end() ), 200
#     .pipe D.$show()
#     .pipe D.$on_end => T_done()
#   #.........................................................................................................
#   for n in [ 0 .. 10 ]
#     input.write n
#   input.end()
#   #.........................................................................................................
#   return null
#   ###
#   delay   = ( t, f ) => setTimeout f, t
#   input   = D.create_throughstream()
#   #.........................................................................................................
#   input
#     .pipe D.remit_async_spread ( n, send ) =>
#       return send.done "item ##{n}" if ( n / 2 ) is parseInt ( n / 2 ), 10
#       delay 200, =>
#         send "an odd number: #{n}"
#         send.done "item ##{n}"
#     .pipe D.$show()
#     .pipe D.$on_end => T_done()
#   #.........................................................................................................
#   for n in [ 0 .. 10 ]
#     input.write n
#   input.end()
#   #.........................................................................................................
#   return null


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 2500

############################################################################################################
unless module.parent?
  include = [
    "TEE.from_pipeline accepts missing settings argument"
    "TEE.from_pipeline reflects extra settings"
    "TEE.from_pipeline 1"
    "TEE.from_pipeline 2"
    "D.combine produces new stream from existing ones 1"
    "D.combine produces new stream from existing ones 2"
    "TEE.from_readwritestreams 1"
    "TEE.from_readwritestreams 2"
    "stream_from_text"
    "synchronous collect"
    "asynchronous collect"
    # "$async with stream end detection"
    ]
  # @_prune()
  @_main()




