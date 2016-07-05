

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
require './plugin-split-tsv'

#...........................................................................................................
### TAINT for the time being, we create one global folder and keep it beyond process termination; this
allows to inspect folder contents after tests have terminated. It would probably be a good idea to remove
the `keep: yes` setting at a later point in time. ###
TMP                       = require 'tmp'
TMP.setGracefulCleanup()
# _temp_thing               = TMP.dirSync keep: yes, unsafeCleanup: no, prefix: 'pipedreams-'
_temp_thing               = TMP.dirSync keep: no, unsafeCleanup: yes, prefix: 'pipedreams-'
temp_home                 = _temp_thing[ 'name' ]
resolve_path              = ( require 'path' ).resolve
resolve_temp_path         = ( P... ) -> resolve_path temp_home, ( p.replace /^[.\/]/g, '' for p in P )...
# removeCallback
# debug resolve_temp_path 'foo.txt'
# debug resolve_temp_path '/foo.txt'

#===========================================================================================================
# TESTS
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
    [ 'oops', text: "make it so",                                 ]
    [ 'text', "make it so",                                       ]
    [ 'binary', 'append', "~/some-file.txt",                      ]
    [ 'omg', 'append', file: "~/some-file.txt",                   ]
    # bad
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
    ["text","make it so",["oops"],null,null]
    ["*plain",null,["text","make it so"],null,null]
    ["*plain",null,["binary","append","~/some-file.txt"],null,null]
    ["file","~/some-file.txt",["omg","append"],null,null]
    # bad
    [null,null,null,null,"expected a 'kind' out of '*plain', 'file', 'path', 'pipeline', 'text', 'url', 'transform', got 'route'"]
    ]
  #.........................................................................................................
  for probe, probe_idx in probes
    result = new_stream_instrument probe...
    # debug JSON.stringify result
    T.eq result, matchers[ probe_idx ]
  #.........................................................................................................
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new new_stream signature (2)" ] = ( T, done ) ->
  path_1      = resolve_temp_path 't-dfgh-1.txt'
  path_2      = resolve_temp_path 't-dfgh-2.txt'
  path_3      = resolve_temp_path 't-dfgh-3.txt'
  fakestream  = { 'stream': yes, }
  #.........................................................................................................
  new_stream_instrument = ( P... ) ->
    R       = null
    message = null
    try
      R = D.new_stream P...
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
    [ 'oops', text: "make it so",                                 ]
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
    [null,"_new_stream_from_text doesn't accept 'hints', got [ 'oops' ]"]
    [null,"_new_stream doesn't accept 'hints', got [ 'utf-8' ]"]
    [null,"_new_stream_from_pipeline doesn't accept 'hints', got [ 'write' ]"]
    ]
  #.........................................................................................................
  for probe, probe_idx in probes
    result      = new_stream_instrument probe...
    result[ 0 ] = fakestream if isa_stream result[ 0 ]
    # debug JSON.stringify result
    T.eq result, matchers[ probe_idx ]
  #.........................................................................................................
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path (1)" ] = ( T, done ) ->
  step        = ( require 'coffeenode-suspend' ).step
  path_1      = resolve_temp_path '_new_stream_from_path-1.txt'
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  matcher     = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = D.new_stream 'write', 'lines', path: path_1
    D.on_finish output, handler
    input
      # .pipe $ ( line, send ) => send line + '\n'
      .pipe output
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    input   = D.new_stream 'read', 'lines', path: path_1
    D.on_finish input, handler
    input
      .pipe D.$collect()
      # .pipe D.$show()
      .pipe $ ( lines ) => T.eq lines, matcher if lines?
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample  resume
    yield read_sample   resume
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path (2)" ] = ( T, done ) ->
  step        = ( require 'coffeenode-suspend' ).step
  path_1      = resolve_temp_path '_new_stream_from_path-2.txt'
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  matcher     = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = ( require 'fs' ).createWriteStream path_1
    D.on_finish output, handler
    input
      .pipe D.$show()
      .pipe D.$as_line()
      .pipe D.$bridge output
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    input   = D.new_stream 'read', 'lines', path: path_1
    D.on_finish input, handler
    input
      .pipe D.$collect()
      # .pipe D.$show()
      .pipe $ ( lines ) => T.eq lines, matcher if lines?
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample  resume
    yield read_sample   resume
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) transforms below output receive data events (1)" ] = ( T, done ) ->
  path_1      = resolve_temp_path '(v4) transforms below output receive data events.txt'
  probes      = [ 'line-1', 'line-2', 23, 56, ]
  matcher     = [ 'line-1\n', 'line-2\n', '23\n', '56\n', ]
  #.........................................................................................................
  $verify = =>
    idx = -1
    return $ ( data ) =>
      if data?
        idx += +1
        T.eq data, matcher[ idx ]
      else
        T.eq idx + 1, matcher.length
      return null
  #.........................................................................................................
  input   = D.new_stream()
  output  = D.new_stream 'write', file: path_1
  input
    .pipe D.$show()
    .pipe D.$as_line()
    .pipe output
    .pipe D.$show()
    .pipe $verify()
  D.on_finish output, => help 'done'; done()
  #.......................................................................................................
  for probe in probes
    do ( probe ) =>
      setImmediate => D.send input, probe
  setImmediate => D.end input
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) transforms below output receive data events (2)" ] = ( T, done ) ->
  path    = ( require 'path' ).resolve __dirname, '../test-data/shape-breakdowwn-formula.txt'
  input   = D.new_stream { path, }
  sink_1  = D.new_stream 'devnull'
  sink_2  = D.new_stream 'devnull'
  D.on_finish sink_2, done
  #.........................................................................................................
  $verify = =>
    count = 0
    return $ ( entry ) =>
      if entry? then  count += +1
      else            T.eq count, 23
      return null
  #.........................................................................................................
  input
    .pipe D.$split_tsv names: 'inline'
    .pipe sink_1
    .pipe $verify()
    .pipe sink_2
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path (3)" ] = ( T, done ) ->
  @[ "_(v4) _new_stream_from_path (3) (outer)" ] ( error, Z ) =>
    throw error if error?
    [ n, failures, ] = Z
    if ( count = failures.length ) is 0
      T.ok true
    else
      T.fail """failed in #{count} out of #{n} cases:
        #{ (JSON.stringify r) + '\n' for r in failures }"""
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "_(v4) _new_stream_from_path (3) (outer)" ] = ( handler ) ->
  ASYNC       = require 'async'
  tasks       = []
  failures    = []
  n           = 100
  #.........................................................................................................
  for idx in [ 0 ... n ]
    do ( idx ) =>
      tasks.push ( done ) =>
        probes = [ 'helo', 'world', "run ##{idx}" ]
        @[ "_(v4) _new_stream_from_path (3) (inner)" ] idx, probes, ( error, result ) =>
          if error?
            failures.push error[ 'message' ]
          else
            failures.push result unless CND.equals result, probes
          done()
  #.........................................................................................................
  ASYNC.parallelLimit tasks, 10, =>
    urge "done"
    handler null, [ n, failures, ]
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "_(v4) _new_stream_from_path (3) (inner)" ] = ( idx, probes, handler ) ->
  step        = ( require 'coffeenode-suspend' ).step
  path_1      = resolve_temp_path "_new_stream_from_path-3-#{idx}.txt"
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = D.new_stream 'write', 'lines', { file: path_1, }
    D.on_finish output, handler
    input
      .pipe output
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    try
      input   = D.new_stream 'read', 'lines', path: path_1
    catch error
      return handler error
    input
      .pipe D.$collect()
      # .pipe D.$show()
      .pipe do =>
        result = null
        return $ ( lines ) =>
          if lines? then result = lines
          else handler null, result
  #.........................................................................................................
  step ( resume ) =>
    yield           write_sample  resume
    result = yield  read_sample   resume
    handler null, result
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path (4)" ] = ( T, done ) ->
  step        = ( require 'coffeenode-suspend' ).step
  path_1      = resolve_temp_path '_new_stream_from_path-4.txt'
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  matcher     = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = ( require 'fs' ).createWriteStream path_1, { flags: 'a', }
    input
      .pipe D.$as_line()
      .pipe D.new_stream pipeline: [ ( D.$bridge output ), D.$show(), ]
    D.on_finish output, handler
    # output.on 'finish', => setImmediate => handler()
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    input   = D.new_stream 'read', 'lines', path: path_1
    D.on_finish input, handler
    input
      .pipe D.$collect()
      # .pipe D.$show()
      .pipe $ ( lines ) => T.eq lines, matcher if lines?
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample  resume
    yield read_sample   resume
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) file stream events (1)" ] = ( T, done ) ->
  path_1      = resolve_temp_path '(v4) file stream events (1).txt'
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    thruput = D.new_stream()
    output  = D.new_stream 'append', file: path_1
    pipeline = input
      .pipe $ ( data ) => info '1', data; debug CND.green 'transform 1 end' unless data?
      .pipe output
      .pipe thruput
      .pipe $ ( data ) => info '2', data; debug CND.green 'transform 2 end' unless data?
    input.on    'end',    => debug CND.lime 'input end'
    input.on    'finish', => debug CND.lime 'input finish'
    output.on   'end',    => debug CND.red  'output end'
    output.on   'finish', => debug CND.red  'output finish'
    thruput.on  'end',    => debug CND.gold 'thruput end'
    thruput.on  'finish', => debug CND.gold 'thruput finish'
    pipeline.on 'end',    => debug CND.blue 'pipeline end'
    pipeline.on 'finish', => debug CND.blue 'pipeline finish'
    output.on   'finish', => setImmediate => debug CND.white 'over'; handler()
    #.......................................................................................................
    for probe in probes
      do ( probe ) =>
        setImmediate => input.write probe
    setImmediate => input.end()
  #.........................................................................................................
  write_sample ( error ) =>
    throw error if error?
    setImmediate => done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) streams as transforms and v/v (1)" ] = ( T, done ) ->
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  matcher     = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  input       = $ ( data ) ->
  D.on_finish input, done
  input
    .pipe D.$collect()
    .pipe D.$show()
    .pipe $ ( lines ) => T.eq lines, matcher if lines?
  #.........................................................................................................
  D.send  input, probe for probe in probes
  D.end   input
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) streams as transforms and v/v (2)" ] = ( T, done ) ->
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  matcher     = [ 'HELO', 'world', '𪉟⿱鹵皿' ]
  transform   = ( line, send ) =>
    if line is 'helo' then  send 'HELO'
    else                    send line
    return null
  input       = $ ( data ) ->
  D.on_finish input, done
  input
    .pipe D.new_stream { transform, }
    .pipe D.$collect()
    .pipe D.new_stream transform: ( ( lines ) => T.eq lines, matcher if lines? )
  #.........................................................................................................
  D.send  input, probe for probe in probes
  D.end   input
  #.........................................................................................................
  return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "(v4) _new_stream_from_path with custom hint" ] = ( T, done ) ->
#   Object.create
#   #.........................................................................................................
#   return null

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
    #.......................................................................................................
    D.on_finish frob, =>
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
  ### TAINT behavior changed now that we're using binary-split in place of split2 ###
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
  D.on_finish input, =>
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
  D.on_finish input, =>
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
  D.on_finish input, done

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
    .pipe $ ( data, send, end ) =>
      send data if data?
      if end?
        end()
        T_done()
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
  D.on_finish input, done
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
  D.on_finish input, done
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
  D.on_finish input, done
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
  D.on_finish input, done
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
    .pipe D.$sort { sorter, }
    .pipe D.$show()
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, [ 99, 98, 82, 55, 33, 23, 11, ] if data?
  D.on_finish input, done
  D.send input, n for n in [ 55, 82, 99, 23, 11, 98, 33, ]
  D.end input

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 4" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$sort { direction: 'descending', }
    .pipe D.$collect()
    .pipe D.$show()
    .pipe $ ( data ) -> T.eq data, [ +Infinity, 99, 98, 82, 55, 33, 23, 11, -Infinity, ] if data?
  D.on_finish input, done
  D.send input, n for n in [ 55, 82, 99, +Infinity, -Infinity, 23, 11, 98, 33, ]
  D.end input

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 5" ] = ( T, done ) ->
  step = ( require 'coffeenode-suspend' ).step
  #.........................................................................................................
  sort = ( direction, keys, matcher, handler ) =>
    info direction, keys
    input = D.new_stream()
    pipeline = ( D.$sort { direction, key, } for key in keys ).reverse()
    input
      .pipe D.new_stream { pipeline, }
      .pipe D.$show()
      .pipe D.$collect()
      .pipe $ ( data ) -> T.eq data, matcher if data? and matcher?
    D.on_finish input, handler
    D.send input, n for n in [
      [ 55,        121, 0, ]
      [ 23,        126, 5, ]
      [ 98,        123, 1, ]
      [ +Infinity, 123, 3, ]
      [ -Infinity, 125, 4, ]
      [ 82,        122, 6, ]
      [ 99,        123, 2, ]
      [ 11,        127, 7, ]
      [ 33,        129, 8, ]
      ]
    D.end input
  #.........................................................................................................
  matcher_a = [
    [ -Infinity, 125, 4 ]
    [ 11, 127, 7 ]
    [ 23, 126, 5 ]
    [ 33, 129, 8 ]
    [ 55, 121, 0 ]
    [ 82, 122, 6 ]
    [ 98, 123, 1 ]
    [ 99, 123, 2 ]
    [ Infinity, 123, 3 ]
    ]
  #.........................................................................................................
  matcher_b = [
    [ 55, 121, 0 ]
    [ 98, 123, 1 ]
    [ 99, 123, 2 ]
    [ Infinity, 123, 3 ]
    [ -Infinity, 125, 4 ]
    [ 23, 126, 5 ]
    [ 82, 122, 6 ]
    [ 11, 127, 7 ]
    [ 33, 129, 8 ]
    ]
  #.........................................................................................................
  matcher_c = [
    [ 55, 121, 0 ]
    [ 98, 123, 1 ]
    [ 99, 123, 2 ]
    [ Infinity, 123, 3 ]
    [ -Infinity, 125, 4 ]
    [ 23, 126, 5 ]
    [ 82, 122, 6 ]
    [ 11, 127, 7 ]
    [ 33, 129, 8 ]
    ]
  #.........................................................................................................
  matcher_d = [
    [ 33, 129, 8 ]
    [ 11, 127, 7 ]
    [ 82, 122, 6 ]
    [ 23, 126, 5 ]
    [ -Infinity, 125, 4 ]
    [ Infinity, 123, 3 ]
    [ 99, 123, 2 ]
    [ 98, 123, 1 ]
    [ 55, 121, 0 ]
    ]
  #.........................................................................................................
  step ( resume ) =>
    yield sort 'ascending',  [ 0, ],       matcher_a, resume
    yield sort 'ascending',  [ 2, ],       matcher_b, resume
    yield sort 'ascending',  [ 2, 1, 0, ], matcher_c, resume
    yield sort 'descending', [ 2, 1, 0, ], matcher_d, resume
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $sort 6" ] = ( T, done ) ->
  step                = ( require 'coffeenode-suspend' ).step
  #.........................................................................................................
  sort = ( directions_and_keys..., matcher, handler ) =>
    help directions_and_keys
    input     = D.new_stream()
    pipeline  = ( D.$sort { direction, key, } for [ direction, key, ] in directions_and_keys )
    pipeline  = pipeline.reverse()
    input
      .pipe D.new_stream { pipeline, }
      .pipe $ ( data ) => info JSON.stringify data if data?
      .pipe $ ( data, send ) => send [ data[ 'date' ], data[ 'size' ], data[ 'name' ], ]
      # .pipe D.$collect()
      # .pipe $ ( data ) -> T.eq data, matcher if data? and matcher?
    D.on_finish input, handler
    for probe in probes
      D.send input, probe
    D.end input
  #.........................................................................................................
  probes = [
    { date: '2016 Apr 19', size:  1069547520, name: "ubuntu-14.04.4-desktop-amd64.iso",                       }
    { date: '2016 Apr 20', size:     1216498, name: "Vermeer-view-of-delft.jpg",                              }
    { date: '2016 Feb  4', size:    28121472, name: "actions.pdf",                                            }
    { date: '2016 Feb 19', size:       61140, name: "rss.opml",                                               }
    { date: '2016 Jan 16', size:   126810054, name: "Inside Star Trek Voyager.mp4",                           }
    { date: '2016 Jan 16', size:   300421011, name: "Star Trek Secrets of the Universe.mp4",                  }
    { date: '2016 Jan 30', size:     8645163, name: "rack-experiment.zip",                                    }
    { date: '2016 Jun  9', size:    71511772, name: "Software Defined Networking - Computerphile.mp4",        }
    { date: '2016 Jun 12', size:   444219478, name: "Syntaxation • Douglas Crockford.mp4",                    }
    { date: '2016 Jun 16', size:   194876109, name: "Another Go at Language Design.mp4",                      }
    { date: '2016 Jun 16', size:   452146120, name: "Go for Pythonistas.mp4",                                 }
    { date: '2016 Jun 16', size:   238955286, name: "Building Services in Go.mp4",                            }
    { date: '2016 Jun 16', size:    29880564, name: "Is Glass a Liquid.mp4",                                  }
    { date: '2016 Jun 16', size:    70266384, name: "Celsius Didn't Invent Celsius.mp4",                      }
    { date: '2016 Jun 16', size:    89684342, name: "INSIDE a Spherical Mirror.mp4",                          }
    { date: '2016 Jun 16', size:   146666578, name: "How Earth Moves.mp4",                                    }
    { date: '2016 Jun 16', size:   131406982, name: "Dynamic Languages Strike Back.mp4",                      }
    { date: '2016 May  4', size:  1537474560, name: "manjaro-xfce-15.12-x86_64.iso",                          }
    { date: '2016 May  6', size:  1828716544, name: "antergos-2016.04.22-x86_64.iso",                         }
    { date: '2016 May  6', size:  1485881344, name: "ubuntu-16.04-desktop-amd64.iso",                         }
    { date: '2016 May  8', size:    12292718, name: "CJK Character Component Standard 20150112165337190.pdf", }
    { date: '2016 May 21', size:     1313746, name: "2015_Logography_and_the_classification_o.pdf",           }
    { date: '2004 Aug  4', size:    10500792, name: "simsun.ttc",                                             }
    { date: '2015 Dec 20', size:     7740439, name: "Ricci, Mnemotechnics, btv1b9006393v.pdf",                }
    { date: '2015 Apr 18', size:    26073977, name: "Perfect Numbers and Mersenne Primes - Numberphile.mp4",  }
    { date: '2015 Nov  1', size:    70623822, name: "atom-amd64(1).deb",                                      }
    { date: '2015 Nov  2', size:    70040746, name: "atom-amd64(2).deb",                                      }
    { date: '2015 Nov 18', size:      362700, name: "CharlesBabbageLawsOfMechanicalNotation.pdf",             }
    { date: '2015 Oct 17', size:    19351620, name: "Legge1899.pdf",                                          }
    { date: '2015 Oct 22', size:    69957572, name: "atom-amd64.deb",                                         }
    { date: '2015 Oct 22', size:   369306221, name: "The Big Bang Theory - Best of Star Trek.mp4",            }
    ]
  #.........................................................................................................
  for probe in probes
    probe[ 'date' ] = ( new Date probe[ 'date' ] )
    probe[ 'size' ] = parseInt 10 ** parseInt Math.log10 probe[ 'size' ]
  #.........................................................................................................
  step ( resume ) =>
    yield sort [ 'ascending', 'date', ], null, resume
    yield sort [ 'ascending', 'size', ], null, resume
    yield sort [ 'ascending', 'name', ], null, resume
    yield sort [ 'descending', 'date', ], [ 'descending', 'size', ], [ 'ascending', 'name', ], null, resume
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $lockstep 1" ] = ( T, done ) ->
  input_1 = D.new_stream()
  input_2 = D.new_stream()
  input_1
    .pipe D.$lockstep input_2
    .pipe D.$collect()
    .pipe D.$show()
    .pipe $ ( data ) -> T.eq data, matcher if data?
  D.on_finish input_1, done
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
  D.on_finish input_1, done
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
  D.on_finish input, done
  matcher = [ [ 0, '以' ], [ 1, '呂' ], [ 2, '波' ], [ 0, '耳' ], [ 1, '本' ], [ 2, '部' ], [ 0, '止' ] ]
  D.send input, word for word in "以 呂 波 耳 本 部 止".split /\s+/
  D.end input
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $split_tsv (1)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split_tsv()
    .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
  D.on_finish input, done
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
    ["","㠋","(⿱山口咢) # first field is empty"]
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
@[ "(v4) $split_tsv (3)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split_tsv names: [ 'fncr', 'glyph', 'formula', ]
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
  D.on_finish input, done
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
    .pipe D.$split_tsv names: 'inline'
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$collect()
    .pipe $ ( data ) -> T.eq data, matcher if data?
  D.on_finish input, done
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

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) read TSV file (1)" ] = ( T, done ) ->
  path  = ( require 'path' ).resolve __dirname, '../test-data/shape-breakdowwn-formula.txt'
  input = D.new_stream { path, }
  # sink  = D.new_stream 'write', path: '/dev/null'
  # sink  = D.new_stream 'write', path: '/tmp/output.txt'
  sink  = D.new_stream 'devnull'
  #.........................................................................................................
  $is_valid_fncr = ->
    errors = []
    return $ ( entry, send, end ) =>
      if entry?
        { fncr, glyph, }  = entry
        fncr_cid          = parseInt ( fncr.replace /^[^\/]+\/(.+)$/g, '$1' ), 16
        glyph_cid         = glyph.codePointAt 0
        #...................................................................................................
        unless fncr_cid is glyph_cid
          fncr_cid_hex  = '0x' + fncr_cid.toString  16
          glyph_cid_hex = '0x' + glyph_cid.toString 16
          message = "CID mismatch: #{fncr} (#{fncr_cid_hex} != #{glyph} (#{glyph_cid_hex}))"
          entry[ 'error' ] = message
          errors.push message
        #...................................................................................................
        send entry
      #.....................................................................................................
      if end?
        if errors.length > 0
          warn "there were #{errors.length} CID mismatches"
          urge "(these were deliberately inserted into the data"
          urge "so these error messages are expected):"
          for error_message in errors
            warn error_message
        end()
      #.....................................................................................................
      return null
  #.........................................................................................................
  $verify = =>
    error_count = 0
    return $ ( entry, send, end ) =>
      if entry?
        { error, }    = entry
        error_count  += +1 if error?
        send entry
      #.....................................................................................................
      if end?
        T.eq error_count, 2
        end()
      #.....................................................................................................
      return null
  #.........................................................................................................
  D.on_finish sink, done
  #.........................................................................................................
  input
    # .pipe D.$split()
    .pipe D.$split_tsv names: 'inline'
    .pipe $is_valid_fncr()
    .pipe $verify()
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe sink
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) fail to read when thru stream comes before read stream" ] = ( T, done ) ->
  MSP   = require 'mississippi'
  path  = ( require 'path' ).resolve __dirname, '../test-data/shape-breakdowwn-formula.txt'
  input = D.new_stream { path, }
  # input = D.new_stream 'utf-8', { path, }
  # input = ( require 'fs' ).createReadStream path, encoding: 'utf-8'
  pipeline = [
    ( MSP.through.obj() )
    ( ( require 'fs' ).createReadStream path, encoding: 'utf-8' )
    ]
  input = MSP.pipeline.obj pipeline...
  input
    # .pipe D.$split_tsv first: 'split', names: 'inline'
    # .pipe $ ( data ) -> help JSON.stringify data if data?
    .pipe D.$show()
    # .pipe D.$collect()
    # .pipe D.$show()
  input.on    'end',    => debug CND.lime 'input end'
  input.on    'finish', => debug CND.lime 'input finish'
  MSP.finished input, ( error ) =>
    throw error if error
    urge "MSP.finish"
    done()
  # D.on_finish input, done
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_url" ] = ( T, done ) ->
  input = D.new_stream url: 'http://example.com'
  sink  = D.new_stream 'devnull'
  found = no
  D.on_finish sink, =>
    T.ok found
    done()
  input
    .pipe D.$split()
    .pipe $ ( line ) ->
      if line?
        found = found or ( /<h1>Example Domain<\/h1>/ ).test line
    # .pipe D.$show()
    .pipe sink
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream README example (1)" ] = ( T, done ) ->
  input = D.new_stream()
  input
    .pipe D.$split()
    .pipe D.$show()
    .pipe D.$on_finish done
  input.write "helo\nworld"
  input.write "!"
  input.end()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream README example (2)" ] = ( T, done ) ->
  input   = D.new_stream()
  thruput = D.new_stream()
  output  = D.new_stream()
  #.........................................................................................................
  input
    .pipe D.$split()
    .pipe thruput
    .pipe D.$on_finish done
    .pipe output
  #.........................................................................................................
  thruput
    .pipe $ ( data ) -> log 'thruput', rpr data
  #.........................................................................................................
  output
    .pipe $ ( data ) -> log 'output', rpr data
  #.........................................................................................................
  input.write "helo\nworld"
  input.write "!"
  input.end()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream README example (3)" ] = ( T, done ) ->
  input   = D.new_stream()
  thruput = D.new_stream()
  output  = D.new_stream()
  #.........................................................................................................
  input
    .pipe D.$split()
    .pipe thruput
    .pipe D.$on_finish done
    .pipe output
    .pipe D.$show()
  #.........................................................................................................
  thruput
    .pipe $ ( data ) -> log 'thruput', rpr data
  #.........................................................................................................
  output
    .pipe $ ( data ) ->
      if data is 'helo'
        thruput.write "meh\n"
        input.write "\nmoar\nof the same!\n"
      # if '#' in data
      #   input.end()
      log 'output', rpr data
  #.........................................................................................................
  setImmediate => input.write "helo\nworld"
  setImmediate => input.write "!"
  setImmediate => input.write "#"
  setImmediate => input.end()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path with encodings" ] = ( T, done ) ->
  step        = ( require 'coffeenode-suspend' ).step
  path        = resolve_temp_path '_new_stream_from_path with encodings.txt'
  probe       = "helo world\näöü\n𪉟⿱鹵皿"
  matcher     = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  encodings   = [ null, 'ascii', 'utf-8', 'ucs2', 'base64', 'binary', 'hex', 'buffer', ]
  matchers    = {}
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = D.new_stream 'write', { path, }
    input
      .pipe D.$show()
      .pipe output
      .pipe D.$on_finish handler
    #.......................................................................................................
    D.send input, probe
    D.end  input
  #.........................................................................................................
  read_matchers = ( encoding, handler ) =>
    if encoding is 'buffer' then  input = ( require 'fs' ).createReadStream path
    else                          input = ( require 'fs' ).createReadStream path, { encoding, }
    input
      .pipe D.$collect()
      .pipe $ ( data ) => matchers[ encoding ] = data if data?
      .pipe D.$on_finish handler
    return null
  #.........................................................................................................
  read_sample = ( encoding, use_hint, handler ) =>
    if use_hint
      if encoding is null then  input = D.new_stream { path, }
      else                      input = D.new_stream encoding, { path, }
    else
      if encoding is 'buffer' then  input = D.new_stream { path, }
      else                          input = D.new_stream { path, }, { encoding, }
    input
      .pipe D.$collect()
      # .pipe D.$show "using #{encoding}:"
      .pipe $ ( result ) =>
        if result?
          if CND.equals result, matchers[ encoding ]
            T.ok yes
          else
            T.fail """
              reading file with encoding #{rpr encoding}, use_hint #{use_hint} failed;
              expected #{rpr matchers[ encoding ]}
              got      #{rpr result}
              """
      .pipe D.$on_finish handler
    return null
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample resume
    for encoding in encodings
      yield read_matchers encoding, resume
    for use_hint in [ false, true, ]
      for encoding in encodings
        yield read_sample encoding, use_hint, resume
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path (raw)" ] = ( T, done ) ->
  step        = ( require 'coffeenode-suspend' ).step
  path        = resolve_temp_path '_new_stream_from_path (raw).txt'
  probe       = "helo world\näöü\n𪉟⿱鹵皿"
  matcher     = [ new Buffer [ 0x68, 0x65, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x0a, 0xc3, 0xa4, 0xc3, 0xb6, 0xc3, 0xbc, 0x0a, 0xf0, 0xaa, 0x89, 0x9f, 0xe2, 0xbf, 0xb1, 0xe9, 0xb9, 0xb5, 0xe7, 0x9a, 0xbf, ]]
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = D.new_stream 'write', { path, }
    input
      .pipe D.$show()
      .pipe output
      .pipe D.$on_finish handler
    #.......................................................................................................
    D.send input, probe
    D.end  input
  #.........................................................................................................
  read_sample = ( encoding, use_hint, handler ) =>
    if use_hint
      if encoding is null then  input = D.new_stream { path, }
      else                      input = D.new_stream encoding, { path, }
    else
      if encoding is 'buffer' then  input = D.new_stream { path, }
      else                          input = D.new_stream { path, }, { encoding, }
    input
      .pipe D.$collect()
      .pipe D.$show "using #{encoding}:"
      .pipe $ ( result ) =>
        if result?
          if CND.equals result, matcher
            T.ok yes
          else
            T.fail """
              reading file with encoding #{rpr encoding}, use_hint #{use_hint} failed;
              expected #{rpr matcher}
              got      #{rpr result}
              """
      .pipe D.$on_finish handler
    return null
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample resume
    for use_hint in [ false, true, ]
      for encoding in [ null, 'buffer', ]
        yield read_sample encoding, use_hint, resume
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) TSV whitespace trimming" ] = ( T, done ) ->
  ends_pattern = ///
    (?: ^ [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]+   )
    |
    (?:   [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]+ $ )
    ///g
  mid_pattern = ///
    [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]*
    \t
    [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]*
    ///g
  probes_and_matchers = [
    ["helo world","helo world"]
    ["helo\tworld","helo\tworld"]
    ["helo\t  world","helo\tworld"]
    ["helo\t  world ","helo\tworld"]
    ["\u3000 helo\t　world\n\n","helo\tworld"]
    ["\t\thelo\t　world\n\n","\t\thelo\tworld"]
    ["\r\t\thelo   \t　world\n\n","\t\thelo\tworld"]
    ]
  for [ probe, matcher, ] in probes_and_matchers
    result_A  = probe
    result_A  = result_A.replace ends_pattern, ''
    result_A  = result_A.replace  mid_pattern, '\t'
    result_B  = D.$split_tsv._trim probe
    # debug '8702', JSON.stringify [ probe, result_A, ]
    # debug '8702', JSON.stringify [ probe, result_B, ]
    debug()
    T.eq result_A, matcher
    T.eq result_B, matcher
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) stream sigils" ] = ( T, done ) ->
#   ⏏⌘⏚⏫⏬⏭⏮⏯⏳⏴⏵⏶⏷⏸⏹⏺📖💻🖨✇✀
#   ⚐⚑⚒⚓⚔⚕⚖⚗⚘⚙⚚⚛⚜⚝⚞⚟
#   ∑⎶〈〉《》【】
#   🔵🔿🕀🗟🛈🖹
#   ▲△▴▵▶▷▸▹►▼▽▾▿◀◁◂◃⯅⯆⯇⯈
#   ▵▼
#   ↔
#   ↹  leftwards arrow to bar over rightwards arrow to bar Unicode code point: U+21B9
#   ⇄  rightwards arrow over leftwards arrow Unicode code point: U+21C4
#   ⇆  leftwards arrow over rightwards arrow Unicode code point: U+21C6
#   ⇋  leftwards harpoon over rightwards harpoon Unicode code point: U+21CB
#   ⇌  rightwards harpoon over leftwards harpoon Unicode code point: U+21CC
  debug ( Array.from """
    ⏳ ⎘ ⎚ ⎇
    ␀␁␂␃␄␅␆␇␈␉␊␋␌␍␎␏␐␑␒␓␔␕␖␗␘␙␚␛␜␝␞␟␠␡␢␣␤␥␦
    ✁✂✃✄✆✇✈✉✌✍✎✏✐✑✒✓✔✕✖✗✘✙✚✛✜✝✞✟✠✡✢✣✤✥✦✧✩✪✫✬✭✮✯✰✱✲✳✴✵✶✷✸✹✺✻✼✽✾✿❀❁❂❃❄❅❆❇❈❉❊❋❍❏❐❑
    ❒❖❗❘❙❚❛❜❝❞❡❢❣❤❥❦❧❨❩❪❫❬❭❮❯❰❱❲❳❴❵❶❷❸❹❺❻❼❽❾❿➀➁➂➃➄➅➆➇➈➉➊➋➌➍➎➏➐➑➒➓➔➘➙➚➛➜➝➞➟➠➡➢➣➤
    ➥➦➧➨➩➪➫➬➭➮➯➱➲➳➴➵➶➷➸➹➺➻➼➽➾✅✊✋✨❌❎❓❔❕❟❠➕➖➗➰➿✀
    """ ).join ' '
  output_path = resolve_temp_path 'sigils-output.txt'
  path        = resolve_temp_path 'sigils.txt'
  output      = D.new_stream 'write', { path, }
  D.on_finish output, =>
    help ( CND.grey '001' ), $ ( d ) =>
    help ( CND.grey '002' ), $ ( d, s ) =>
    help ( CND.grey '003' ), $ ( d, s, e ) =>
    help()
    help ( CND.grey '004' ), D.new_stream()
    help ( CND.grey '005' ), D.new_stream file: path
    help ( CND.grey '006' ), D.new_stream 'lines', file: path
    help()
    help ( CND.grey '007' ), D._new_stream$write_to_file path, { encoding: 'utf-8', }
    help ( CND.grey '007' ), D._new_stream$write_to_file path, { encoding: 'utf-8', }
    help ( CND.grey '008' ), D.$bridge D._new_stream$write_to_file path, { encoding: 'utf-8', }
    help ( CND.grey '009' ), D.new_stream 'write',          file: path
    help ( CND.grey '009' ), D.new_stream 'write', 'utf-8', file: path
    help ( CND.grey '010' ), D.new_stream 'write', 'lines', file: path
    help()
    help ( CND.grey '011' ), D.new_stream 'devnull'
    help ( CND.grey '011' ), D.new_stream pipeline: [ ( D.new_stream file: path ), ( D.new_stream 'devnull' ), ]
    help()
    help ( CND.grey '012' ), D._new_stream$split_buffer '\n'
    help ( CND.grey '013' ), D.$split matcher: '\n', encoding: 'buffer'
    help ( CND.grey '014' ), D.$split matcher: '\n'
    help()
    help ( CND.grey '015' ), D.new_stream pipeline: [ ( $ ( data ) => null ), ]
    help ( CND.grey '015' ), D.new_stream pipeline: [ ( $ ( data ) => null ), ( $ ( data, send ) => null ), ]
    help ( CND.grey '016' ), $ ( data ) => null
    help ( CND.grey '017' ), D.$throttle_bytes 100
    help ( CND.grey '018' ), D.$sort()
    help ( CND.grey '019' ), D.$show()
    help ( CND.grey '020' ), D.$collect()
    help ( CND.grey '021' ), D.$spread()
    help ( CND.grey '022' ), D.new_stream pipeline: [
      ( D.new_stream 'read', 'lines', file: path )
      ( D.$sort() )
      ( D.new_stream 'write', 'lines', file: output_path )
      ]
    help()
    help ( CND.grey '021' ), D.$split_tsv empty: no, comments: no
    help ( CND.grey '021' ), D.$split_tsv empty: no
    help ( CND.grey '021' ), D.$split_tsv comments: no
    help ( CND.grey '021' ), D.$split_tsv()
    debug '9970'
    setImmediate => debug '3332'; done()
  D.send output, 'x'
  D.end output

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $join (1)" ] = ( T, done ) ->
  #.........................................................................................................
  source  = D.new_stream()
  source
    # .pipe D.$collect()
    .pipe D.$join ', '
    .pipe $ ( data, send ) =>
      # debug '5540', JSON.stringify data
      T.eq data, "い, ろ, は, に, ほ, へ, と"
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $join (2)" ] = ( T, done ) ->
  #.........................................................................................................
  source  = D.new_stream()
  source
    # .pipe D.$collect()
    .pipe D.$join()
    .pipe $ ( data, send ) =>
      # debug '5540', JSON.stringify data
      T.eq data, "い\nろ\nは\nに, ほ, へ, と\n諸\n行\n無\n常"
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろは"
  D.send  source, Array.from "にほへと"
  D.send  source, kana for kana in Array.from "諸行無常"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $join (3)" ] = ( T, done ) ->
  #.........................................................................................................
  source  = D.new_stream()
  source
    # .pipe D.$collect()
    .pipe D.$join '—', '·'
    .pipe $ ( data, send ) =>
      # debug '5540', JSON.stringify data
      T.eq data, "い—ろ—は—に·ほ·へ·と—諸—行—無—常"
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろは"
  D.send  source, Array.from "にほへと"
  D.send  source, kana for kana in Array.from "諸行無常"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $intersperse (1)" ] = ( T, done ) ->
  intersperse = D.$intersperse ','
  debug intersperse
  source  = D.new_stream()
  source
    .pipe intersperse
    .pipe D.$show '2'
    .pipe D.$join ''
    .pipe D.$show '4'
    .pipe $ ( data, send ) =>
      # debug '5540', JSON.stringify data
      T.eq data, "い,ろ,は,に,ほ,へ,と"
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $intersperse (2)" ] = ( T, done ) ->
  intersperse = D.$intersperse '|', ','
  debug intersperse
  source      = D.new_stream()
  source
    .pipe intersperse
    .pipe D.$show '2'
    .pipe D.$join ''
    .pipe D.$show '4'
    .pipe $ ( data, send ) =>
      # debug '5540', JSON.stringify data
      T.eq data, "|い,ろ,は,に,ほ,へ,と|"
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $intersperse (3)" ] = ( T, done ) ->
  intersperse = D.$intersperse '[', ',', ']'
  debug intersperse
  source      = D.new_stream()
  source
    .pipe D.$stringify()
    .pipe intersperse
    .pipe D.$join ''
    .pipe $ ( data, send ) =>
      # debug '5540', JSON.stringify data
      T.eq data, '["い","ろ","は","に","ほ","へ","と"]'
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $intersperse (3a)" ] = ( T, done ) ->
  intersperse = D.$intersperse '[\n  ', ',\n  ', '\n  ]\n'
  debug intersperse
  source      = D.new_stream()
  source
    .pipe D.$stringify()
    .pipe intersperse
    .pipe D.$join ''
    .pipe $ ( data, send ) =>
      info '\n' + data
      # debug '5540', rpr data
      T.eq data, '[\n  "い",\n  "ろ",\n  "は",\n  "に",\n  "ほ",\n  "へ",\n  "と"\n  ]\n'
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $intersperse (4)" ] = ( T, done ) ->
  step = ( require 'coffeenode-suspend' ).step
  #.........................................................................................................
  demo = ( x..., handler ) =>
    input = D.new_stream()
    input
      .pipe D.$intersperse x...
      .pipe D.$collect()
      .pipe $ ( data ) ->
        if data?
          matcher_idx += +1
          result = data.join ''
          help x, result
          T.eq result, matchers[ matcher_idx ]
    D.on_finish input, handler
    D.send input, 'a'
    D.send input, 'b'
    D.send input, 'c'
    D.end input
  #.........................................................................................................
  matcher_idx = -1
  matchers = [
    'abc'
    'abc'
    'a—b—c'
    'abc'
    'a—b—c'
    '{abc{'
    '{a—b—c{'
    'abc'
    'abc}'
    'a—b—c'
    'a—b—c}'
    '{abc'
    '{abc}'
    '{a—b—c'
    '{a—b—c}'
    '{a—b—c}'
    ]
  #.........................................................................................................
  step ( resume ) =>
    #.......................................................................................................
    ### 1 way to call with 0 arguments ###
    yield demo                    resume
    #.......................................................................................................
    ### 2 ways to call with 1 arguments ###
    yield demo null,              resume
    yield demo '—',               resume
    #.......................................................................................................
    ### 4 ways to call with 2 arguments ###
    yield demo null,  null,       resume
    yield demo null,  '—',        resume
    yield demo '{',   null,       resume
    yield demo '{',   '—',        resume
    #.......................................................................................................
    ### 8 ways to call with 3 arguments ###
    yield demo null,  null, null, resume
    yield demo null,  null, '}',  resume
    yield demo null,  '—',  null, resume
    yield demo null,  '—',  '}',  resume
    yield demo '{',   null, null, resume
    yield demo '{',   null, '}',  resume
    yield demo '{',   '—',  null, resume
    yield demo '{',   '—',  '}',  resume
    #.......................................................................................................
    yield demo '{—}'...,          resume
    # yield demo '𝔞𝔟𝔠'...,           resume
    #.......................................................................................................
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $as_json_list (1)" ] = ( T, done ) ->
  as_json_list  = D.$as_json_list()
  debug as_json_list
  source        = D.new_stream()
  source
    .pipe as_json_list
    .pipe $ ( data, send ) =>
      info '\n' + data
      # debug '5540', rpr data
      T.eq data, '["い","ろ","は","に","ほ","へ","と"]'
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $as_json_list (2)" ] = ( T, done ) ->
  as_json_list  = D.$as_json_list 'pretty'
  debug as_json_list
  source        = D.new_stream()
  source
    .pipe as_json_list
    .pipe $ ( data, send ) =>
      info '\n' + data
      # debug '5540', rpr data
      T.eq data, '[\n  "い",\n  "ろ",\n  "は",\n  "に",\n  "ほ",\n  "へ",\n  "と"\n  ]\n'
  #.........................................................................................................
  D.on_finish source, done
  D.send  source, kana for kana in Array.from "いろはにほへと"
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $as_json_list (2a)" ] = ( T, done ) ->
  #.........................................................................................................
  f = ( path, handler ) ->
    source  = D.new_stream()
    output  = D.new_stream 'write', { path, }
    D.on_finish output, handler
    source
      # .pipe D.$as_json_list()
      .pipe $ ( data, send ) => send ( JSON.stringify data ); send ','
      .pipe D.$on_start ( send ) => send '['
      .pipe D.$on_last ( data, send ) => send ']\n'
      .pipe output
    #.........................................................................................................
    D.send  source, 42
    D.send  source, 'a string'
    # D.send  source, null # uncomment to test
    D.send  source, false
    D.end   source
  #.........................................................................................................
  # f ( resolve_temp_path '$as_json_list (2a)' ), ( error ) =>
  f '/tmp/foo.json', ( error ) =>
    throw error if error?
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $as_json_list (2b)" ] = ( T, done ) ->
  f = ( path, handler ) ->
    #.......................................................................................................
    $serialize = =>
      return $ ( event, send ) =>
        [ kind, value, ] = event
        return send event unless kind is 'data'
        send [ 'json', ( JSON.stringify value ), ]
    #.......................................................................................................
    $insert_delimiters = =>
      return $ ( event, send ) =>
        [ kind, value, ] = event
        send event
        return unless kind is 'json'
        send [ 'command', 'delimiter', ]
    #.......................................................................................................
    $start_list = => D.$on_start (        send ) => send [ 'command', 'start-list', ]
    $stop_list  = => D.$on_last  ( event, send ) => send [ 'command', 'stop-list',  ]
    #.......................................................................................................
    $as_text = =>
      return $ ( event, send ) =>
        [ kind, value, ] = event
        return send value     if kind is 'json'
        return send event unless kind is 'command'
        switch command = value
          when 'delimiter' then send ',\n'
          when 'start-list' then send '[\n'
          when 'stop-list'  then send '\n]\n'
          else send.error new Error "unknown command #{rpr command}"
        return null
    #.......................................................................................................
    source  = D.new_stream()
    output  = D.new_stream 'write', { path, }
    D.on_finish output, handler
    source
      .pipe $serialize()
      .pipe $insert_delimiters()
      .pipe $start_list()
      .pipe $stop_list()
      .pipe $as_text()
      .pipe output
    #.........................................................................................................
    D.send  source, [ 'data', 42,         ]
    D.send  source, [ 'data', 'a string', ]
    D.send  source, [ 'data', null,       ]
    D.send  source, [ 'data', false,      ]
    D.end   source
  #.........................................................................................................
  # f ( resolve_temp_path '$as_json_list (2a)' ), ( error ) =>
  f '/tmp/foo.json', ( error ) =>
    throw error if error?
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $as_json_list (2c)" ] = ( T, done ) ->
  #.........................................................................................................
  f = ( path, handler ) ->
    source  = D.new_stream()
    output  = D.new_stream 'write', { path, }
    D.on_finish output, handler
    source
      .pipe $ ( data, send ) => if data is Symbol.for 'null' then send 'null' else send JSON.stringify data
      .pipe $ ( data, send ) => send data; send ','
      .pipe D.$on_start (       send ) => send '['
      .pipe D.$on_last  ( data, send ) => send ']\n'
      .pipe output
    #.........................................................................................................
    data_items = [ 42, 'a string', null, false, ]
    for data in data_items
      D.send source, if data is null then Symbol.for 'null' else data
    D.end source
  #.........................................................................................................
  # f ( resolve_temp_path '$as_json_list (2a)' ), ( error ) =>
  f '/tmp/foo.json', ( error ) =>
    throw error if error?
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $as_json_list (3)" ] = ( T, done ) ->
  source        = D.new_stream()
  source
    .pipe D.$as_json_list 'pretty'
    .pipe $ ( data, send ) =>
      info '\n' + data
      # debug '5540', rpr data
      T.eq data, '[\n  "a text",\n  {"~isa":"symbol","value":"XXXXXXXX"},\n  42,\n  null,\n  true,\n  ["foo","bar"]\n  ]\n'
  D.on_finish source, done
  #.........................................................................................................
  probes = [
    "a text"
    Symbol.for 'XXXXXXXX'
    42
    Symbol.for 'null'
    true
    [ 'foo', 'bar', ]
    ]
  matcher = [
    '"a text"'
    '{"~isa":"symbol","value":"XXXXXXXX"}'
    '42'
    'null'
    'true'
    '["foo","bar"]'
    ]
  D.send  source, probe for probe in probes
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) symbols as data events (1)" ] = ( T, done ) ->
  source        = D.new_stream()
  source
    # .pipe D.$collect()
    .pipe do =>
      idx = -1
      return $ ( data, send ) =>
        idx += +1
        info data
        T.eq data, probe[ idx ]
  #.........................................................................................................
  D.on_finish source, done
  probe = [
    "a text"
    Symbol.for 'XXXXXXXX'
    42
    Symbol.for 'null'
    true
    [ 'foo', 'bar', ]
    ]
  D.send  source, element for element in probe
  D.end   source
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) symbols as data events (2)" ] = ( T, done ) ->
  source        = D.new_stream()
  source
    .pipe D.$stringify()
    # .pipe D.$show()
    # .pipe D.$collect()
    .pipe do =>
      idx = -1
      return $ ( data, send ) =>
        idx += +1
        # info data
        T.eq data, matchers[ idx ]
  #.........................................................................................................
  D.on_finish source, done
  probes = [
    "a text"
    Symbol.for 'XXXXXXXX'
    42
    Symbol.for 'null'
    true
    [ 'foo', 'bar', ]
    ]
  matchers = [
    '"a text"'
    '{"~isa":"symbol","value":"XXXXXXXX"}'
    '42'
    'null'
    'true'
    '["foo","bar"]'
    ]
  D.send  source, element for element in probes
  D.end   source
  #.........................................................................................................
  return null



#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
delay = ( name, f ) =>
  if arguments.length is 1
    f     = name
    name  = null
  dt = CND.random_integer 10, 200
  # dt = 1
  whisper "delay for #{rpr name}: #{dt}ms" if name?
  setTimeout f, dt

#-----------------------------------------------------------------------------------------------------------
sleep = ( dt, handler ) =>
  setTimeout handler, dt

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
  info "temporary files, if any, written to #{temp_home}"
  test @, 'timeout': 3000

############################################################################################################
unless module.parent?
  include = [
    # "(v4) stream / transform construction with through2 (2)"
    # "(v4) fail to read when thru stream comes before read stream"
    # "(v4) _new_stream_from_text doesn't work synchronously"
    "(v4) _new_stream_from_path (2)"
    "(v4) _new_stream_from_pipeline (1a)"
    "(v4) _new_stream_from_pipeline (3)"
    "(v4) _new_stream_from_pipeline (4)"
    "(v4) _new_stream_from_text"
    "(v4) _new_stream_from_text (2)"
    "(v4) observer transform called with data `null` on stream end"
    "(v4) README demo (1)"
    "(v4) D.new_stream"
    "(v4) stream / transform construction with through2 (1)"
    "(v4) D._new_stream_from_pipeline"
    "(v4) $async with method arity 2"
    "(v4) $async with method arity 3"
    "(v4) $lockstep 1"
    "(v4) $lockstep fails on streams of unequal lengths without fallback"
    "(v4) $lockstep succeeds on streams of unequal lengths with fallback"
    "(v4) $batch and $spread"
    "(v4) streams as transforms and v/v (1)"
    "(v4) streams as transforms and v/v (2)"
    "(v4) file stream events (1)"
    "(v4) transforms below output receive data events (1)"
    "(v4) transforms below output receive data events (2)"
    "(v4) _new_stream_from_url"
    "(v4) new_stream README example (1)"
    "(v4) new_stream README example (2)"
    "(v4) new_stream README example (3)"
    "(v4) _new_stream_from_path with encodings"
    "(v4) _new_stream_from_path (raw)"
    "(v4) new new_stream signature (1)"
    "(v4) new new_stream signature (2)"
    "(v4) _new_stream_from_path (1)"
    "(v4) _new_stream_from_path (4)"
    "(v4) _new_stream_from_path (3)"
    "(v4) $split_tsv (3)"
    "(v4) $split_tsv (4)"
    "(v4) read TSV file (1)"
    "(v4) TSV whitespace trimming"
    "(v4) $split_tsv (1)"
    "(v4) $intersperse (1)"
    "(v4) $intersperse (2)"
    "(v4) $intersperse (3)"
    "(v4) $intersperse (3a)"
    "(v4) $intersperse (4)"
    "(v4) $join (1)"
    "(v4) $join (2)"
    "(v4) $join (3)"
    "(v4) $as_json_list (1)"
    "(v4) $as_json_list (2)"
    "(v4) $as_json_list (2a)"
    "(v4) $as_json_list (2b)"
    "(v4) $as_json_list (2c)"
    "(v4) $as_json_list (3)"
    "(v4) symbols as data events (1)"
    "(v4) symbols as data events (2)"
    "(v4) stream sigils"
    "(v4) $sort 1"
    "(v4) $sort 2"
    "(v4) $sort 3"
    "(v4) $sort 4"
    "(v4) $sort 5"
    "(v4) $sort 6"
    ]
  @_prune()
  @_main()


  # debug '5562', JSON.stringify key for key in Object.keys @

