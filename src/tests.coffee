

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'PIPEDREAMS/tests'
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
{ $, $async, }            = D


#===========================================================================================================
# TESTS
#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_pipeline (1)" ] = ( T, done ) ->
  #.........................................................................................................
  create_frob_tee = ( settings ) ->
    multiply      = $ ( data, send ) => send data * 2
    add           = $ ( data, send ) => send data + 2
    square        = $ ( data, send ) => send data ** 2
    unsquared     = D.create_throughstream()
    #.....................................................................................................
    return D.new_stream_from_pipeline [ multiply, add, unsquared, square, ]
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    frob                = create_frob_tee()
    { input, output, }  = frob
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
@[ "(v4) new_stream_from_pipeline (2)" ] = ( T, done ) ->
  create_frob_tee = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply        = $ ( data, send ) => send data * 2
      add             = $ ( data, send ) => send data + 2
      square          = $ ( data, send ) => send data ** 2
      unsquared       = D.create_throughstream()
      #.....................................................................................................
      R = D.new_stream_from_pipeline [ multiply, add, unsquared, square, ]
      R[ 'inputs'  ]  = { add, }
      R[ 'outputs' ]  = { unsquared, }
      return R
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
      outputs }         = frob
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
@[ "(v4) new_stream_from_pipeline (3)" ] = ( T, done ) ->
  create_frob_tee = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.....................................................................................................
      return D.new_stream_from_pipeline [ multiply, add, unsquared, square, ]
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
      # .pipe D.$show()
      .pipe output
      #.....................................................................................................
      .pipe D.$on_end =>
        T.eq results, matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_pipeline using existing streams" ] = ( T, done ) ->
  probes      = [ 10 .. 20 ]
  matchers    = [20,22,24,26,28,30,32,34,36,38,40]
  results     = []
  input       = D.create_throughstream()
  transforms = [
    ( $ ( data, send ) => send n + 2 )
    ( $ ( data, send ) => send n * 2 )
    ]
  confluence  = D.new_stream pipeline: [ input, transforms..., ]
  confluence
    .pipe $ ( data, send ) => results.push data; send data
    # .pipe D.$show()
  for n in probes
    input.write n
  input.end()
  # debug '©ΧΞΩΞΒ', JSON.stringify results
  T.eq results, matchers
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_text" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input     = D.new_stream_from_text text
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
@[ "(v4) synchronous collect" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input   = D.new_stream_from_text text
  input   = input.pipe D.$split()
  result  = D.collect input
  input.resume()
  T.eq result, text.split '\n'
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) asynchronous collect" ] = ( T, T_done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input   = D.new_stream_from_text text
  stream  = input
    .pipe D.$split()
    .pipe $async ( line, send, end ) =>
      debug '1121', ( CND.truth line? ), ( CND.truth send.end? ), ( CND.truth end? )
      if line?
        setTimeout ( => send line ), 200
      if end?
        urge 'text completed'
        send.done "\ntext completed."
        end()
  #.........................................................................................................
  D.collect stream, ( error, result ) =>
    T.eq result, ( text.split '\n' ) + "\ntext completed."
    debug '©4D8tA', 'T_done'
    T_done()
  #.........................................................................................................
  input.resume()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) asynchronous DB-like" ] = ( T, T_done ) ->
  db = [
    [ '千', 'variant',     '仟',                         ]
    [ '千', 'variant',     '韆',                         ]
    [ '千', 'similarity',  '于',                         ]
    [ '千', 'similarity',  '干',                         ]
    [ '千', 'usagecode',   'CJKTHM',                    ]
    [ '千', 'strokeorder', '312',                       ]
    [ '千', 'reading',     'qian',                      ]
    [ '千', 'reading',     'foo',                       ]
    [ '千', 'reading',     'bar',                       ]
    [ '仟', 'strokeorder', '32312',                     ]
    [ '仟', 'usagecode',   'CJKTHm',                    ]
    [ '仟', 'reading',     'qian',                      ]
    [ '韆', 'strokeorder', '122125112125221134515454',  ]
    [ '韆', 'usagecode',   'KTHm',                      ]
    [ '韆', 'reading',     'qian',                      ]
    ]
  #.........................................................................................................
  delay = ( f ) => setTimeout f, CND.random_integer 100, 800
  #.........................................................................................................
  read_facets = ( glyph, handler ) =>
    delay =>
      for record in CND.shuffle db
        [ sbj, prd, obj, ] = record
        continue unless sbj is glyph
        urge '1'; handler null, { value: record, done: no, }
      urge '2'; handler null, { value: null, done: yes, }
  #.........................................................................................................
  input = D.new_stream()
  input
    #.......................................................................................................
    .pipe D.$show "before:"
    #.......................................................................................................
    .pipe $async ( glyph, send ) =>
      read_facets glyph, ( error, event ) =>
        throw error if error?
        urge '7765', event
        { value, done, } = event
        send value if value?
        debug '4431', value
        send.done() if done
    #.......................................................................................................
    .pipe D.$show "after: "
    #.......................................................................................................
    .pipe do =>
      collector = []
      return $ ( data, send, end ) =>
        collector.push data if data?
        debug '4432', collector
        if end?
          # T.eq collector, [ 'foo', 'bar', 'baz', ]
          delay =>
            # end()
            # T_done()
  #.........................................................................................................
  for glyph in Array.from '千仟韆國'
    input.write glyph
  input.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) asynchronous (using ES.map)" ] = ( T, T_done ) ->
  db = [
    [ '千', 'strokeorder', '312',                       ]
    [ '仟', 'strokeorder', '32312',                     ]
    [ '韆', 'strokeorder', '122125112125221134515454',  ]
    ]
  #.........................................................................................................
  delay = ( glyph, f ) =>
    dt = CND.random_integer 1, 1500
    # dt = 1
    whisper "delay for #{glyph}: #{dt}ms"
    setTimeout f, dt
  #.........................................................................................................
  read_one_phrase = ( glyph, handler ) =>
    delay glyph, =>
      for phrase in db
        [ sbj, prd, obj, ] = phrase
        continue unless sbj is glyph
        return handler null, phrase
      handler null, null
  #.........................................................................................................
  $detect_stream_end = ( S ) =>
    return $ ( data, send, end ) =>
      if data?
        send data
      if end?
        warn "$detect_stream_end detected end of stream at count #{S.count}"
        S.end_stream = end
  #.........................................................................................................
  $client_method_called_here = ( S ) =>
    return D._ES.map ( glyph, handler ) =>
      debug '7762', S.input.readable
      S.count += +1
      read_one_phrase glyph, ( error, phrase ) =>
        return handler error if error?
        info ( S.count ), ( CND.truth S.end_stream? )
        S.count += -1
        urge '7765', phrase
        handler null, phrase if phrase?
        handler()
  #.........................................................................................................
  $foo = ( S ) =>
    if S.end_stream? and S.count <= 0
      S.end_stream()
      T_done()
  #.........................................................................................................
  $collect_results = ( S ) =>
    collector = []
    return $ ( data, send ) =>
      info '7764', '$collect_results', ( CND.truth data? )
      if data?
        collector.push data
        help '7765 $collect_results data:', data
  #.........................................................................................................
  S             = {}
  S.count       = 0
  S.end_stream  = null
  # S.input       = D.new_stream_from_pipeline [
  #   $detect_stream_end          S
  #   $client_method_called_here  S
  #   $collect_results            S ]
  S.input       = D.new_stream()
  S.input
    # .pipe ( $detect_stream_end          S ) #, { end: false, }
    .pipe ( $client_method_called_here  S ) #, { end: false, }
    .pipe ( $collect_results            S )
  #.........................................................................................................
  # for glyph in CND.shuffle Array.from '千仟韆國'
  for glyph in Array.from '千仟韆'
    S.input.write glyph
  S.input.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) D.new_stream" ] = ( T, done ) ->
  T.ok isa_stream stream = D.new_stream()
  stream
    # .pipe D.$show()
    .pipe do =>
      collector = []
      $ ( data, send, end ) =>
        collector.push data if data?
        if end?
          T.eq collector, [ 'foo', 'bar', 'baz', ]
          end()
          done()
  stream.write 'foo'
  stream.write 'bar'
  stream.write 'baz'
  stream.end()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) stream / transform construction with through2" ] = ( T, T_done ) ->
  FS        = require 'fs'
  PATH      = require 'path'
  through2  = require 'through2'
  ###
  ```
  through2([ options, ] [ transformFunction ] [, flushFunction ])
  ```

  ```

  > To queue a new chunk, call `this.push(chunk)`—this can be called as many
  > times as required before the `callback()` if you have multiple pieces to
  > send on.

  > Alternatively, you may use `callback(err, chunk)` as shorthand for emitting
  > a single chunk or an error.

  > The optional `flushFunction` is provided as the last argument (2nd or 3rd,
  > depending on whether you've supplied `options`) is called just prior to the
  > stream ending. Can be used to finish up any processing that may be in
  > progress.

  ```

  ###
  t2_settings = {}
  input       = FS.createReadStream PATH.resolve __dirname, '../package.json'
  #.........................................................................................................
  delay = ( name, f ) =>
    dt = CND.random_integer 1, 1500
    # dt = 1
    whisper "delay for #{rpr name}: #{dt}ms"
    setTimeout f, dt
  #.........................................................................................................
  ### must not be a bound method b/c of `@push` ###
  transform_main = ( line, encoding, handler ) ->
    return handler() unless ( /"(name|version)"/ ).test line
    line.trim()
    delay line, =>
      @push [ 'first-chr', ( Array.from line )[ 0 ], ]
      handler null, [ 'text', line, ]
  #.........................................................................................................
  ### must not be a bound method b/c of `@push` ###
  transform_flush = ( done ) -> # ( line, encoding, handler ) ->
    push = @push.bind @
    delay 'flush', =>
      push [ 'message', "ok", ]
      push [ 'message', "we're done", ]
      done()
  #.........................................................................................................
  input
    .pipe D.$split()
    # .pipe D.$observe ( line ) => whisper rpr line
    .pipe through2.obj t2_settings, transform_main, transform_flush
    .pipe D.$show()
    .pipe D.$on_end => T_done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) asynchronous (using ES.map, stream-combiner2)" ] = ( T, T_done ) ->
  combine2  = require 'stream-combiner2'
  through2  = require 'through2'
  #.........................................................................................................
  db = [
    [ '千', 'strokeorder', '312',                       ]
    [ '仟', 'strokeorder', '32312',                     ]
    [ '韆', 'strokeorder', '122125112125221134515454',  ]
    ]
  #.........................................................................................................
  delay = ( glyph, f ) =>
    # dt = CND.random_integer 1, 1500
    dt = 1
    whisper "delay for #{glyph}: #{dt}ms"
    setTimeout f, dt
  #.........................................................................................................
  read_one_phrase = ( glyph, handler ) =>
    delay glyph, =>
      for phrase in db
        [ sbj, prd, obj, ] = phrase
        continue unless sbj is glyph
        return handler null, phrase
      handler null, null
  #.........................................................................................................
  $detect_stream_end = ( S ) =>
    return $ ( data, send, end ) =>
      if data?
        send data
      if end?
        warn "$detect_stream_end detected end of stream at count #{S.count}"
        S.end_stream = end
  #.........................................................................................................
  $client_method_called_here = ( S ) =>
    return D._ES.map ( glyph, handler ) =>
      debug '7762', S.input.readable
      S.count += +1
      read_one_phrase glyph, ( error, phrase ) =>
        return handler error if error?
        info ( S.count ), ( CND.truth S.end_stream? )
        S.count += -1
        urge '7765', phrase
        handler null, phrase if phrase?
        handler()
  #.........................................................................................................
  $foo = ( S ) =>
    if S.end_stream? and S.count <= 0
      S.end_stream()
      T_done()
  #.........................................................................................................
  $collect_results = ( S ) =>
    collector = []
    return $ ( data, send ) =>
      info '7764', '$collect_results', ( CND.truth data? )
      if data?
        collector.push data
        help '7765 $collect_results data:', data
  #.........................................................................................................
  S             = {}
  S.count       = 0
  S.end_stream  = null
  # S.input       = D.new_stream_from_pipeline [
  #   $detect_stream_end          S
  #   $client_method_called_here  S
  #   $collect_results            S ]
  S.input       = D.new_stream()
  S.input
    # .pipe ( $detect_stream_end          S ) #, { end: false, }
    .pipe ( $client_method_called_here  S ) #, { end: false, }
    .pipe ( $collect_results            S )
  #.........................................................................................................
  # for glyph in CND.shuffle Array.from '千仟韆國'
  for glyph in Array.from '千仟韆'
    S.input.write glyph
  S.input.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) D.new_stream" ] = ( T, done ) ->
  T.ok isa_stream stream = D.new_stream()
  stream
    # .pipe D.$show()
    .pipe do =>
      collector = []
      $ ( data, send, end ) =>
        collector.push data if data?
        if end?
          T.eq collector, [ 'foo', 'bar', 'baz', ]
          end()
          done()
  stream.write 'foo'
  stream.write 'bar'
  stream.write 'baz'
  stream.end()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) D.new_stream_from_pipeline" ] = ( T, done ) ->
  pipeline = [
    # D.$show()
    do =>
      collector = []
      return $ ( data, send, end ) =>
        collector.push data if data?
        if end?
          T.eq collector, [ 'foo', 'bar', 'baz', ]
          end()
          done()
    ]
  T.ok isa_stream stream = D.new_stream_from_pipeline pipeline
  stream.write 'foo'
  stream.write 'bar'
  stream.write 'baz'
  stream.end()

  # T.ok isa_stream D.new_stream_from_streams()
  # T.ok isa_stream D.new_file_readstream()
  # T.ok isa_stream D.new_file_readlinestream()
  # T.ok isa_stream D.new_file_writestream()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $async with stream end detection" ] = ( T, done ) ->
  throw new Error "not implemented"

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $async with arbitrary number of results" ] = ( T, done ) ->
  throw new Error "not implemented"


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
get_index = ( element, key ) -> if ( CND.isa_function key ) then key element else element[ key ]

#-----------------------------------------------------------------------------------------------------------
isa_stream = ( x ) -> x instanceof ( require 'stream' ).Stream

#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 30000


############################################################################################################
unless module.parent?
  include = [
    # "(v4) new_stream_from_pipeline (1)"
    # "(v4) new_stream_from_pipeline (2)"
    # "(v4) new_stream_from_pipeline (3)"
    # "(v4) new_stream_from_pipeline using existing streams"
    # "(v4) new_stream_from_text"
    # "(v4) synchronous collect"
    # "(v4) asynchronous collect"
    # "(v4) D.new_stream"
    # "(v4) D.new_stream_from_pipeline"
    # "(v4) asynchronous DB-like"
    # "(v4) asynchronous (using ES.map)"
    "(v4) stream / transform construction with through2"
    # "(v4) asynchronous (using ES.map, stream-combiner2)"
    # "(v4) $async with stream end detection"
    # "(v4) $async with arbitrary number of results"
    ]
  @_prune()
  @_main()



