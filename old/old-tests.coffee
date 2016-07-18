
### This module contains tests that are of dubious value, outdated, or fail
for unknown reasons; they are kept here to keep the code around and maybe
reuse them at a later point in time. ###


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


#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_stream_from_pipeline (2)" ] = ( T, done ) ->
  create_frob_tee = null
  #.........................................................................................................
  do ->
    create_frob_tee = ( settings ) ->
      multiply        = $ ( data, send ) => send data * 2
      add             = $ ( data, send ) => send data + 2
      square          = $ ( data, send ) => send data ** 2
      unsquared       = D.new_stream()
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
        debug '4435', JSON.stringify unsquared_results
        debug '4435', JSON.stringify unsquared_matchers
        debug '4435', JSON.stringify output_results
        debug '4435', JSON.stringify output_matchers
        T.eq unsquared_results, unsquared_matchers
        T.eq    output_results,    output_matchers
        done()
    #.......................................................................................................
    input.write n for n in probes
    input.end()
  #.........................................................................................................
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "(v4) failing asynchronous demo with event-stream, PipeDreams v2" ] = ( T, T_done ) ->
  #.........................................................................................................
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
  $client_method_called_here = ( S ) =>
    return D._ES.map ( glyph, handler ) =>
      S.count += +1
      urge '7765-1 $client_method_called_here:', glyph
      read_one_phrase glyph, ( error, phrase ) =>
        return handler error if error?
        S.count += -1
        urge '7765-2 $client_method_called_here:', phrase
        handler null, phrase if phrase?
        handler()
  #.........................................................................................................
  $collect_results = ( S ) =>
    collector = []
    return $ ( data, send, end ) =>
      if data?
        collector.push data
        help '7765-3 $collect_results data:     ', data
      if end?
        info collector
        end()
  #.........................................................................................................
  S             = {}
  S.count       = 0
  S.end_stream  = null
  S.input       = D.new_stream()
  S.input
    .pipe $client_method_called_here  S
    .pipe $collect_results            S
    .pipe D.$on_end => T_done()
  #.........................................................................................................
  for glyph in Array.from '千仟韆'
    S.input.write glyph
  S.input.end()
  #.........................................................................................................
  return null

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
            end()
            T_done()
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
@[ "(v4) synchronous collect" ] = ( T, done ) ->
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  f = ( text ) ->
  through2  = require 'through2'
  split2    = require 'split2'
  input     = through2()
  output    = through2.obj()
  input
    # .pipe $ ( data ) -> if data? then urge rpr data.toString 'utf-8' else warn '1—stream ended'
    .pipe do =>
      last_is_nl = no
      return $ ( data, send, end ) ->
        if data?
          if CND.isa_text data then last_is_nl = data[ data.length - 1 ] is 0x0a
          else                      last_is_nl = data[ data.length - 1 ] is '\n'
          send data
        if end?
          debug '4431', last_is_nl
          send '\n' unless last_is_nl
          end()
    .pipe split2()
    .pipe $ ( data ) -> if data? then help rpr data #.toString 'utf-8'
    .pipe output
  output
    .pipe do =>
      # collector = []
      return $ ( data, send, end ) ->
        collector.push data if data?
        if end?
          info collector
          end()
  # input.resume()
  input.on 'end', -> warn '2—stream ended'
  output.on 'end', -> warn '3—stream ended'
  #.........................................................................................................
  # input.pause()
  # input.write text
  # input.end()
  collector = []
  input.push text + if text.endsWith '\n' then '' else '\n'
  input.push null
  debug collector
  # info '4432', result  = D.collect output
  # input.resume()
  # T.eq result, text.split '\n'
  setTimeout done, 500

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

###
#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $bridge" ] = ( T, done ) ->
  # input   = D.new_file_readstream ( require 'path' ).resolve __dirname, '../package.json'
  MSP         = require 'mississippi'
  has_url     = no
  has_ended   = no
  input       = ( require 'fs' ).createReadStream ( require 'path' ).resolve __dirname, '../package.json'
  # throughput  = ( require 'fs' ).createWriteStream '/tmp/foo'
  # #.........................................................................................................
  # D.$bridge = ( stream ) ->
  #   stream.on 'close',  => urge 'close'
  #   stream.on 'finish', => urge 'finish'
  #   main  = ( data, _, callback ) ->
  #     debug '4453', data
  #     stream.write data
  #     @push data
  #     callback()
  #   flush = ( callback ) ->
  #     stream.close()
  #     callback()
  #   # return MSP.through.obj main, flush
  #   return D.new_stream()
  #.........................................................................................................
  input
    .pipe D.$split()
    .pipe D.$show()
    .pipe $ ( line ) =>
      has_url = has_url or ( /// "homepage" .* "https:\/\/github .* \/pipedreams" /// ).test line
    # .pipe D.$bridge ( require 'fs' ).createWriteStream '/tmp/foo'
    # .pipe MSP.duplex ( ( require 'fs' ).createWriteStream '/tmp/foo' ), D.new_stream()
    # .pipe D.$bridge process.stdout
    .pipe D.$on_end =>
      has_ended = yes
      if has_url then T.ok yes
      else            T.fail "expected to find a URL"
      done()
  # report_failure = =>
  #   return if has_ended
  #   T.fail ".pipe D.$on_end was not called"
  #   done()
  # setTimeout report_failure, 2000
  return null
###

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) new_file_readstream" ] = ( T, done ) ->
  input   = D.new_file_readstream ( require 'path' ).resolve __dirname, '../package.json'
  # input   = ( require 'fs' ).createReadStream ( require 'path' ).resolve __dirname, '../package.json'
  has_url = no
  input
    .pipe D.$split()
    .pipe D.$show()
    .pipe $ ( line ) =>
      has_url = has_url or ( /// "homepage" .* "https:\/\/github .* \/pipedreams" /// ).test line
    # .pipe D.$bridge ( require 'fs' ).createWriteStream '/tmp/foo'
    .pipe D.$on_end =>
      if has_url then T.ok yes
      else            T.fail "expected to find a URL"
      done()
    # .pipe ( require 'fs' ).createWriteStream '/dev/null'
  input.resume()

# #-----------------------------------------------------------------------------------------------------------
# @[ "(v4) new_file_readlinestream" ] = ( T, done ) ->
#   input = D.new_file_readlinestream ( require 'path' ).resolve __dirname, '../package.json'
#   input
#     .pipe D.$show()
#     .pipe D.new_sink()
#     .pipe D.$on_end => done()
#   # done()
#   input.resume()

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

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) _new_stream_from_path (interim) (2)" ] = ( T, done ) ->
  ### One possible implementation of `D.$bridge` ###
  step        = ( require 'coffeenode-suspend' ).step
  MSP         = require 'mississippi'
  path_1      = resolve_temp_path '_new_stream_from_path-2.txt'
  probes      = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  matcher     = [ 'helo', 'world', '𪉟⿱鹵皿' ]
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    # output  = MSP.duplex ( D.new_stream 'write', 'lines', path: path_1 ), D.new_stream()
    # output = ( D.new_stream 'write', 'lines', path: path_1 )
    W = ( require 'fs' ).createWriteStream path_1
    Z = D.new_stream()
    A = $ ( data, send, end ) =>
        if data?
          W.write data
          Z.write data
        if end?
          W.end()
          Z.end()
          end()
    output  = MSP.duplex A, Z, { objectMode: yes, }
    input
      .pipe $ ( line, send ) => send line + '\n'
      .pipe output
      .pipe D.$show()
      .pipe D.$on_end => handler()
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    input   = D.new_stream 'read', 'lines', path: path_1
    input
      .pipe D.$collect()
      # .pipe D.$show()
      .pipe $ ( lines ) => T.eq lines, matcher if lines?
      .pipe D.$on_end => handler()
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample  resume
    yield read_sample   resume
    done()
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
      .pipe D.$on_finish handler
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    input   = D.new_stream 'read', 'lines', path: path_1
    input
      .pipe D.$collect()
      .pipe $ ( lines ) => T.eq lines, matcher if lines?
      .pipe D.$on_finish handler
  #.........................................................................................................
  step ( resume ) =>
    yield write_sample  resume
    yield read_sample   resume
    done()
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
  MSP         = require 'mississippi'
  step        = ( require 'coffeenode-suspend' ).step
  path        = resolve_temp_path "_new_stream_from_path-3-#{idx}.txt"
  #.........................................................................................................
  write_sample = ( handler ) =>
    input   = D.new_stream()
    output  = D.new_stream 'write', 'lines', { path, }
    input
      .pipe output
      .pipe D.$on_finish handler
      # .pipe D.$finish output, handler
    #.......................................................................................................
    D.send input, probe for probe in probes
    D.end input
  #.........................................................................................................
  read_sample = ( handler ) =>
    try
      input   = D.new_stream 'read', 'lines', { path, }
    catch error
      return handler error
    input
      .pipe D.$collect()
      # .pipe D.$show()
      .pipe do =>
        result = null
        return $ 'null', ( lines ) =>
          if lines? then result = lines
          else handler null, result
  #.........................................................................................................
  step ( resume ) =>
    yield           write_sample  resume
    result = yield  read_sample   resume
    handler null, result
  #.........................................................................................................
  return null

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (w/ mississippi pipeline)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers    = [ '', '', ]
  through     = MSP.pipeline.obj D.new_stream(), D.new_stream(), D.new_stream()
  input       = D.new_stream()
  input
    .pipe through
    .pipe D.$show()
    .pipe $ ( data ) => urge data
    .pipe $ ( data, send ) => send data if data is ''
    .pipe $validate_probes T, matchers
    .pipe D.$on_finish done
  D.send  input, 'A text'
  D.send  input, 'with a few'
  D.send  input, ''
  D.send  input, 'lines'
  D.send  input, ''
  D.send  input, 'some of which'
  D.send  input, 'are empty.'
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi through works as such)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers    = []
  sub_input   = D.new_stream()
  sub_output  = D.new_stream()
  sub_input.pipe sub_output
  through     = MSP.through.obj sub_input, sub_output
  input       = D.new_stream()
  input
    .pipe through
    .pipe D.$show()
    .pipe $ ( data ) => urge data
    .pipe $ ( data, send ) => send data if data is ''
    .pipe $validate_probes T, matchers
    .pipe D.$on_finish done
  D.send  input, 'A text'
  D.send  input, 'with a few'
  D.send  input, 'lines'
  D.send  input, 'some of which'
  D.send  input, 'are empty.'
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi through works with empty strings)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers    = [ '', '', ]
  sub_input   = D.new_stream()
  sub_output  = D.new_stream()
  sub_input.pipe sub_output
  through     = MSP.through.obj sub_input, sub_output
  input       = D.new_stream()
  input
    .pipe through
    .pipe D.$show()
    .pipe $ ( data ) => urge data
    .pipe $ ( data, send ) => send data if data is ''
    .pipe $validate_probes T, matchers
    .pipe D.$on_finish done
  D.send  input, 'A text'
  D.send  input, 'with a few'
  D.send  input, ''
  D.send  input, 'lines'
  D.send  input, ''
  D.send  input, 'some of which'
  D.send  input, 'are empty.'
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi pipeline works as such)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "none", "of which", "are empty.", ]
  matchers_2  = []
  collector   = []
  sub_input   = D.new_stream()
  collect     = $ ( data ) => collector.push data
  sub_output  = D.new_stream()
  # handler     = ( error ) =>
  #   return T.fail error if error?
  #   T.succeed "mississippi pipe ok."
  #   # done()
  through     = MSP.pipeline.obj sub_input, collect, sub_output
  input       = D.new_stream()
  input
    .pipe through
    # .pipe D.$show()
    .pipe $ ( data ) => urge data
    .pipe $ ( data, send ) => send data if data is ''
    .pipe $validate_probes T, matchers_2
    .pipe D.$on_finish =>
      T.eq collector, matchers_1
      done()
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, "none"
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi pipeline works with empty strings)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "", "some", "", "of which", "are empty.", ]
  matchers_2  = []
  collector   = []
  sub_input   = D.new_stream()
  collect     = $ ( data ) => collector.push data
  sub_output  = D.new_stream()
  # handler     = ( error ) =>
  #   return T.fail error if error?
  #   T.succeed "mississippi pipe ok."
  #   # done()
  through     = MSP.pipeline.obj sub_input, collect, sub_output
  input       = D.new_stream()
  input
    .pipe through
    # .pipe D.$show()
    .pipe $ ( data ) => urge data
    .pipe $ ( data, send ) => send data if data is ''
    .pipe $validate_probes T, matchers_2
    .pipe D.$on_finish =>
      T.eq collector, matchers_1
      done()
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, ""
  D.send  input, "some"
  D.send  input, ""
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi pipe works as such)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "none", "of which", "are empty.", ]
  matchers_2  = []
  collector   = []
  #.........................................................................................................
  collect     = $ ( data ) => collector.push data
  show        = $ ( data ) => urge data
  filter      = $ ( data, send ) => send data if data is ''
  # validate    = $validate_probes T, matchers_2
  input       = D.new_stream()
  #.........................................................................................................
  handler     = ( error ) =>
    return T.fail error if error?
    T.succeed "mississippi pipe ok."
    T.eq collector, matchers_1
    done()
  #.........................................................................................................
  MSP.pipe input, collect, show, handler
  #.........................................................................................................
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, "none"
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi pipe works with empty strings)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "", "some", "", "of which", "are empty.", ]
  matchers_2  = [ "", "", ]
  collector_1 = []
  collector_2 = []
  #.........................................................................................................
  collect_1   = $ ( data ) => collector_1.push data
  collect_2   = $ ( data ) => collector_2.push data
  show        = $ ( data ) => urge data
  filter      = $ ( data, send ) => send data if data is ''
  # validate    = $validate_probes T, matchers_2
  input       = D.new_stream()
  #.........................................................................................................
  handler     = ( error ) =>
    return T.fail error if error?
    T.succeed "mississippi pipe ok."
    T.eq collector_1, matchers_1
    T.eq collector_2, matchers_2
    done()
  #.........................................................................................................
  MSP.pipe input, collect_1, show, filter, collect_2, handler
  #.........................................................................................................
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, ""
  D.send  input, "some"
  D.send  input, ""
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi duplex works as such)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "none", "of which", "are empty.", ]
  collector_1 = []
  #.........................................................................................................
  collect     = $ ( data ) => collector_1.push data
  show        = $ ( data ) => urge data
  filter      = $ ( data, send ) => send data if data is ''
  input       = D.new_stream()
  receiver    = D.new_stream()
  sender      = D.new_stream()
  #.........................................................................................................
  handler     = ( error ) =>
    return T.fail error if error?
    help 'ok'
  #.........................................................................................................
  MSP.pipe receiver, collect, show, sender, handler
  through     = MSP.duplex.obj receiver, sender
  #.........................................................................................................
  input
    .pipe through
    .pipe D.$show()
    .pipe D.$on_finish =>
      T.eq collector_1, matchers_1
      done()
  #.........................................................................................................
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, "none"
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) can send empty strings (validate mississippi duplex works with empty strings)" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "", "some", "", "of which", "are empty.", ]
  matchers_2  = [ "", "", ]
  collector_1 = []
  collector_2 = []
  #.........................................................................................................
  collect_1   = $ ( data ) => collector_1.push data
  collect_2   = $ ( data ) => collector_2.push data
  show        = $ ( data ) => urge data
  filter      = $ ( data, send ) => send data if data is ''
  input       = D.new_stream()
  receiver    = D.new_stream()
  sender      = D.new_stream()
  #.........................................................................................................
  handler     = ( error ) =>
    return T.fail error if error?
    help 'ok'
  #.........................................................................................................
  MSP.pipe receiver, collect_1, show, filter, collect_2, sender, handler
  through     = MSP.duplex.obj receiver, sender
  #.........................................................................................................
  input
    .pipe through
    .pipe D.$show()
    .pipe D.$on_finish =>
      T.eq collector_1, matchers_1
      T.eq collector_2, matchers_2
      done()
  #.........................................................................................................
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, ""
  D.send  input, "some"
  D.send  input, ""
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input

#-----------------------------------------------------------------------------------------------------------
@[ "(empty-string) duplexer2 works with empty strings" ] = ( T, done ) ->
  MSP         = require 'mississippi'
  matchers_1  = [ "A text", "with a few", "lines", "", "some", "", "of which", "are empty.", ]
  matchers_2  = [ "", "", ]
  collector_1 = []
  collector_2 = []
  #.........................................................................................................
  collect_1   = $ ( data ) => collector_1.push data
  collect_2   = $ ( data ) => collector_2.push data
  show        = $ ( data ) => urge data
  filter      = $ ( data, send ) => send data if data is ''
  cause_error = $ ( data, send ) =>
    return send data unless data is "some"
    send.error new Error "test error"
  input       = D.new_stream()
  receiver    = D.new_stream()
  sender      = D.new_stream()
  #.........................................................................................................
  handler     = ( error ) =>
    return pipeline.emit 'error', error if error?
    help 'ok'
  #.........................................................................................................
  # MSP.pipe receiver, collect_1, show, cause_error, filter, collect_2, sender, handler
  MSP.pipe receiver, collect_1, show, filter, collect_2, sender, handler
  pipeline = ( require 'duplexer2' ) { objectMode: yes, }, receiver, sender
  #.........................................................................................................
  input
    .pipe pipeline
    .pipe D.$on_finish =>
      T.eq collector_1, matchers_1
      T.eq collector_2, matchers_2
      done()
  #.........................................................................................................
  D.send  input, "A text"
  D.send  input, "with a few"
  D.send  input, "lines"
  D.send  input, ""
  D.send  input, "some"
  D.send  input, ""
  D.send  input, "of which"
  D.send  input, "are empty."
  D.end   input


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


### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 3000


############################################################################################################
unless module.parent?
  @_main()

