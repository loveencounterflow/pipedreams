

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
@[ "(v4) new_stream_from_pipeline (1a)" ] = ( T, done ) ->
  MSP                       = require 'mississippi'
  combine                   = require 'stream-combiner2'
  create_frob_tee           = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply        = $ ( data, send ) => whisper 'multiply', data; send data *  2
      add             = $ ( data, send ) => whisper 'add',      data; send data +  2
      square          = $ ( data, send ) => whisper 'square',   data; send data ** 2
      unsquared       = MSP.through.obj()
      #.....................................................................................................
      R               = source = MSP.through.obj()
      source          = R
      sink            = R
      R               = R.pipe multiply
      R               = R.pipe add
      R               = R.pipe unsquared
      R               = R.pipe square
      R[ 'source' ]   = source
      R[ 'sink'   ]   = R # square
      return R
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    output_matchers     = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    output_results      = []
    frob                = create_frob_tee()
    { source, sink, }   = frob
    #.......................................................................................................
    sink
      #.....................................................................................................
      .pipe $ ( data )        =>            help 'show #1', data
      .pipe $ ( data, send )  => send data; help 'show #2', data
      #.....................................................................................................
      .pipe $ ( data, send, end ) =>
        send data if data?
        if end?
          warn "pausing for a second"
          setTimeout end, 1000
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        output_results.push data
        send data
      #.....................................................................................................
      .pipe $ ( data, send, end ) =>
        send data if data?
        if end?
          help "output_results", output_results
          T.eq output_results, output_matchers
          end()
          done()
    #.......................................................................................................
    write_data_using_write = ->
      for n in probes
        urge 'write', n
        source.write n
      source.end()
    #.......................................................................................................
    write_data_using_push = ->
      for n in probes
        urge 'push', n
        source.push n
      source.push null
    #.......................................................................................................
    # write_data_using_write()
    write_data_using_push()
    #.......................................................................................................
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_pipeline (3)" ] = ( T, done ) ->
  MSP                       = require 'mississippi'
  create_frob_tee           = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.new_stream()
      #.....................................................................................................
      return D.new_stream pipeline: [ multiply, add, unsquared, square, ]
  #.........................................................................................................
  do ->
    probes              = [ 1 ... 10 ]
    matchers            = [ 16, 36, 64, 100, 144, 196, 256, 324, 400, ]
    results             = []
    frob                = create_frob_tee()
    #.......................................................................................................
    frob
      .pipe D.$show()
      #.....................................................................................................
      .pipe $ ( data, send ) =>
        results.push data
        send data
      #.....................................................................................................
      .pipe D.$on_end =>
        T.eq results, matchers
        done()
    #.......................................................................................................
    frob.write n for n in probes
    frob.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_pipeline (4)" ] = ( T, done ) ->
  probes      = [ 10 .. 20 ]
  matchers    = [20,22,24,26,28,30,32,34,36,38,40]
  results     = []
  pipeline    = [
    ( $ ( data, send ) => send n + 2 )
    ( $ ( data, send ) => send n * 2 )
    ]
  confluence  = D.new_stream pipeline: pipeline
  confluence
    .pipe D.$show()
    .pipe $ ( data, send, end ) =>
      if data?
        send data
        results.push data
      if end?
        T.eq results, matchers
        end()
        done()
  for n in probes
    confluence.write n
  confluence.end()
  #.........................................................................................................
  return null

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
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_text doesn't work synchronously" ] = ( T, done ) ->
  collector = []
  input     = D.new_stream()
  input
    .pipe D.$split()
    .pipe $ ( line, send ) =>
      send line
      collector.push line
  input.write "first line\nsecond line"
  input.end()
  T.eq collector, [ "first line", ]
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_text (2)" ] = ( T, done ) ->
  collector = []
  input     = D.new_stream()
  input
    .pipe D.$split()
    .pipe $ ( line, send ) =>
      send line
      collector.push line
    .pipe D.$on_end =>
      T.eq collector, [ "first line", "second line", ]
      done()
  input.write "first line\nsecond line"
  input.end()


#-----------------------------------------------------------------------------------------------------------
@[ "(v4) observer transform called with data `null` on stream end" ] = ( T, done ) ->
  received_null = no
  collector     = []
  input = D.new_stream()
  input
    .pipe $ ( data ) =>
        if data?
          collector.push data
        else
          if data is null
            T.fail "received null, shouldn't happen" if received_null
            received_null = yes
          else
            T.fail "received #{rpr data}, shouldn't happen"
    .pipe D.$on_end =>
      T.fail "expected to receive null in observer transform" unless received_null
      T.eq collector, [ "helo", "world", ]
      done()
  input.write "helo"
  input.write "world"
  input.end()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) README demo (1)" ] = ( T, done ) ->
  #.........................................................................................................
  $comment = ->
    count = 0
    return $ ( data ) =>
      if data?
        count += +1
        info "received event:", data
      else
        warn "stream has ended; read #{count} events"

  #.........................................................................................................
  $as_text_line = ->
    return $ ( data, send ) =>
      send "line: " + ( JSON.stringify data ) + '\n'

  #.........................................................................................................
  $summarize = ( title ) ->
    collector = []
    return $ ( data, send, end ) =>
      if data?
        send data
        collector.push ( JSON.stringify data )
      if end?
        collector.sort() # Just a demo; always use a custom sort method, kids!
        help title, collector.join ', '
        end()

  #.........................................................................................................
  $verify = ( title ) ->
    collector = []
    return $ ( data, send, end ) =>
      if data?
        send data
        collector.push ( JSON.stringify data )
      if end?
        T.eq collector, [ '"line: 4\\n"', '"line: 7\\n"', '"line: 9\\n"', '"line: 3\\n"', '"line: 5\\n"', '"line: 6\\n"' ]
        end()

  #.........................................................................................................
  input = D.new_stream()  # returns a `through2` stream
  input
    .pipe $comment()
    .pipe $ ( data ) => log CND.truth data?
    .pipe $summarize "position #1:"
    .pipe $as_text_line()
    .pipe D.$bridge process.stdout # bridge the stream, so data is passed through to next transform
    .pipe $verify()
    .pipe $summarize "position #2:"
    .pipe D.$on_end => done()

  #.........................................................................................................
  for n in [ 4, 7, 9, 3, 5, 6, ]
    input.write n
  input.end()

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
@[ "(v4) stream / transform construction with through2 (1)" ] = ( T, T_done ) ->
  FS          = require 'fs'
  PATH        = require 'path'
  MSP         = require 'mississippi'
  t2_settings = {}
  input       = FS.createReadStream PATH.resolve __dirname, '../package.json'
  #.........................................................................................................
  delay = ( name, f ) =>
    dt = CND.random_integer 100, 500
    # dt = 1
    whisper "delay for #{rpr name}: #{dt}ms"
    setTimeout f, dt
  #.........................................................................................................
  ### The main transform method accepts a line, takes it out of the stream unless it matches
  either `"name"` or `"version"`, trims it, and emits two events (formatted as lists) per remaining
  line. This method must be free (a.k.a. bound, using a slim arrow) so we can use `@push`. ###
  transform_main = ( line, encoding, handler ) ->
    throw new Error "unknown encoding #{rpr encoding}" unless encoding is 'utf8'
    return handler() unless ( /"(name|version)"/ ).test line
    line = line.trim()
    delay line, =>
      @push [ 'first-chr', ( Array.from line )[ 0 ], ]
      handler null, [ 'text', line, ]
  #.........................................................................................................
  ### The 'flush' transform is called once, right before the stream has ended; the callback must be called
  exactly once, and it's possible to put additional 'last-minute' data into the stream by calling `@push`.
  Because we have to access `this`/`@`, the method must again be free and not bound, but of course we
  can set up an alias for `@push`: ###
  transform_flush = ( done ) ->
    push = @push.bind @
    delay 'flush', =>
      push [ 'message', "ok", ]
      push [ 'message', "we're done", ]
      done()
  #.........................................................................................................
  input
    .pipe D.$split()
    # .pipe D.$observe ( line ) => whisper rpr line
    .pipe MSP.through.obj t2_settings, transform_main, transform_flush
    .pipe D.$show()
    .pipe D.$on_end => T_done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) stream / transform construction with through2 (2)" ] = ( T, T_done ) ->
  MSP         = require 'mississippi'
  t2_settings = {}
  S           = {}
  S.input     = MSP.through.obj()
  #.........................................................................................................
  db = CND.shuffle [
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
  delay = ( name, f ) =>
    dt = CND.random_integer 100, 500
    # dt = 1
    whisper "delay for #{rpr name}: #{dt}ms"
    setTimeout f, dt
  #.........................................................................................................
  read_one_phrase = ( glyph, handler ) =>
    delay glyph, =>
      for phrase in db
        [ sbj, prd, obj, ] = phrase
        continue unless sbj is glyph
        handler null, phrase
      handler null, null
  #.........................................................................................................
  $retrieve_data_from_db = ( S ) =>
    #.......................................................................................................
    main = ( glyph, encoding, handler ) ->
      push = @push.bind @
      push [ glyph, 'start', ]
      read_one_phrase glyph, ( error, phrase ) =>
        return handler error if error?
        return handler null, [ glyph, 'stop', ] unless phrase?
        push phrase
    #.......................................................................................................
    flush = ( done ) ->
      push = @push.bind @
      delay 'flush', =>
        push [ 'message', "ok", ]
        push [ 'message', "we're done", ]
        done()
    #.......................................................................................................
    return MSP.through.obj t2_settings, main, flush
  #.........................................................................................................
  $collect = ( S ) =>
    matchers  = new Set ( JSON.stringify phrase for phrase in db )
    collector = []
    #.......................................................................................................
    main = ( phrase, _, handler ) ->
      probe = JSON.stringify phrase
      [ sbj, prd, obj, ] = phrase
      unless ( prd in [ 'start', 'stop', ] ) or ( sbj is 'message' )
        T.ok matchers.has probe
        matchers.delete probe
      handler null, phrase
    #.......................................................................................................
    flush = ( handler ) ->
      T.eq matchers.size, 0
      handler()
    #.......................................................................................................
    return MSP.through.obj t2_settings, main, flush
  #.........................................................................................................
  S.input
    .pipe $retrieve_data_from_db  S
    .pipe $collect                S
    .pipe D.$show()
    .pipe D.$on_end => T_done()
  #.........................................................................................................
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
  test @, 'timeout': 3000


############################################################################################################
unless module.parent?
  include = [
    "(v4) new_stream_from_pipeline (1a)"
    "(v4) new_stream_from_pipeline (3)"
    "(v4) new_stream_from_pipeline (4)"
    "(v4) D.new_stream"
    "(v4) D.new_stream_from_pipeline"
    "(v4) stream / transform construction with through2 (1)"
    "(v4) stream / transform construction with through2 (2)"
    # # "(v4) $async with stream end detection"
    # # "(v4) $async with arbitrary number of results"
    "(v4) new_stream_from_text"
    "(v4) new_stream_from_text doesn't work synchronously"
    "(v4) new_stream_from_text (2)"
    "(v4) README demo (1)"
    "(v4) observer transform called with data `null` on stream end"
    ]
  @_prune()
  @_main()










