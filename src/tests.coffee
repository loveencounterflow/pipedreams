

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
#...........................................................................................................
### TAINT for the time being, we create one global folder and keep it beyond process termination; this
allows to inspect folder contents after tests have terminated. It would probably be a good idea to remove
the `keep: yes` setting at a later point in time. ###
TMP                       = require 'tmp'
TMP.setGracefulCleanup()
_temp_folder              = TMP.dirSync keep: yes, prefix: 'pipedreams-'
temp_home                 = _temp_folder[ 'name' ]
resolve_path              = ( require 'path' ).resolve
resolve_temp_path         = ( P... ) -> resolve_path temp_home, ( p.replace /^[.\/]/g, '' for p in P )...
# removeCallback
# debug resolve_temp_path 'foo.txt'
# debug resolve_temp_path '/foo.txt'

#===========================================================================================================
# TESTS
#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new new_stream signature (preview)" ] = ( T, done ) ->

  ############################################################################################################
  test_function_signature_def = ->

    #-----------------------------------------------------------------------------------------------------------
    @new_stream = ( P... ) ->
      #.........................................................................................................
      help() # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      help Array.from arguments # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      try # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        [ kind, seed, hints, settings, ] = @new_stream._read_arguments P # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        switch kind
          when '*plain'       then return @_new_stream                seed, hints, settings
          when 'file', 'path' then return @_new_stream_from_path      seed, hints, settings
          when 'pipeline'     then return @_new_stream_from_pipeline  seed, hints, settings
          when 'text'         then return @_new_stream_from_text      seed, hints, settings
          when 'url'          then return @_new_stream_from_url       seed, hints, settings
          else throw new Error "unknown kind #{rpr kind} (shouldn't happen)"
      catch error # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        warn error[ 'message' ] # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        return # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    #-----------------------------------------------------------------------------------------------------------
    @new_stream._read_arguments = ( P ) =>
      kind_and_seed = null
      settings      = null
      kind          = null
      seed          = null
      hints         = null
      #.........................................................................................................
      if P.length > 0
        if P.length > 1
          unless CND.isa_text P[ P.length - 1 ]
            kind_and_seed = P.pop()
        unless CND.isa_text P[ P.length - 1 ]
          settings  = kind_and_seed
          kind_and_seed = P.pop()
      #.........................................................................................................
      hints = P
      #.........................................................................................................
      unless kind_and_seed?
        kind = '*plain'
      else
        unless ( kind_count = ( Object.keys kind_and_seed ).length ) is 1
          throw new Error "expected 0 or 1 'kind', got #{kind_count}"
        break for kind, seed of kind_and_seed
      #.........................................................................................................
      unless CND.is_subset hints, @new_stream._hints
        expected  = ( rpr x for x in @new_stream._hints                                  ).join ', '
        got       = ( rpr x for x in              hints when x not in @new_stream._hints ).join ', '
        throw new Error "expected 'hints' out of #{expected}, got #{got}"
      #.........................................................................................................
      unless kind in @new_stream._kinds
        expected  = ( rpr x for x in @new_stream._kinds ).join ', '
        got       =   rpr kind
        throw new Error "expected a 'kind' out of #{expected}, got #{got}"
      #.........................................................................................................
      urge 'kind      ', kind
      urge 'seed      ', seed
      urge 'hints     ', hints
      urge 'settings  ', settings
      hints = null if hints.length is 0
      return [ kind, seed, hints, settings, ]

    #...........................................................................................................
    @new_stream._kinds = [ '*plain', 'file', 'path',    'pipeline', 'text',   'url',                       ]
    @new_stream._hints = [ 'utf-8',  'utf8', 'binary',  'read',     'write',  'append',                    ]

    #-----------------------------------------------------------------------------------------------------------
    @_new_stream = ( seed, hints, settings ) ->
      throw new Error "_new_stream doesn't accept 'seed', got #{rpr seed}" if seed?
      throw new Error "_new_stream doesn't accept 'hints', got #{rpr hints}" if hints?
      throw new Error "_new_stream doesn't accept 'settings', got #{rpr settings}" if settings?
      return MSP.through.obj()

    #-----------------------------------------------------------------------------------------------------------
    @_new_stream_from_path = ( seed, hints, settings ) -> throw new Error "_new_stream_from_path: not implemented"

    #-----------------------------------------------------------------------------------------------------------
    @_new_stream_from_pipeline = ( seed, hints, settings ) -> throw new Error "_new_stream_from_pipeline: not implemented"

    #-----------------------------------------------------------------------------------------------------------
    @_new_stream_from_text = ( seed, hints, settings ) ->
      ### Given a text, return a stream that has `text` written into it; as soon as you `.pipe` it to some
      other stream or transformer pipeline, those parts will get to read the text. Unlike PipeDreams v2, the
      returned stream will not have to been resumed explicitly. ###
      throw new Error "illegal argument 'hints': #{rpr hints}"        if hints?
      throw new Error "illegal argument 'settings': #{rpr settings}"  if settings?
      unless ( type = CND.type_of seed ) in [ 'text', 'buffer', ]
        throw new Error "expected text or buffer, got a #{type}"
      #.........................................................................................................
      R = @new_stream()
      R.write text
      R.end()
      return R

    #-----------------------------------------------------------------------------------------------------------
    @_new_stream_from_url = ( seed, hints, settings ) -> throw new Error "_new_stream_from_url: not implemented"


  #===========================================================================================================
  MSP                       = require 'mississippi'
  DEMO                      = {}
  test_function_signature_def.apply DEMO
  #.........................................................................................................
  debug DEMO.new_stream._kinds
  debug DEMO.new_stream._hints
  DEMO.new_stream()
  DEMO.new_stream 'utf-8'
  DEMO.new_stream 'write', 'binary', file: 'baz.doc'
  DEMO.new_stream 'write', pipeline: []
  DEMO.new_stream 'write', 'binary', { file: 'baz.doc', }, { mode: 0o744, }
  DEMO.new_stream text: "make it so"
  DEMO.new_stream 'oops', text: "make it so"
  DEMO.new_stream 'text', "make it so"
  DEMO.new_stream 'binary', 'append', "~/some-file.txt"
  DEMO.new_stream 'omg', 'append', file: "~/some-file.txt"
  DEMO.new_stream 'write', route: "~/some-file.txt"
  done()



### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new new_stream signature (1)" ] = ( T, done ) ->
  #.........................................................................................................
  new_stream_instrument = ( P... ) ->
    message   = null
    kind      = null
    seed      = null
    hints     = null
    settings  = null
    try
      [ kind, seed, hints, settings, ] = D.new_stream._read_arguments P
    catch error
      message = error[ 'message' ]
    return [ kind, seed, hints, settings, message, ]
  #.........................................................................................................
  probes = [
    # good
    [                                                             ]
    [ 'utf-8',                                                    ]
    [ 'write', 'binary', file: 'baz.doc',                         ]
    [ 'write', pipeline: [],                                      ]
    [ 'write', 'binary', { file: 'baz.doc', }, { mode: 0o744, },  ]
    [ text: "make it so",                                         ]
    # bad
    [ 'oops', text: "make it so",                                 ]
    [ 'text', "make it so",                                       ]
    [ 'binary', 'append', "~/some-file.txt",                      ]
    [ 'omg', 'append', file: "~/some-file.txt",                   ]
    [ 'write', route: "~/some-file.txt",                          ]
    ]
  #.........................................................................................................
  matchers = [
    # good
    ["*plain",null,null,null,null]
    ["*plain",null,["utf-8"],null,null]
    ["file","baz.doc",["write","binary"],null,null]
    ["pipeline",[],["write"],null,null]
    ["file","baz.doc",["write","binary"],{"mode":484},null]
    ["text","make it so",null,null,null]
    # bad
    [null,null,null,null,"expected 'hints' out of 'utf-8', 'utf8', 'binary', 'read', 'write', 'append', got 'oops'"]
    [null,null,null,null,"expected 'hints' out of 'utf-8', 'utf8', 'binary', 'read', 'write', 'append', got 'text', 'make it so'"]
    [null,null,null,null,"expected 'hints' out of 'utf-8', 'utf8', 'binary', 'read', 'write', 'append', got '~/some-file.txt'"]
    [null,null,null,null,"expected 'hints' out of 'utf-8', 'utf8', 'binary', 'read', 'write', 'append', got 'omg'"]
    [null,null,null,null,"expected a 'kind' out of '*plain', 'file', 'path', 'pipeline', 'text', 'url', got 'route'"]
    ]
  #.........................................................................................................
  for probe, probe_idx in probes
    result = new_stream_instrument probe...
    T.eq result, matchers[ probe_idx ]
  #.........................................................................................................
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new new_stream signature (2)" ] = ( T, done ) ->
  path_1 = resolve_temp_path 't-dfgh-1.txt'
  path_2 = resolve_temp_path 't-dfgh-2.txt'
  path_3 = resolve_temp_path 't-dfgh-3.txt'
  #.........................................................................................................
  new_stream_instrument = ( P... ) ->
    try
      R = D.new_stream P
    catch error
      message = error[ 'message' ]
    return [ R, message, ]
  #.........................................................................................................
  probes = [
    # good
    [                                                             ]
    [ pipeline: [],                                               ]
    [ 'write', 'binary',   file: path_1,                         ]
    [ 'write', 'binary', { file: path_2, }, { mode: 0o744, },  ]
    [ 'binary', 'append',  file: path_3,                      ]
    [ text: "make it so",                                         ]
    # bad
    [ 'utf-8',                                                    ]
    [ 'write', pipeline: [],                                      ]
    ]
  #.........................................................................................................
  matchers  = [
    [{"stream":true},null]
    [{"stream":true},null]
    [{"stream":true},null]
    [{"stream":true},null]
    [{"stream":true},null]
    [{"stream":true},null]
    [null,"_new_stream doesn't accept 'hints', got [ 'utf-8' ]"]
    [null,"_new_stream_from_pipeline doesn't accept 'hints', got [ 'write' ]"]
    ]
  ASTREAM   = { 'stream': yes, }
  #.........................................................................................................
  for probe, probe_idx in probes
    result      = new_stream_instrument probe...
    result[ 0 ] = ASTREAM if isa_stream result[ 0 ]
    debug JSON.stringify result
    # T.eq result, matchers[ probe_idx ]
  #.........................................................................................................
  done()

### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
### ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##   ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###
###          ## ## ##          ## ## ##          ## ## ##          ## ## ##          ## ## ##            ###


#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_pipeline (1a)" ] = ( T, done ) ->
  MSP                       = require 'mississippi'
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
@[ "(v4) _new_stream_from_pipeline (3)" ] = ( T, done ) ->
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
@[ "(v4) _new_stream_from_pipeline (4)" ] = ( T, done ) ->
  probes      = [ 10 .. 20 ]
  matchers    = [20,22,24,26,28,30,32,34,36,38,40]
  results     = []
  pipeline    = [
    ( $ ( data, send ) => send n + 2 )
    ( $ ( data, send ) => send n * 2 )
    ]
  confluence  = D.new_stream { pipeline, }
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
@[ "(v4) _new_stream_from_text" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  input     = D.new_stream { text, }
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
@[ "(v4) _new_stream_from_text doesn't work synchronously" ] = ( T, done ) ->
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
@[ "(v4) _new_stream_from_text (2)" ] = ( T, done ) ->
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
    # .pipe D.$bridge process.stdout # bridge the stream, so data is passed through to next transform
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
    dt = CND.random_integer 1, 100
    # dt = 1
    whisper "delay for #{rpr name}: #{dt}ms"
    setTimeout f, dt
  #.........................................................................................................
  read_phrases = ( glyph, handler ) =>
    delay glyph, =>
      for phrase in db
        [ sbj, prd, obj, ] = phrase
        continue unless sbj is glyph
        handler null, phrase
      handler null, null
  #.........................................................................................................
  $retrieve_data_from_db = ( S ) =>
    #.......................................................................................................
    main = ( glyph, encoding, callback ) ->
      push = @push.bind @
      push [ glyph, 'start', ]
      is_finished = no
      read_phrases glyph, ( error, phrase ) =>
        return callback error if error?
        return push phrase if phrase?
        push [ glyph, 'stop', ]
        callback() unless is_finished
        is_finished = yes
      return null
    #.......................................................................................................
    flush = ( callback ) ->
      push = @push.bind @
      # delay 'flush', =>
      push [ 'message', "ok", ]
      push [ 'message', "we're done", ]
      callback()
    #.......................................................................................................
    return MSP.through.obj t2_settings, main #, flush
  #.........................................................................................................
  $collect = ( S ) =>
    matchers  = new Set ( JSON.stringify phrase for phrase in db )
    collector = []
    #.......................................................................................................
    main = ( phrase, _, callback ) ->
      probe = JSON.stringify phrase
      [ sbj, prd, obj, ] = phrase
      unless ( prd in [ 'start', 'stop', ] ) or ( sbj is 'message' )
        T.ok matchers.has probe
        matchers.delete probe
      callback null, phrase
    #.......................................................................................................
    flush = ( callback ) ->
      T.eq matchers.size, 0
      callback()
    #.......................................................................................................
    return MSP.through.obj t2_settings, main, flush
  #.........................................................................................................
  $finalize = ( S ) =>
    #.......................................................................................................
    main = null
    #.......................................................................................................
    flush = ( callback ) ->
      help "that’s all"
      T_done()
      callback()
    #.......................................................................................................
    return MSP.through.obj t2_settings, main, flush
  #.........................................................................................................
  S.input
    .pipe $retrieve_data_from_db  S
    .pipe $collect                S
    .pipe D.$show()
    .pipe $finalize               S
    # .pipe D.$on_end => T_done()
  #.........................................................................................................
  ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
  ### TAINT this test causes a timeout for unknown reasons; postponing ###
  T.fail "test fails with timeout for unknown reasons"
  return T_done()
  ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
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
@[ "(v4) D._new_stream_from_pipeline" ] = ( T, done ) ->
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
  T.ok isa_stream stream = D.new_stream { pipeline, }
  stream.write 'foo'
  stream.write 'bar'
  stream.write 'baz'
  stream.end()

  # T.ok isa_stream D.new_stream_from_streams()
  # T.ok isa_stream D.new_file_readstream()
  # T.ok isa_stream D.new_file_readlinestream()
  # T.ok isa_stream D.new_file_writestream()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $async with method arity 2" ] = ( T, done ) ->
  #.........................................................................................................
  $calculate = => $async ( n, send ) =>
    delay "$calculate", =>
      send n - 1
      send n
      send n + 1
      send.done()
  #.........................................................................................................
  input = D.new_stream()
  # MSP   = require 'mississippi'
  #.........................................................................................................
  input
    # .pipe MSP.through.obj ( ( d, _, cb ) => help "data"; cb null, d ), ( ( cb ) => warn "over"; cb() )
    .pipe $calculate()
    .pipe D.$show()
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, [ 4, 5, 6, 14, 15, 16, 24, 25, 26, ] if data?
    .pipe D.$on_end => done()
  #.........................................................................................................
  D.send input, 5
  D.send input, 15
  D.send input, 25
  D.end input
  #.........................................................................................................
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $async with method arity 3" ] = ( T, done ) ->
  #.........................................................................................................
  $calculate = => $async ( n, send ) =>
    delay "$calculate", =>
      send n - 1
      send n
      send n + 1
      send.done()
  #.........................................................................................................
  $group = =>
    last_n        = null
    current_group = null
    return $async ( n, send, end ) =>
      delay "$group", =>
        if n?
          if last_n? and ( Math.abs n - last_n ) is 1
            current_group.push n
          else
            send current_group if current_group?
            current_group = [ n, ]
          last_n = n
        if end?
          send current_group if current_group?
          end()
        send.done()
  #.........................................................................................................
  input = D.new_stream()
  # MSP   = require 'mississippi'
  #.........................................................................................................
  input
    # .pipe MSP.through.obj ( ( d, _, cb ) => help "data"; cb null, d ), ( ( cb ) => warn "over"; cb() )
    .pipe $calculate()
    .pipe $group()
    .pipe D.$show()
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, [ [ 4, 5, 6, ], [ 14, 15, 16, ], [ 24, 25, 26, ], ] if data?
    .pipe D.$on_end => done()
  #.........................................................................................................
  D.send input, 5
  D.send input, 15
  D.send input, 25
  D.end input
  #.........................................................................................................
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 1" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$sort()
    .pipe D.$show()
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, [ 11, 23, 33, 55, 82, 98, 99, ] if data?
    .pipe D.$on_end => done()
  D.send input, n for n in [ 55, 82, 99, 23, 11, 98, 33, ]
  D.end input

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 2" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$sort()
    .pipe D.$show()
    .pipe D.$collect collect: yes
    .pipe $ ( data ) -> T.eq data, [ 11, 23, 33, 55, 82, 98, 99, ] if data?
    .pipe D.$on_end => done()
  D.send input, n for n in [ 55, 82, 99, 23, 11, 98, 33, ]
  D.end input

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 3" ] = ( T, done ) ->
  sorter = ( a, b ) =>
    return +1 if a < b
    return -1 if a > b
    return  0
  input = D.new_stream()
  input
    .pipe D.$sort sorter
    .pipe D.$show()
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, [ 99, 98, 82, 55, 33, 23, 11, ] if data?
    .pipe D.$on_end => done()
  D.send input, n for n in [ 55, 82, 99, 23, 11, 98, 33, ]
  D.end input

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 4" ] = ( T, done ) ->
  sorter = ( a, b ) =>
    return +1 if a < b
    return -1 if a > b
    return  0
  input = D.new_stream()
  input
    .pipe D.$sort sorter, collect: yes
    .pipe D.$show()
    .pipe $ ( data ) -> T.eq data, [ 99, 98, 82, 55, 33, 23, 11, ] if data?
    .pipe D.$on_end => done()
  D.send input, n for n in [ 55, 82, 99, 23, 11, 98, 33, ]
  D.end input

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $lockstep 1" ] = ( T, done ) ->
  input_1 = D.new_stream()
  input_2 = D.new_stream()
  input_1
    .pipe D.$lockstep input_2
    .pipe D.$collect()
    .pipe D.$show()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  # D.send input_1, word for word in "do re mi fa so la ti".split /\s+/
  matcher = [ [ '以', 'i' ],  [ '呂', 'ro' ], [ '波', 'ha' ], [ '耳', 'ni' ],
              [ '本', 'ho' ], [ '部', 'he' ], [ '止', 'to' ], ]
  D.send input_1, word for word in "以 呂 波 耳 本 部 止".split /\s+/
  D.send input_2, word for word in "i ro ha ni ho he to".split /\s+/
  D.end input_1
  D.end input_2
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $lockstep fails on streams of unequal lengths without fallback" ] = ( T, done ) ->
  f = =>
    input_1 = D.new_stream()
    input_2 = D.new_stream()
    input_1
      .pipe D.$lockstep input_2
      .pipe D.$collect()
      # .pipe D.$show()
    #   .pipe $ ( data ) -> T.eq data, matcher if data?
    #   .pipe D.$on_end => done()
    # # D.send input_1, word for word in "do re mi fa so la ti".split /\s+/
    # matcher = [ [ '以', 'i' ],  [ '呂', 'ro' ], [ '波', 'ha' ], [ '耳', 'ni' ],
    #             [ '本', 'ho' ], [ '部', 'he' ], [ '止', 'to' ] ]
    D.send input_1, word for word in "以 呂 波 耳 本 部 止 千".split /\s+/
    D.send input_2, word for word in "i ro ha ni ho he to".split /\s+/
    D.end input_1
    D.end input_2
  D.run f, ( error ) =>
    T.eq error[ 'message' ], "streams of unequal lengths and no fallback value given"
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $lockstep succeeds on streams of unequal lengths with fallback" ] = ( T, done ) ->
  input_1 = D.new_stream()
  input_2 = D.new_stream()
  input_1
    .pipe D.$lockstep input_2, fallback: null
    .pipe D.$collect()
    .pipe D.$show()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  matcher = [ [ '以', 'i' ],  [ '呂', 'ro' ], [ '波', 'ha' ], [ '耳', 'ni' ],
              [ '本', 'ho' ], [ '部', 'he' ], [ '止', 'to' ], [ '千', null ], ]
  D.send input_1, word for word in "以 呂 波 耳 本 部 止 千".split /\s+/
  D.send input_2, word for word in "i ro ha ni ho he to".split /\s+/
  D.end input_1
  D.end input_2
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $batch and $spread" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$batch 3
    .pipe D.$spread indexed: yes
    .pipe D.$collect()
    .pipe D.$show()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  matcher = [ [ 0, '以' ], [ 1, '呂' ], [ 2, '波' ], [ 0, '耳' ], [ 1, '本' ], [ 2, '部' ], [ 0, '止' ] ]
  D.send input, word for word in "以 呂 波 耳 本 部 止".split /\s+/
  D.end input
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $split_tsv (1)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split_tsv()
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  matcher = [
    ["a","text"]
    ["with","a number"]
    ["of","lines"]
    ["u-cjk/9e1f","鸟","⿴乌丶"]
    ["u-cjk/9e20","鸠","⿰九鸟"]
    ["u-cjk/9e21","鸡","⿰又鸟"]
    ["u-cjk/9e22","鸢","⿱弋鸟"]
    ["u-cjk/9e23","鸣","⿰口鸟"]
    ["u-cjk-xa/380b","㠋","(⿱山品亏)"]
    ["㠋","(⿱山口咢) # first field is empty"]
    ]
  text = []
  text.push "a\ttext"
  text.push "with\ta number"
  text.push "          "
  text.push "of\tlines\n"
  text.push ""
  text.push "\t\t# comment"
  text.push "u-cjk/9e1f\t鸟\t⿴乌丶"
  text.push "u-cjk/9e20\t鸠\t⿰九鸟"
  text.push "u-cjk/9e21\t鸡\t⿰又鸟"
  text.push "u-cjk/9e22\t鸢\t⿱弋鸟"
  text.push "u-cjk/9e23\t鸣\t⿰口鸟"
  text.push "u-cjk-xa/380b\t㠋\t(⿱山品亏)"
  text.push "\t㠋\t(⿱山口咢) # first field is empty"
  D.send input, text.join '\n'
  D.end input
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $split_tsv (2)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split_tsv first: 'split'
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  matcher = [
    ["u-cjk/9e1f","鸟","⿴乌丶"]
    ["u-cjk/9e20","鸠","⿰九鸟"]
    ["u-cjk/9e21","鸡","⿰又鸟 # this comment remains in output"]
    ["u-cjk/9e22","鸢","⿱弋鸟"]
    ["u-cjk-xa/380b","㠋","(⿱山品亏)"]
    ["","㠋","(⿱山口咢) # first field is empty"]
    ["u-cjk/9e23","鸣","⿰口鸟"]
    ]
  text = []
  text.push "# This is a comment"
  text.push "\t\t# two empty fields, comment"
  text.push "u-cjk/9e1f\t鸟\t⿴乌丶"
  text.push " "
  text.push "u-cjk/9e20\t鸠\t⿰九鸟"
  text.push "u-cjk/9e21\t鸡\t⿰又鸟 # this comment remains in output"
  text.push ""
  text.push "u-cjk/9e22\t鸢\t⿱弋鸟\t# this one will be removed"
  text.push "u-cjk-xa/380b\t㠋\t(⿱山品亏)"
  text.push "\t㠋\t(⿱山口咢) # first field is empty"
  text.push "u-cjk/9e23\t鸣\t⿰口鸟"
  D.send input, text.join '\n'
  D.end input
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $split_tsv (3)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split_tsv first: 'split', names: [ 'fncr', 'glyph', 'formula', ]
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  matcher = [
    {"fncr":"u-cjk/9e1f","glyph":"鸟","formula":"⿴乌丶"}
    {"fncr":"u-cjk/9e20","glyph":"鸠","formula":"⿰九鸟"}
    {"fncr":"u-cjk/9e21","glyph":"鸡","formula":"⿰又鸟 # this comment remains in output"}
    {"fncr":"u-cjk/9e22","glyph":"鸢","formula":"⿱弋鸟"}
    {"fncr":"u-cjk-xa/380b","glyph":"㠋","formula":"(⿱山品亏)"}
    {"fncr":"","glyph":"㠋","formula":"(⿱山口咢) # first field is empty"}
    {"fncr":"u-cjk/9e23","glyph":"鸣","formula":"⿰口鸟"}
    ]
  text = []
  text.push "# This is a comment"
  text.push "\t\t# two empty fields, comment"
  text.push "u-cjk/9e1f\t鸟\t⿴乌丶"
  text.push " "
  text.push "u-cjk/9e20\t鸠\t⿰九鸟"
  text.push "u-cjk/9e21\t鸡\t⿰又鸟 # this comment remains in output"
  text.push ""
  text.push "u-cjk/9e22\t鸢\t⿱弋鸟\t# this one will be removed"
  text.push "u-cjk-xa/380b\t㠋\t(⿱山品亏)"
  text.push "\t㠋\t(⿱山口咢) # first field is empty"
  text.push "u-cjk/9e23\t鸣\t⿰口鸟"
  D.send input, text.join '\n'
  D.end input
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $split_tsv (4)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split_tsv first: 'split', names: 'inline'
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
    .pipe D.$on_end => done()
  matcher = [
    {"fncr":"u-cjk/9e1f","glyph":"鸟","formula":"⿴乌丶"}
    {"fncr":"u-cjk/9e20","glyph":"鸠","formula":"⿰九鸟"}
    {"fncr":"u-cjk/9e21","glyph":"鸡","formula":"⿰又鸟 # this comment remains in output"}
    {"fncr":"u-cjk/9e22","glyph":"鸢","formula":"⿱弋鸟"}
    {"fncr":"u-cjk-xa/380b","glyph":"㠋","formula":"(⿱山品亏)"}
    {"fncr":"","glyph":"㠋","formula":"(⿱山口咢) # first field is empty"}
    {"fncr":"u-cjk/9e23","glyph":"鸣","formula":"⿰口鸟"}
    ]
  text = []
  text.push "# This is a comment"
  text.push "\t\t# two empty fields, comment"
  text.push "fncr\tglyph\tformula"
  text.push "u-cjk/9e1f\t鸟\t⿴乌丶"
  text.push " "
  text.push "u-cjk/9e20\t鸠\t⿰九鸟"
  text.push "u-cjk/9e21\t鸡\t⿰又鸟 # this comment remains in output"
  text.push ""
  text.push "u-cjk/9e22\t鸢\t⿱弋鸟\t# this one will be removed"
  text.push "u-cjk-xa/380b\t㠋\t(⿱山品亏)"
  text.push "\t㠋\t(⿱山口咢) # first field is empty"
  text.push "u-cjk/9e23\t鸣\t⿰口鸟"
  D.send input, text.join '\n'
  D.end input
  return null


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
delay = ( name, f ) =>
  dt = CND.random_integer 10, 200
  # dt = 1
  whisper "delay for #{rpr name}: #{dt}ms"
  setTimeout f, dt

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
  info "temporary files, if any, written to #{temp_home}"

############################################################################################################
unless module.parent?
  include = [
    # "(v4) stream / transform construction with through2 (2)"
    # "(v4) new new_stream signature (preview)"
    "(v4) new new_stream signature (1)"
    "(v4) new new_stream signature (2)"
    # "(v4) _new_stream_from_pipeline (1a)"
    # "(v4) _new_stream_from_pipeline (3)"
    # "(v4) _new_stream_from_pipeline (4)"
    # "(v4) _new_stream_from_text"
    # "(v4) _new_stream_from_text doesn't work synchronously"
    # "(v4) _new_stream_from_text (2)"
    # "(v4) observer transform called with data `null` on stream end"
    # "(v4) README demo (1)"
    # "(v4) D.new_stream"
    # "(v4) stream / transform construction with through2 (1)"
    # "(v4) D._new_stream_from_pipeline"
    # "(v4) $async with method arity 2"
    # "(v4) $async with method arity 3"
    # "(v4) $sort 1"
    # "(v4) $sort 2"
    # "(v4) $sort 3"
    # "(v4) $sort 4"
    # "(v4) $lockstep 1"
    # "(v4) $lockstep fails on streams of unequal lengths without fallback"
    # "(v4) $lockstep succeeds on streams of unequal lengths with fallback"
    # "(v4) $batch and $spread"
    # "(v4) $split_tsv (1)"
    # "(v4) $split_tsv (2)"
    # "(v4) $split_tsv (3)"
    # "(v4) $split_tsv (4)"
    ]
  @_prune()
  @_main()
  # debug '5562', JSON.stringify Object.keys D






