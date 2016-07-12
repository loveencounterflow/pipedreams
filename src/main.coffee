

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


#===========================================================================================================
# STREAM-PRODUCING 3RD PARTY LIBRARIES
#...........................................................................................................
###

**Note** Conventions:

* Never call a stream/transform-producing 3rd party API from an arbitrary place in this or affiliate
  modules, but to always route such calls through a proxy method to be collected in the space below;

* Issue `require` 3rd party libraries in a 'lazy' fashion / on-demand (i.e. on API-method call time, not on
  module load time);

* Wrap all stream/transform creation calls so that printing of shorthand descriptions of pipelines becomes
  feasible. Printouts of unwrapped stream objects can extend over hundreds of lines and are nearly
  impossible to digest properly (in the future, a more sophisticated solution may be implemented, but even
  then and until such time, the wrapping is not going to hurt either).

###
#-----------------------------------------------------------------------------------------------------------
@_new_stream$read_from_file = ( path, settings )   ->
  R = ( require 'fs' ).createReadStream path, settings
  return @_rpr "*🖹 △", "FS read", ( rpr path ), R

#-----------------------------------------------------------------------------------------------------------
@_new_stream$write_to_file = ( path, settings )   ->
  R = ( require 'fs' ).createWriteStream path, settings
  return @_rpr "*🖹 ▼", "FS write", ( rpr path ), R

#-----------------------------------------------------------------------------------------------------------
@_new_stream$append_to_file = ( path, settings )   ->
  settings[ 'flags' ] = ( settings[ 'flags' ] ? '' ) + 'a'
  R = ( require 'fs' ).createWriteStream path, settings
  return @_rpr "*🖹 ⏬", "FS append", ( rpr path ), R

#-----------------------------------------------------------------------------------------------------------
@_new_stream$split_buffer = ( matcher ) ->
  R = ( require 'binary-split' ) matcher
  return @_rpr "*✀", "split", ( rpr matcher ), R

#-----------------------------------------------------------------------------------------------------------
@_new_stream$line_splitter = ( matcher ) ->
  R = ( require 'line-stream' ) matcher
  return @_rpr "*✀", "split", ( rpr matcher ), R

# #-----------------------------------------------------------------------------------------------------------
# @_new_stream$throttle_bytes = ( bytes_per_second ) ->
#   R = new ( require 'throttle' ) bytes_per_second
#   return @_rpr "⏳", "throttle", "#{bytes_per_second} B/s", R


#===========================================================================================================
# CONSTANTS
#-----------------------------------------------------------------------------------------------------------
@NULL = Symbol.for 'null'


#-----------------------------------------------------------------------------------------------------------
@_rpr = ( symbol, name, extra, stream ) ->
  throw new Error "expected 4 arguments, got #{arity}" unless ( arity = arguments.length ) is 4
  return @_rprx '(', symbol, name, extra, ')', stream

#-----------------------------------------------------------------------------------------------------------
@_rprx = ( start, symbol, name, extra, stop, stream ) ->
  throw new Error "expected 6 arguments, got #{arity}" unless ( arity = arguments.length ) is 6
  _symbols    = CND.yellow
  gl          = CND.gold
  _name       = CND.grey
  _brackets   = CND.white
  _sub        = CND.crimson
  _extra      = CND.orange
  sub_inspect = stream.inspect
  show_subs   = yes
  show_names  = no
  parts       = []
  parts.push _brackets start
  parts.push ' '
  parts.push _symbols symbol  if symbol?
  parts.push ' '              if symbol?
  parts.push _name name       if show_names
  parts.push ' '              if show_names
  parts.push _extra extra     if extra?
  parts.push ' '              if extra?
  parts.push _sub ' {='       if show_subs and sub_inspect?
  parts.push sub_inspect()       if show_subs and sub_inspect?
  parts.push _sub '=} '       if show_subs and sub_inspect?
  # parts.push ' '              if sub_inspect?
  parts.push _brackets stop
  # parts.push gy ","
  stream.inspect = -> parts.join ''
  return stream


#===========================================================================================================
# STREAM CREATION
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
  # echo '3345', ( CND.white rprd P ), ( CND.grey '=>' ), ( CND.lime rprd R )
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
  return @_rpr "#", "plain", null, MSP.through.obj()

#-----------------------------------------------------------------------------------------------------------
@_new_devnull_stream = ->
  x     = new Buffer "devnull\n"
  plug  = @new_stream()
  pipeline = [
    ( @$ ( data, send ) => send x; @send plug, data )
    ( @new_stream 'write', file: '/dev/null' )
    ( @$ ( data, send ) => null )
    plug
    ]
  return @_rpr "⏚", "devnull", null, @new_stream { pipeline, }

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
  ### TAINT must simplify handling of encoding as tag and in settings ###
  extra     = "#{rpr path}"
  _encoding = encoding ? settings[ 'encoding' ]
  extra    += ' ' + _encoding if _encoding?
  ### TAINT no choice between symbol or name, no colorization ###
  if use_line_mode
    if role is 'read' then  extra += ' ' + "✀"
    else                    extra += ' ' + "∮"
  if role is 'read'
    if use_line_mode
      return @_rpr "🖹 △", "file-read", extra, @new_stream pipeline: [
        ( @_new_stream$read_from_file path, settings )
        ( @$split { encoding, }                      )
        ]
    else
      settings[ 'encoding' ]?= if encoding is 'buffer' then null else encoding
      return @_rpr "🖹 △", "file-read", extra, @_new_stream$read_from_file path, settings
  #.........................................................................................................
  settings[ 'encoding' ]?= encoding unless encoding is 'buffer'
  #.........................................................................................................
  if role is 'append'
    R = @$bridge @_new_stream$append_to_file path, settings
    if use_line_mode
      return @_rpr "🖹 ⏬", "file-append", extra, @new_stream pipeline: [ @$as_line(), R, ]
    return @_rpr "🖹 ⏬", "file-append", extra, R
  #.........................................................................................................
  ### role is write ###
  R = @$bridge @_new_stream$write_to_file path, settings
  if use_line_mode
    return @_rpr "🖹 ▼", "file-write", extra, @new_stream pipeline: [ @$as_line(), R, ]
  return @_rpr "🖹 ▼", "file-write", extra, R
  #.........................................................................................................
  return null

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
  # #.........................................................................................................
  # ### The underlying implementation does not allow to get passed less than two streams, so we
  # add pass-through transforms to satisfy it: ###
  # if pipeline.length < 2
  #   pipeline  = Object.assign [], pipeline
  #   while pipeline.length < 2
  #     if ( pipeline.length is 1 ) and ( @isa_readonly_stream pipeline[ 0 ] )
  #       pipeline.push @$pass_through()
  #     else
  #       pipeline.unshift @$pass_through()
  # #.........................................................................................................
  # inner = ( rpr p for p in pipeline ).join ' '
  # return @_rprx "[", null, "pipeline", inner, "]", MSP.pipeline.obj pipeline...
  R = @new_stream()
  for transform in pipeline
    transform = @$bridge transform if @isa_readonly_stream transform
    R         = R.pipe transform
  return R

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
@$pass_through = -> @_rpr "⦵", "pass-through", null, MSP.through.obj()


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
@remit        = @$      = ( tags..., method ) -> @_new_remit tags,  'sync', method
@remit_async  = @$async = ( tags..., method ) -> @_new_remit tags, 'async', method

#-----------------------------------------------------------------------------------------------------------
@_new_remit = ( tags, mode, method ) ->
  throw new Error "unknown mode #{rpr mode}" unless mode in [ 'sync', 'async', ]
  #.........................................................................................................
  unless CND.is_subset tags, [ 'null', ]
    throw new Error "the only allowed tag is 'null', got #{rpr tags}"
  send_null   = 'null' in tags
  if send_null and mode is 'async'
    throw new Error "tag 'null' not allowed for asynchronous transforms"
  #.........................................................................................................
  has_error = no
  arity     = method.length
  if mode is 'sync'
    unless 1 <= arity <= 3
      throw new Error "method with #{arity} arguments not supported for synchronous transforms"
  else
    unless arity is 3
      throw new Error "method with #{arity} arguments not supported for asynchronous transforms"
  #.........................................................................................................
  if arity is 1
    #.......................................................................................................
    main = ( chunk, encoding, callback ) ->
      method chunk
      callback null, chunk
    #.......................................................................................................
    flush = ( callback ) ->
      method null if send_null
      callback()
    #.......................................................................................................
    return @_rpr "+", "$d", null, MSP.through.obj main, flush
  #.........................................................................................................
  else if arity is 2
    if send_null
      flush = ( callback ) ->
        send = get_send @, callback
        method null, send
        return null
    else
      flush = null
  #.........................................................................................................
  else if arity is 3
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
      # debug '4401', rpr data
      # urge '4402', ( rpr data.toString 'utf-8' ) if ( CND.type_of data ) is 'buffer'
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
  return @_rpr "⧺", "$ds",  null, MSP.through.obj main, flush if arity is 2
  return @_rpr "⧻", "$dse", null, MSP.through.obj main, flush

#===========================================================================================================
# SENDING DATA
#-----------------------------------------------------------------------------------------------------------
@send = ( me, data ) ->
  ### Given a stream and some data, send / write / push that data into the stream. ###
  ### NOTE using `push` over `write` since `push null` does work as expected. ###
  # me.write data
  me.push data
  return me

#-----------------------------------------------------------------------------------------------------------
@end = ( me ) ->
  ### Given a stream, end it. ###
  me.end()
  return me


#===========================================================================================================
# SPLITTING, JOINING, SORTING
#-----------------------------------------------------------------------------------------------------------
@$join = ( outer_joiner = '\n', inner_joiner = ', ' ) ->
  ### Join all strings and lists in the stream. `$join` accepts two arguments, an `outer_joiner` and an
  `inner_joiner`. Joining works in three steps: First, all list encountered in the stream are joined using
  the `inner_joiner`, turning each list into a string as a matter of course. In the second step, the entire
  stream data is collected into a list (using PipeDreams `$collect`). In the last step, that collection is
  turned into a single string by joining them with the `outer_joiner`. The `outer_joiner` defaults to a
  newline, the `inner_joiner` to a comma and a space. ###
  $f = => @$ ( data, send ) =>
    switch type = CND.type_of data
      when 'text' then send data
      when 'list' then send data.join inner_joiner
      else throw new Error "expected a text or a list, got a #{type}"
  return @_rpr "join", "join", "#{rpr outer_joiner} #{rpr inner_joiner}",  @new_stream pipeline: [
    $f()
    @$collect()
    @$ ( collection, send ) => send collection.join outer_joiner
    ]
  return null

#-----------------------------------------------------------------------------------------------------------
@$split = ( settings ) ->
  matcher   = settings?[ 'matcher'  ] ? '\n'
  encoding  = settings?[ 'encoding' ] ? 'utf-8'
  throw new Error "expected a text, got a #{type}" unless ( type = CND.type_of matcher ) is 'text'
  R         = @_new_stream$split_buffer matcher
  extra     = rpr matcher
  extra    += " #{encoding}" unless encoding is 'buffer'
  return @_rpr "✀", "split", extra, R if encoding is 'buffer'
  return @_rpr "✀", "split", extra, @new_stream pipeline: [ R, ( @$decode encoding ), ]

#-----------------------------------------------------------------------------------------------------------
@$split_2 = ( settings ) ->
  matcher     = settings?[ 'matcher'  ] ? '\n'
  throw new Error "expected a text, got a #{type}" unless ( type = CND.type_of matcher ) is 'text'
  strip       = settings?[ 'strip'    ] ? yes and matcher.length > 0
  encoding    = settings?[ 'encoding' ] ? 'utf-8'
  #.........................................................................................................
  if strip
    matcher_bfr = if ( Buffer.isBuffer matcher ) then matcher else new Buffer matcher, 'utf-8'
  #.........................................................................................................
  splitter    = @_new_stream$line_splitter matcher
  output      = @new_stream()
  splitter.on 'data',      ( data ) => debug '4432-1', rpr data; @send  output, data
  splitter.on 'fragment',  ( data ) => debug '4432-2', rpr data; @send  output, data
  splitter.on 'end',                => @end   output
  pipeline    = []
  pipeline.push MSP.duplex splitter, output
  #.........................................................................................................
  if strip
    pipeline.push @$ ( data, send ) =>
      position = data.length - matcher_bfr.length
      return send data unless data.includes matcher_bfr, position
      send data.slice 0, position
  #.........................................................................................................
  pipeline.push @$decode encoding unless encoding is 'buffer'
  extra       = rpr matcher
  extra      += " #{encoding}" unless encoding is 'buffer'
  return @_rpr "✀", "split", extra, @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@$decode = ( encoding = 'utf-8' ) ->
  return @_rpr "?", "decode", encoding, @$ ( data, send ) =>
    return send data unless Buffer.isBuffer data
    send data.toString encoding

#-----------------------------------------------------------------------------------------------------------
@$sort = ( settings ) ->
  ### https://github.com/mziccard/node-timsort ###
  TIMSORT   = require 'timsort'
  direction = 'ascending'
  sorter    = null
  key       = null
  switch arity = arguments.length
    when 0 then null
    when 1
      direction = settings[ 'direction' ] ? 'ascending'
      sorter    = settings[ 'sorter'    ] ? null
      key       = settings[ 'key'       ] ? null
    else throw new Error "expected 0 or 1 arguments, got #{arity}"
  #.........................................................................................................
  unless direction in [ 'ascending', 'descending', ]
    throw new Error "expected 'ascending' or 'descending' for direction, got #{rpr direction}"
  #.........................................................................................................
  unless sorter?
    #.......................................................................................................
    type_of = ( x ) =>
      ### NOTE for the purposes of magnitude comparison, `Infinity` can be treated as a number: ###
      R = CND.type_of x
      return if R is 'infinity' then 'number' else R
    #.......................................................................................................
    validate_type = ( type_a, type_b, include_list = no ) =>
      unless type_a is type_b
        throw new Error "unable to compare a #{type_a} with a #{type_b}"
      if include_list
        unless type_a in [ 'number', 'date', 'text', 'list', ]
          throw new Error "unable to compare values of type #{type_a}"
      else
        unless type_a in [ 'number', 'date', 'text', ]
          throw new Error "unable to compare values of type #{type_a}"
      return null
    #.......................................................................................................
    if key?
      sorter = ( a, b ) =>
        a = a[ key ]
        b = b[ key ]
        validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
    #.......................................................................................................
    else
      sorter = ( a, b ) =>
        validate_type ( type_a = type_of a ), ( type_b = type_of b ), yes
        if type_a is 'list'
          a = a[ 0 ]
          b = b[ 0 ]
          validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
  #.........................................................................................................
  $sort = =>
    collector = []
    return @$ ( data, send, end ) =>
      collector.push data if data?
      if end?
        TIMSORT.sort collector, sorter
        send x for x in collector
        collector.length = 0
        end()
      return null
  #.........................................................................................................
  return @_rpr "⮃", "sort", null, $sort()

# #-----------------------------------------------------------------------------------------------------------
# @$sort.from_keys = ( keys... ) ->
#   R = ( a, b ) =>
#     for key in keys
#       return +1 if a[ key ] > b[ key ]
#       return -1 if a[ key ] < b[ key ]
#     return 0

#-----------------------------------------------------------------------------------------------------------
@$as_list = ( names... ) ->
  ### Turn named attributes into list of values. ###
  return @$ ( data, send ) ->
    send ( data[ name ] for name in names )
    return null

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
    return send stringify data unless CND.isa_text data
    send data

#-----------------------------------------------------------------------------------------------------------
@$stringify = ( stringify ) ->
  ### Turn all data items into their JSON representations. ###
  if stringify?
    return @$ ( data, send ) =>
      data = stringify data
      unless ( type = CND.type_of data ) in [ 'null', 'text', ]
        return send.error new Error "expected a text or `null`, got a #{type}"
  return @$ ( data, send ) =>
    return send 'null' if data is @NULL
    if ( CND.type_of data ) is 'symbol'
      data = { '~isa': 'symbol', value: ( data.toString().replace /^Symbol\((.*)\)$/, '$1' ) }
    send JSON.stringify data

#-----------------------------------------------------------------------------------------------------------
@$transform = ( method ) -> @$ ( data, send ) -> send method data

#-----------------------------------------------------------------------------------------------------------
@$as_line = ( stringify ) ->
  ### Like `$as_text`, but appends a newline to each chunk. ###
  pipeline = [
    ( @$as_text stringify )
    ( @$ ( text, send ) => send text + '\n' ) ]
  return @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@$intersperse = ( joiners... ) ->
  ### Similar to `$join`, but inserts events between (and around) existing events. ###
  throw new Error "expected 0 to 3 joiners, got #{arity}" unless 0 <= ( arity = arguments.length ) <= 3
  return @$pass_through() if arity is 0
  return @$pass_through() if joiners[ 0 ] == ( joiners[ 1 ] ? null ) == ( joiners[ 2 ] ? null )
  #.........................................................................................................
  cache             = null
  call_joiner       = no
  first_joiner      = null
  mid_joiner        = null
  last_joiner       = null
  call_first_joiner = no
  call_mid_joiner   = no
  call_last_joiner  = no
  _first_joiner     = null
  _mid_joiner       = null
  _last_joiner      = null
  #.........................................................................................................
  do =>
    for joiner, idx in joiners
      switch idx
        when 0
          mid_joiner          = joiner
          call_mid_joiner     = CND.isa_function joiner
        when 1
          first_joiner        = last_joiner      = mid_joiner
          call_first_joiner   = call_last_joiner = call_mid_joiner
          mid_joiner          = joiner
          call_mid_joiner     = CND.isa_function joiner
        when 2
          last_joiner         = joiner
          call_last_joiner    = CND.isa_function joiner
  #.........................................................................................................
  _first_joiner     = ( ( send, a, b ) => if ( Z = first_joiner a, b )? then send Z ) if call_first_joiner
  _mid_joiner       = ( ( send, a, b ) => if ( Z = mid_joiner   a, b )? then send Z ) if call_mid_joiner
  _last_joiner      = ( ( send, a, b ) => if ( Z = last_joiner  a, b )? then send Z ) if call_last_joiner
  #.........................................................................................................
  R = @$ ( data, send, end ) =>
    if data?
      if cache?
        send cache
        if mid_joiner?
          if call_mid_joiner    then _mid_joiner send, cache, data
          else                       send mid_joiner
      else
        if first_joiner?
          if call_first_joiner  then _first_joiner send, null, data
          else                       send first_joiner
      cache = data
    if end?
      if cache?
        send cache
        if last_joiner?
          if call_last_joiner   then _last_joiner send, data, null
          else                       send last_joiner
      cache = null
      end()
  #.........................................................................................................
  extra = []
  extra.push rpr first_joiner if first_joiner?
  extra.push rpr mid_joiner   if   mid_joiner?
  extra.push rpr last_joiner  if  last_joiner?
  extra = extra.join ' '
  return @_rpr "intersperse", "intersperse", extra, R

#-----------------------------------------------------------------------------------------------------------
@$as_json_list = ( tags... ) ->
  if ( pretty = 'pretty' in tags ) and ( arity = tags.length ) > 1
    throw new Error "expected at most single tag 'pretty', go #{rpr tags}"
  if pretty then  intersperse = @$intersperse '[\n  ', ',\n  ', '\n  ]\n'
  else            intersperse = @$intersperse '[', ',', ']'
  translate_null  = @$ ( data, send ) => send if data is @NULL then 'null' else data
  R = @new_stream pipeline: [
    ( @$stringify()   )
    ( intersperse     )
    ( translate_null  )
    ( @$join ''       ) ]
  return @_rpr "as_json_list", "as_json_list", ( if pretty then "pretty" else null ), R


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
  input.pipe @$ ( data, send, end ) =>
    send data if data
    if end?
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
  return @_rpr "⚞", "collect", null, @$ ( data, send, end ) ->
    collector.push data if data?
    if end?
      send collector
      end()

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  # end       = settings?[ 'end'      ] ? no
  return @_rpr "⚟", "spread", null, @$ ( data, send ) =>
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
@$on_start = ( method ) ->
  is_first = yes
  return @$ ( data, send ) ->
    method send if is_first
    is_first = no
    send data

#-----------------------------------------------------------------------------------------------------------
@$on_stop = ( method ) ->
  unless 0 <= ( arity = method.length ) <= 1
    throw new Error "expected method with up to 1 argument, got one with #{arity}"
  cache = null
  return @$ ( data, send, end ) ->
    if data?
      send cache if cache?
      cache = data
    if end?
      send cache if cache?
      cache = null
      if arity is 0 then method() else method send
      end()

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
@$on_last = ( method ) ->
  unless ( arity = method.length ) is 2
    throw new Error "expected method with 2 argument, got one with #{arity}"
  cache = null
  return @$ ( data, send, end ) ->
    if data?
      send cache if cache?
      cache = data
    if end?
      method cache, send
      cache = null
      end()

#-----------------------------------------------------------------------------------------------------------
@on_finish = ( stream, handler ) ->
  # stream.on 'finish', => setImmediate handler
  stream.on 'finish', => setImmediate => handler()

# #-----------------------------------------------------------------------------------------------------------
# @$finish = ( stream, handler ) ->
#   MSP.finished stream, handler
#   # @on_finish stream, handler
#   return stream

#-----------------------------------------------------------------------------------------------------------
@$on_finish = ( method ) ->
  ### NOTE For reason not well understood, using `@new_stream()` here instead ov a `devnull` stream
  will in some cases not work, as the finish event never fires. ###
  R = @new_stream 'devnull'
  @on_finish R, method
  return R

#-----------------------------------------------------------------------------------------------------------
@$on_end = ( method ) ->
  unless 0 <= ( arity = method.length ) <= 1
    throw new Error "expected method with 0 or 1 argument, got #{arity}"
  return @$ ( data, send, end ) ->
    alert "Use of PipeDreams `$on_end` is discouraged; use `$on_stop`/`$on_last` instead"
    send data
    if end?
      if arity is 1
        method end
      else
        method()
        end()

#===========================================================================================================
# FILTERING
#-----------------------------------------------------------------------------------------------------------
@$filter = ( method ) -> @$ ( data, send ) => send data if method data



#===========================================================================================================
# REPORTING & BENCHMARKS
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  my_show = CND.get_logger 'info', badge ? '*'
  return @$ ( record, send ) =>
    my_show rpr record
    send record

#-----------------------------------------------------------------------------------------------------------
@$benchmark = ( title = null ) ->
  t0                            = null
  me                            = {}
  me.n                          = 0
  me.dt                         = null
  me.rps                        = null
  me.title                      = title ? "№#{( Object.keys @$benchmark.registry ).length}"
  @$benchmark.registry[ title ] = me
  R                             = @new_stream()
  #.........................................................................................................
  R.on 'data', =>
    t0  ?= +new Date()
    me.n += 1
    echo title, me.n if me.n % 10000 is 0
  #.........................................................................................................
  R.on 'finish', =>
    me.dt  = ( new Date() - t0 ) / 1000
    me.rps = me.n / me.dt
    @$benchmark._report me
  return R

# #-----------------------------------------------------------------------------------------------------------
# @$benchmark.$summarize = =>
#   R = @new_stream()
#   R.on 'finish', => @$benchmark.summarize()
#   return R

#-----------------------------------------------------------------------------------------------------------
@$benchmark.summarize = =>
  urge "Benchmarks summary:"
  @$benchmark._report me for _, me of @$benchmark.registry

#-----------------------------------------------------------------------------------------------------------
@$benchmark._report = ( me ) =>
  n   = CND.format_number me.n
  dt  = me.dt.toFixed  3
  rps = me.rps.toFixed 3
  info CND.steel "#{me.title}: #{n} records in #{dt} s (#{rps} r/s)"
  return null

#-----------------------------------------------------------------------------------------------------------
@$benchmark.registry = {}


#===========================================================================================================
# THROUGHPUT LIMITING
#-----------------------------------------------------------------------------------------------------------
@$throttle_bytes = ( bytes_per_second ) ->
  throw new Error "$throttle_bytes on hold"
  # return @_new_stream$throttle_bytes bytes_per_second

#-----------------------------------------------------------------------------------------------------------
@$throttle_items = ( items_per_second ) ->
  throw new Error "$throttle_items on hold"
  # buffer    = []
  # count     = 0
  # idx       = 0
  # _send     = null
  # timer     = null
  # has_ended = no
  # #.........................................................................................................
  # emit = ->
  #   if ( data = buffer[ idx ] ) isnt undefined
  #     buffer[ idx ] = undefined
  #     idx   += +1
  #     count += -1
  #     _send data
  #   #.......................................................................................................
  #   if has_ended and count < 1
  #     clearInterval timer
  #     _send.end()
  #     buffer = _send = timer = null # necessary?
  #   #.......................................................................................................
  #   return null
  # #.........................................................................................................
  # start = ->
  #   timer = setInterval emit, 1 / items_per_second * 1000
  # #---------------------------------------------------------------------------------------------------------
  # return @$ ( data, send, end ) =>
  #   if data?
  #     unless _send?
  #       _send = send
  #       start()
  #     buffer.push data
  #     count += +1
  #   #.......................................................................................................
  #   if end?
  #     has_ended = yes


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
  output      = @_rpr "output",     "output",     null, @new_stream()
  # throughput  = @_rpr "throughput", "throughput", null, @$ ( data, send, end ) =>
  throughput  = @$ ( data, send, end ) =>
    if data?
      send data
      output.write data
    if end?
      end()
      output.end()
  bridge = @new_stream pipeline: [
    throughput
    stream
    ]
  extra = ( rpr bridge ) + ' ↝ ' + ( rpr output )
  return @_rpr "↷", "bridge", extra, MSP.duplex.obj bridge, output


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


