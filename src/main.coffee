

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
insp                      = ( require 'util' ).inspect
#...........................................................................................................
# ### https://github.com/rvagg/through2 ###
# through2                  = require 'through2'
### https://github.com/maxogden/mississippi ###
MSP                       = require 'mississippi'
#...........................................................................................................
### http://stringjs.com ###
# stringfoo                 = require 'string'
#...........................................................................................................
### https://github.com/mcollina/split2 ###
# split2                    = require 'split2'
#...........................................................................................................
### https://github.com/mziccard/node-timsort ###
# timsort                   = require 'timsort'


#-----------------------------------------------------------------------------------------------------------
@new_stream = ( P... ) ->
  @new_stream._read_arguments_2 P
  [ kind, seed, hints, settings, ] = @new_stream._read_arguments P
  R = switch kind
    when '*plain'       then @_new_stream                seed, hints, settings
    when 'file', 'path' then @_new_stream_from_path      seed, hints, settings
    when 'pipeline'     then @_new_stream_from_pipeline  seed, hints, settings
    when 'text'         then @_new_stream_from_text      seed, hints, settings
    when 'url'          then @_new_stream_from_url       seed, hints, settings
    when 'transform'    then @_new_stream_from_transform seed, hints, settings
    else throw new Error "unknown kind #{rpr kind} (shouldn't happen)"
  #.....................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@new_stream._read_arguments_2 = ( P ) =>
  R =
    flags:        []
    kind:         null
    seed:         null
    settings:     {}
  #.....................................................................................................
  # ultimate_idx    = P.length - 1
  # penultimate_idx = ultimate_idx - 1
  flags_over      = no
  #.....................................................................................................
  for p, idx in P
    if CND.isa_text p
      if flags_over
        throw new Error "detected flag at illegal position in call signature #{rpr P}"
      R.flags.push p
    else
      flags_over = yes
      unless R.kind?
        for kind, seed of p
          if R.kind?
            throw new Error "can't have more than single key in kind selector object, got #{rpr P}"
          unless kind in @new_stream._kinds
            expected  = ( rpr x for x in @new_stream._kinds ).join ', '
            got       =   rpr kind
            throw new Error "expected a 'kind' out of #{expected}, got #{got}"
          R.kind  = kind
          R.seed  = seed
      else
        R.settings = Object.assign {}, P[ idx .. ]...
  #.....................................................................................................
  R.kind ?= 'through'
  #.....................................................................................................
  rprd = ( x ) -> insp x, depth: 1
  debug '3345', ( CND.white rprd P ), ( CND.grey '=>' ), ( CND.lime rprd R )
  # debug '3345', ( CND.yellow ( require 'util' ).inspect P, depth: 0 )#, ( CND.grey '=>' ), ( CND.lime R )
  #.....................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@new_stream._read_arguments = ( P ) =>
  kind_and_seed = null
  settings      = null
  kind          = null
  seed          = null
  hints         = null
  # #.........................................................................................................
  # return [ 'transform', t, null, null, ] if P.length is 1 and CND.isa_function t = P[ 0 ]
  #.........................................................................................................
  if P.length > 0
    if P.length > 1
      unless CND.isa_text P[ P.length - 1 ]
        kind_and_seed = P.pop()
    unless CND.isa_text P[ P.length - 1 ]
      settings      = kind_and_seed
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
  unless kind in @new_stream._kinds
    expected  = ( rpr x for x in @new_stream._kinds ).join ', '
    got       =   rpr kind
    throw new Error "expected a 'kind' out of #{expected}, got #{got}"
  #.........................................................................................................
  hints = null if hints.length is 0
  return [ kind, seed, hints, settings, ]

#...........................................................................................................
@new_stream._kinds = [ '*plain', 'file', 'path', 'pipeline', 'text', 'url', 'transform', ]

#-----------------------------------------------------------------------------------------------------------
@_new_stream = ( seed, hints, settings ) ->
  if ( not seed? ) and ( not settings? ) and hints? and ( hints.length is 1 ) and 'devnull' in hints
    return @_new_devnull_stream()
  throw new Error "_new_stream doesn't accept 'seed', got #{rpr seed}" if seed?
  throw new Error "_new_stream doesn't accept 'hints', got #{rpr hints}" if hints?
  throw new Error "_new_stream doesn't accept 'settings', got #{rpr settings}" if settings?
  return @_wrap_stream 'P', MSP.through.obj()

#-----------------------------------------------------------------------------------------------------------
@_new_stream$fs_read_stream   = ( P ... )   ->
  @_wrap_stream 'FsR', ( require 'fs' ).createReadStream  P...

#-----------------------------------------------------------------------------------------------------------
@_new_stream$fs_write_stream  = ( P ... )   ->
  @_wrap_stream 'FsW', ( require 'fs' ).createWriteStream P...

#-----------------------------------------------------------------------------------------------------------
@_new_stream$split_buffer     = ( matcher ) ->
  return @_wrap_stream "//#{rpr matcher}//", ( require 'binary-split' ) matcher

#-----------------------------------------------------------------------------------------------------------
@_wrap_stream = ( sigil, stream ) ->
  if ( _inspect = stream.inspect )?
    if CND.isa_function sigil then  inspect = -> "(#{sigil()} [#{_inspect()}])"
    else                            inspect = -> "(#{sigil} [#{_inspect()}])"
  else
    if CND.isa_function sigil then  inspect = -> "(#{sigil()})"
    else                            inspect = -> "(#{sigil})"
  stream.inspect = inspect
  return stream

#-----------------------------------------------------------------------------------------------------------
@_new_devnull_stream = ->
  x = new Buffer "data\n"
  pipeline = [
    ( @$ ( data, send ) => send x )
    ( @new_stream 'write', path: '/dev/null' )
    ]
  return @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_path = ( path, hints, settings ) ->
  unless type = ( CND.type_of path ) is 'text'
    throw new Error "expected path to be a text, got a #{type}"
  #.........................................................................................................
  role          = 'read'
  encoding      = null
  use_line_mode = null
  pipeline      = []
  settings      = Object.assign {}, settings
  #.........................................................................................................
  if hints?
    #.......................................................................................................
    unless CND.is_subset hints, @_new_stream_from_path._hints
      expected  = ( rpr x for x in @_new_stream_from_path._hints ).join ', '
      got       = ( rpr x for x in hints when x not in @_new_stream_from_path._hints ).join ', '
      throw new Error "expected 'hints' out of #{expected}, got #{got}"
    #.......................................................................................................
    use_line_mode = 'lines' in hints
    #.......................................................................................................
    role_count  = 0
    if 'read' in hints
      role        = 'read'
      role_count += +1
    if 'write' in hints
      role        = 'write'
      role_count += +1
    if 'append' in hints
      role        = 'append'
      role_count += +1
    if role_count > 1
      throw new Error "can only specify one of `read`, `write` or `append`; got #{rpr hints}"
  # #.........................................................................................................
  # if hints? and hints.length > 1
  #   warn "ignoring additional hints of #{rpr hints} for the time being"
  if hints?
    for key in [ 'ascii', 'utf8', 'utf-8', 'ucs2', 'base64', 'binary', 'hex', 'buffer', ]
      if key in hints
        throw new Error "hints contain multiple encodings: #{rpr hints}" if encoding?
        encoding = key
  #.........................................................................................................
  if role is 'read'
    if use_line_mode
      pipeline.push @_new_stream$fs_read_stream path, settings
      pipeline.push @$split { encoding, }
    else
      settings[ 'encoding' ]?= if encoding is 'buffer' then null else encoding
      pipeline.push @_new_stream$fs_read_stream path, settings
  #.........................................................................................................
  else # role is write or append
    if role is 'append' then settings[ 'flags' ] = 'a'
    settings[ 'encoding' ]?= encoding unless encoding is 'buffer'
    pipeline.push @$as_line() if use_line_mode
    pipeline.push @$bridge @_new_stream$fs_write_stream path, settings
  #.........................................................................................................
  return @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_path._hints = [
  'ascii', 'utf8', 'utf-8', 'ucs2', 'base64', 'binary', 'hex', 'buffer',
  'read', 'write', 'append',
  'lines', ]

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_pipeline = ( pipeline, hints, settings ) ->
  ### Given a list of transforms (a.k.a. a 'pipeline'), return a stream that has all the transforms
  successively linked with `.pipe` calls; writing to the stream will write to the first transform, and
  reading from the stream will read from the last transform. ###
  throw new Error "_new_stream_from_pipeline doesn't accept 'hints', got #{rpr hints}"        if hints?
  throw new Error "_new_stream_from_pipeline doesn't accept 'settings', got #{rpr settings}"  if settings?
  throw new Error "expected a list, got a #{type}" unless ( type = CND.type_of pipeline ) is 'list'
  #.........................................................................................................
  ### The underlying implementation does not allow to get passed less than two streams, so we
  add pass-through transforms to satisfy it: ###
  if pipeline.length < 2
    pipeline  = Object.assign [], pipeline
    while pipeline.length < 2
      if ( pipeline.length is 1 ) and ( @isa_readonly_stream pipeline[ 0 ] )
        pipeline.push @$pass_through()
      else
        pipeline.unshift @$pass_through()
  #.........................................................................................................
  inspect = ->
    inner = ( insp p for p in pipeline ).join ' '
    return "PL #{inner} "
  return @_wrap_stream inspect, MSP.pipeline.obj pipeline...

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_text = ( text, hints, settings ) ->
  ### Given a text, return a stream that has `text` written into it; as soon as you `.pipe` it to some
  other stream or transformer pipeline, those parts will get to read the text. Unlike PipeDreams v2, the
  returned stream will not have to been resumed explicitly. ###
  throw new Error "_new_stream_from_text doesn't accept 'hints', got #{rpr hints}"        if hints?
  throw new Error "_new_stream_from_text doesn't accept 'settings', got #{rpr settings}"  if settings?
  unless ( type = CND.type_of text ) in [ 'text', 'buffer', ]
    throw new Error "expected text or buffer, got a #{type}"
  #.........................................................................................................
  R = @new_stream()
  R.write text
  R.end()
  return R

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_url = ( url, hints, settings ) ->
  url_parts       = ( require 'url' ).parse url
  { protocol
    hostname
    pathname }    = url_parts
  pathname       ?= '/'
  hostname       ?= 'localhost'
  debug '8090', url_parts
  unless ( protocol in [ 'http:', 'https:', ] ) and ( hostname.length > 0 ) and ( pathname.length > 0 )
    throw new Error "URL not supported: #{JSON.stringify url_parts}\n#{rpr url}"
  http_settings   = { hostname, pathname, protocol, followAllRedirects: yes, }
  R               = @new_stream()
  HTTP            = require if protocol is 'http:' then 'http' else 'https'
  request         = HTTP.request http_settings, ( response ) =>
    sink = @new_stream 'devnull'
    @on_finish sink, => @end R
    response
      .pipe @$ ( data, send ) =>
        @send R, data
        send data
      .pipe sink
    return null
  request.end()
  return R

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_transform = ( transform, hints, settings ) ->
  throw new Error "_new_stream_from_transform doesn't accept 'settings', got #{rpr settings}"  if settings?
  #.........................................................................................................
  hints ?= []
  #.........................................................................................................
  unless CND.is_subset hints, @_new_stream_from_transform._hints
    expected  = ( rpr x for x in @new_stream._hints                                  ).join ', '
    got       = ( rpr x for x in              hints when x not in @new_stream._hints ).join ', '
    throw new Error "expected 'hints' out of #{expected}, got #{got}"
  #.........................................................................................................
  return @$async transform if 'async' in hints
  return @$ transform

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_transform._hints = [ 'async', ]

#-----------------------------------------------------------------------------------------------------------
@$pass_through = -> @_wrap_stream 'PT', MSP.through.obj()


#===========================================================================================================
# ISA METHODS
#-----------------------------------------------------------------------------------------------------------
### thx to German Attanasio http://stackoverflow.com/a/28564000/256361 ###
@isa_stream           = ( x ) -> x instanceof ( require 'stream' ).Stream
@isa_readable_stream  = ( x ) -> ( @isa_stream x ) and x.readable
@isa_writable_stream  = ( x ) -> ( @isa_stream x ) and x.writable
@isa_readonly_stream  = ( x ) -> ( @isa_stream x ) and x.readable and not x.writable
@isa_writeonly_stream = ( x ) -> ( @isa_stream x ) and x.writable and not x.readable
@isa_duplex_stream    = ( x ) -> ( @isa_stream x ) and x.readable and     x.writable


#===========================================================================================================
# TRANSFORM CREATION
#-----------------------------------------------------------------------------------------------------------
@remit        = @$      = ( method ) -> @_new_remit  'sync', method
@remit_async  = @$async = ( method ) -> @_new_remit 'async', method

#-----------------------------------------------------------------------------------------------------------
@_new_remit = ( mode, method ) ->
  arity       = method.length
  throw new Error "method with #{arity} arguments not supported" unless arity in [ 1, 2, 3, ]
  throw new Error "unknown mode #{rpr mode}" unless mode in [ 'sync', 'async', ]
  has_error   = no
  flush       = null
  #.........................................................................................................
  if arity is 1
    throw new Error "method with #{arity} arguments not supported for async transforms" if mode is 'async'
    #.......................................................................................................
    main = ( chunk, encoding, callback ) ->
      method chunk
      callback null, chunk
    #.......................................................................................................
    flush = ( callback ) ->
      method null
      callback()
    #.......................................................................................................
    return @_wrap_stream 't', MSP.through.obj main, flush
  #.........................................................................................................
  if arity is 3
    flush = ( callback ) ->
      ### TAINT do we have to re-construct `send` on each call, or can we recycle the same function? ###
      send = get_send @, callback
      end  = ->
        callback() unless has_error
        return null
      method null, send, end
      return null
  #.........................................................................................................
  get_send = ( self, callback ) ->
    #.......................................................................................................
    R = ( data ) ->
      self.push data # if data?
    #.......................................................................................................
    R.error = ( error ) ->
      has_error = yes
      callback error
    #.......................................................................................................
    R.end = ->
      self.push null
    #.......................................................................................................
    if mode is 'async'
      R.done = ( data ) ->
        if data is undefined then callback() else callback null, data
    #.......................................................................................................
    return R
  #.........................................................................................................
  main = ( chunk, encoding, callback ) ->
    ### TAINT do we have to re-construct `send` on each call, or can we recycle the same function? ###
    send = get_send @, callback
    method chunk, send
    if mode is 'sync'
      callback() unless has_error
    return null
  #.....................................................................................................
  return @_wrap_stream 't', MSP.through.obj main, flush

#===========================================================================================================
# SENDING DATA
#-----------------------------------------------------------------------------------------------------------
@send = ( me, data ) ->
  ### Given a stream and some data, send / write / push that data into the stream. ###
  me.write data
  # me.push data
  return me

#-----------------------------------------------------------------------------------------------------------
@end = ( me ) ->
  ### Given a stream, end it. ###
  me.end()
  return me


#===========================================================================================================
# SPLITTING, JOINING, SORTING
#-----------------------------------------------------------------------------------------------------------
@$join = ( joiner = '\n' ) ->
  ### Join all strings in the stream using a `joiner`, which defaults to newline, so `$join` is the inverse
  of `$split()`. The current version only supports strings, but buffers could conceivably be made to work as
  well. ###
  return @new_stream pipeline: [
    @$ ( x ) => throw new Error "expected a text, got a #{type}" unless ( type = CND.type_of x ) is 'text'
    @$collect()
    @$ ( collection, send ) => send collection.join joiner
    ]
  return null

#-----------------------------------------------------------------------------------------------------------
@$split = ( settings ) ->
  ### TAINT should allow to specify splitter, encoding, keep binary format ###
  matcher   = settings?[ 'matcher'  ] ? '\n'
  encoding  = settings?[ 'encoding' ] ? 'utf-8'
  # debug '6654', settings, encoding
  throw new Error "expected a text, got a #{type}" unless ( type = CND.type_of matcher ) is 'text'
  R         = @_new_stream$split_buffer matcher
  return R if encoding is 'buffer'
  return @new_stream pipeline: [ R, ( @$decode encoding ), ]

#-----------------------------------------------------------------------------------------------------------
@$decode = ( encoding = 'utf-8' ) ->
  return @$ ( data, send ) =>
    return send data unless Buffer.isBuffer data
    send data.toString encoding

#-----------------------------------------------------------------------------------------------------------
@$sort = ( sorter, settings ) ->
  ### https://github.com/mziccard/node-timsort ###
  TIMSORT = require 'timsort'
  switch arity = arguments.length
    when 0, 2
      null
    when 1
      unless CND.isa_function sorter
        settings  = sorter
        sorter    = null
    else throw new Error "expected 0 to 2 arguments, got #{arity}"
  #.........................................................................................................
  collector = []
  collect   = settings?[ 'collect' ] ? no
  sorter   ?= ( a, b ) =>
    return +1 if a > b
    return -1 if a < b
    return  0
  #.........................................................................................................
  return @$ ( data, send, end ) =>
    collector.push data if data?
    if end?
      TIMSORT.sort collector, sorter
      if collect
        send collector
      else
        send x for x in collector
        collector.length = 0
      end()

#-----------------------------------------------------------------------------------------------------------
@$as_text = ( stringify ) ->
  ### Turn all data items into texts using `JSON.stringify` or a custom stringifier. `null` and any strings
  in the data stream is passed through unaffected. Observe that buffers in the stream will very probably not
  come out the way you'd expect them; this is because there's no way to know for the method what kind of
  data they represent.

  This method is handy to put as a safeguard right in front of a `.pipe output_file` clause to avoid
  `illegal non-buffer` issues. ###
  stringify ?= JSON.stringify
  return @$ ( data, send ) ->
    return send null if data is null
    return send stringify data unless CND.isa_text data
    send data

#-----------------------------------------------------------------------------------------------------------
@$as_line = ( stringify ) ->
  ### Like `$as_text`, but appends a newline to each chunk. ###
  pipeline = [
    ( @$as_text stringify )
    ( @$ ( text, send ) => send text + '\n' ) ]
  return @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@$parse_csv = ( options ) ->
  throw new Error "$parse_csv is on hold; investigating other libraries and extensibility"
  # field_names = null
  # options    ?= {}
  # headers     = options[ 'headers'    ] ? true
  # delimiter   = options[ 'delimiter'  ] ? ','
  # qualifier   = options[ 'qualifier'  ] ? '"'
  # ### http://stringjs.com ###
  # stringfoo   = require 'string'
  # #.........................................................................................................
  # return @$ ( record, send ) =>
  #   if record?
  #     values = ( stringfoo record ).parseCSV delimiter, qualifier, '\\'
  #     if headers
  #       if field_names is null
  #         field_names = values
  #       else
  #         record = {}
  #         record[ field_names[ idx ] ] = value for value, idx in values
  #         send record
  #     else
  #       send values


#===========================================================================================================
# LOCKSTEP
#-----------------------------------------------------------------------------------------------------------
@$lockstep = ( input, settings ) ->
  ### Usage:

  ```coffee
  input_1
    .pipe D.$lockstep input_2 # or `.pipe D.$lockstep input_2, fallback: null`
    .pipe $ ( [ data_1, data_2, ], send ) =>
      ...
  ```

  `$lockstep` combines each piece of data coming down the stream with one piece of data emitted from the
  stream you passed in when calling the function. If the two streams turn out to have unequal lengths,
  an error is sent into the stream unless you called the function with an additional `fallback: value`
  argument.
  ###
  #.........................................................................................................
  ### TAINT re-write in a less low-level fashion ###
  ### TAINT re-write to avoid buffering both streams ###
  #.........................................................................................................
  fallback  = settings?[ 'fallback' ]
  idx_1     = 0
  idx_2     = 0
  buffer_1  = []
  buffer_2  = []
  _send     = null
  _end_1    = null
  _end_2    = null
  has_ended = false
  #.........................................................................................................
  flush = =>
    #.......................................................................................................
    if _send?
      while ( buffer_1.length > 0 ) and ( buffer_2.length > 0 ) and idx_1 is idx_2
        _send [ buffer_1.shift(), buffer_2.shift(), ]
        idx_1 += +1
        idx_2 += +1
    #.......................................................................................................
    if _end_1? and _end_2?
      if ( buffer_1.length > 0 ) or ( buffer_2.length > 0 )
        for idx in [ 0 ... Math.max buffer_1.length, buffer_2.length ]
          data_1 = buffer_1[ idx ]
          data_2 = buffer_2[ idx ]
          if data_1 is undefined or data_2 is undefined
            if fallback is undefined
              return _send.error new Error "streams of unequal lengths and no fallback value given"
            data_1 = fallback if data_1 is undefined
            data_2 = fallback if data_2 is undefined
          _send [ data_1, data_2, ]
      _end_1()
      _end_2()
  #.........................................................................................................
  alert "must not use .on 'data' use .read(), see http://codewinds.com/blog/2013-08-04-nodejs-readable-streams.html"
  input.on 'data', ( data_2 ) =>
    buffer_2.push data_2
    flush()
  # input.on 'readable', =>
  #   data_2 = input.read()
  #   buffer_2.push data_2
  #   flush()
  #.........................................................................................................
  input.pipe @$on_end ( end ) =>
    _end_2 = end
    flush()
  #.........................................................................................................
  return @$ ( data_1, send, end ) =>
    _send   = send
    #.......................................................................................................
    if data_1?
      buffer_1.push data_1
      flush()
    #.......................................................................................................
    if end?
      _end_1 = end
      flush()



#===========================================================================================================
# SAMPLING / THINNING OUT
#-----------------------------------------------------------------------------------------------------------
@$sample = ( p = 0.5, options ) ->
  ### Given a `0 <= p <= 1`, interpret `p` as the *p*robability to *p*ick a given record and otherwise toss
  it, so that `$sample 1` will keep all records, `$sample 0` will toss all records, and
  `$sample 0.5` (the default) will toss (on average) every other record.

  You can pipe several `$sample()` calls, reducing the data stream to 50% with each step. If you know
  your data set has, say, 1000 records, you can cut down to a random sample of 10 by piping the result of
  calling `$sample 1 / 1000 * 10` (or, of course, `$sample 0.01`).

  Tests have shown that a data file with 3'722'578 records (which didn't even fit into memory when parsed)
  could be perused in a matter of seconds with `$sample 1 / 1e4`, delivering a sample of around 370
  records. Because these records are randomly selected and because the process is so immensely sped up, it
  becomes possible to develop regular data processing as well as coping strategies for data-overload
  symptoms with much more ease as compared to a situation where small but realistic data sets are not
  available or have to be produced in an ad-hoc, non-random manner.

  **Parsing CSV**: There is a slight complication when your data is in a CSV-like format: in that case,
  there is, with `0 < p < 1`, a certain chance that the *first* line of a file is tossed, but some
  subsequent lines are kept. If you start to transform the text line into objects with named values later in
  the pipe (which makes sense, because you will typically want to thin out largeish streams as early on as
  feasible), the first line kept will be mis-interpreted as a header line (which must come first in CSV
  files) and cause all subsequent records to become weirdly malformed. To safeguard against this, use
  `$sample p, headers: true` (JS: `$sample( p, { headers: true } )`) in your code.

  **Predictable Samples**: Sometimes it is important to have randomly selected data where samples are
  constant across multiple runs:

  * once you have seen that a certain record appears on the screen log, you are certain it will be in the
    database, so you can write a snippet to check for this specific one;

  * you have implemented a new feature you want to test with an arbitrary subset of your data. You're
    still tweaking some parameters and want to see how those affect output and performance. A random
    sample that is different on each run would be a problem because the number of records and the sheer
    bytecount of the data may differ from run to run, so you wouldn't be sure which effects are due to
    which causes.

  To obtain predictable samples, use `$sample p, seed: 1234` (with a non-zero number of your choice);
  you will then get the exact same
  sample whenever you re-run your piping application with the same stream and the same seed. An interesting
  property of the predictable sample is that—everything else being the same—a sample with a smaller `p`
  will always be a subset of a sample with a bigger `p` and vice versa. ###
  #.........................................................................................................
  unless 0 <= p <= 1
    throw new Error "expected a number between 0 and 1, got #{rpr p}"
  #.........................................................................................................
  ### Handle trivial edge cases faster (hopefully): ###
  return ( @$ ( record, send ) => send record ) if p == 1
  return ( @$ ( record, send ) => null        ) if p == 0
  #.........................................................................................................
  headers = options?[ 'headers'     ] ? false
  seed    = options?[ 'seed'        ] ? null
  count   = 0
  rnd     = rnd_from_seed seed
  #.........................................................................................................
  return @$ ( record, send ) =>
    count += 1
    send record if ( count is 1 and headers ) or rnd() < p


#===========================================================================================================
# AGGREGATION & DISSEMINATION
#-----------------------------------------------------------------------------------------------------------
@$count = ( on_end = null ) ->
  count = 0
  #.........................................................................................................
  return $ ( data, send, end ) ->
    if data?
      send data
      count += +1
    if end?
      if on_end? then on_end count, send else send count
      end()

#-----------------------------------------------------------------------------------------------------------
@$collect = ( on_end = null ) ->
  collector = []
  #.........................................................................................................
  return @$ ( data, send, end ) ->
    collector.push data if data?
    if end?
      send collector
      end()

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  # end       = settings?[ 'end'      ] ? no
  return @$ ( data, send ) =>
    unless type = ( CND.type_of data ) is 'list'
      return send.error new Error "expected a list, got a #{rpr type}"
    for value, idx in data
      send if indexed then [ idx, value, ] else value
    # send null if end
    return null

#-----------------------------------------------------------------------------------------------------------
@$batch = ( batch_size = 1000 ) ->
  throw new Error "buffer size must be non-negative integer, got #{rpr batch_size}" if batch_size < 0
  buffer = []
  #.........................................................................................................
  return @$ ( data, send, end ) =>
    if data?
      buffer.push data
      if buffer.length >= batch_size
        send buffer
        buffer = []
    if end?
      send buffer if buffer.length > 0
      end()


#===========================================================================================================
# STREAM START & END DETECTION
#-----------------------------------------------------------------------------------------------------------
@$on_end = ( method ) ->
  unless 0 <= ( arity = method.length ) <= 1
    throw new Error "expected method with 0 or 1 argument, got #{arity}"
  return @$ ( data, send, end ) ->
    send data
    if end?
      if arity is 1
        method end
      else
        method()
        end()

#-----------------------------------------------------------------------------------------------------------
@$on_start = ( method ) ->
  is_first = yes
  return @$ ( data, send ) ->
    method send if is_first
    is_first = no
    send data

#-----------------------------------------------------------------------------------------------------------
@$on_first = ( method ) ->
  is_first = yes
  unless ( arity = method.length ) is 2
    throw new Error "expected method with 2 arguments, got one with #{arity}"
  return @$ ( data, send ) ->
    if is_first
      method data, send
      is_first = no
    else
      send data

#-----------------------------------------------------------------------------------------------------------
@on_finish = ( stream, handler ) ->
  stream.on 'finish', => setImmediate handler

#-----------------------------------------------------------------------------------------------------------
@$on_finish = ( method ) ->
  R = @new_stream()
  @on_finish R, method
  return R


#===========================================================================================================
# FILTERING
#-----------------------------------------------------------------------------------------------------------
@$filter = ( method ) -> @$ ( data, send ) => send data if method data


#===========================================================================================================
# REPORTING
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  my_show = CND.get_logger 'info', badge ? '*'
  return @$ ( record, send ) =>
    my_show rpr record
    send record

# #-----------------------------------------------------------------------------------------------------------
# @$stop_time = ( badge_or_handler ) ->
#   t0 = null
#   return @$observe ( data, is_last ) =>
#     t0 = +new Date() if data? and not t0?
#     if is_last
#       dt = ( new Date() ) - t0
#       switch type = CND.type_of badge_or_handler
#         when 'function'
#           badge_or_handler dt
#         when 'text', 'jsundefined'
#           logger = CND.get_logger 'info', badge_or_handler ? 'stop time'
#           logger "#{(dt / 1000).toFixed 2}s"
#         else
#           throw new Error "expected function or text, got a #{type}"


#===========================================================================================================
# THROUGHPUT LIMITING
#-----------------------------------------------------------------------------------------------------------
@$throttle_bytes = ( bytes_per_second ) ->
  return @_wrap_stream "throttle #{bytes_per_second} bps", new ( require 'throttle' ) bytes_per_second

#-----------------------------------------------------------------------------------------------------------
@$throttle_items = ( items_per_second ) ->
  buffer    = []
  count     = 0
  idx       = 0
  _send     = null
  timer     = null
  has_ended = no
  #.........................................................................................................
  emit = ->
    if ( data = buffer[ idx ] ) isnt undefined
      buffer[ idx ] = undefined
      idx   += +1
      count += -1
      _send data
    #.......................................................................................................
    if has_ended and count < 1
      clearInterval timer
      _send.end()
      buffer = _send = timer = null # necessary?
    #.......................................................................................................
    return null
  #.........................................................................................................
  start = ->
    timer = setInterval emit, 1 / items_per_second * 1000
  #---------------------------------------------------------------------------------------------------------
  return @$ ( data, send, end ) =>
    if data?
      unless _send?
        _send = send
        start()
      buffer.push data
      count += +1
    #.......................................................................................................
    if end?
      has_ended = yes


#===========================================================================================================
# ERROR HANDLING
#-----------------------------------------------------------------------------------------------------------
@run = ( method, handler ) ->
  domain  = ( require 'domain' ).create()
  domain.on 'error', ( error ) -> handler error
  setImmediate -> domain.run method
  return domain


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
rnd_from_seed = ( seed ) ->
  ### TAINT use CND method ###
  return if seed? then CND.get_rnd seed else Math.random

#-----------------------------------------------------------------------------------------------------------
pluck = ( x, key ) ->
  ### TAINT use CND method ###
  R = x[ key ]
  delete x[ key ]
  return R


#===========================================================================================================
# BRIDGING
#-----------------------------------------------------------------------------------------------------------
@$bridge = ( stream ) ->
  ### Make it so that the pipeline may be continued even below a writable but not readable stream.
  Conceivably, this method could have be named `tunnel` as well. Something to get you across, you get the
  meaning. ###
  throw new Error "expected a single argument, got #{arity}"        unless ( arity = arguments.length ) is 1
  throw new Error "expected a stream, got a #{CND.type_of stream}"  unless @isa_stream stream
  throw new Error "expected a writable stream"                      if not @isa_writable_stream stream
  # return @new_stream pipeline: [ @$pass_through(), stream, ]
  return @$ ( data, send, end ) =>
    if data?
      stream.write data
      send data
    if end?
      stream.end()
      end()


#===========================================================================================================
# EXTRA MODULES
#-----------------------------------------------------------------------------------------------------------
@$split_tsv = ( require './transform-split-tsv' ).$split_tsv


#===========================================================================================================
# EXPORT
#-----------------------------------------------------------------------------------------------------------
do ( PIPEDREAMS = @ ) ->
  for key in Object.keys PIPEDREAMS
    if CND.isa_function value = PIPEDREAMS[ key ]
      PIPEDREAMS[ key ] = value.bind PIPEDREAMS
      for sub_key in Object.keys value
        PIPEDREAMS[ key ][ sub_key ] = value[ sub_key ]
    else
      PIPEDREAMS[ key ] = value


