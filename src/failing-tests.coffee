
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

#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 3000


############################################################################################################
unless module.parent?
  @_main()

