

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


#===========================================================================================================
# STREAM CREATION
#-----------------------------------------------------------------------------------------------------------
@new_stream = ( settings ) ->
  return MSP.through.obj() if ( not settings? ) or ( keys = Object.keys ).length is 0
  return @new_stream_from_file     file,     settings if ( file     = pluck settings, 'file'     )?
  return @new_stream_from_text     text,     settings if ( text     = pluck settings, 'text'     )?
  return @new_stream_from_pipeline pipeline, settings if ( pipeline = pluck settings, 'pipeline' )?
  expected  = ( rpr key for key in @new_stream.keys ).join ', '
  got       = ( rpr key for key in             keys ).join ', '
  throw new Error "expected one of #{expected}, got #{got}"

#-----------------------------------------------------------------------------------------------------------
@$pass_through = -> MSP.through.obj()

#-----------------------------------------------------------------------------------------------------------
@new_stream.keys = [
  'file'
  'text'
  'pipeline' ]

#-----------------------------------------------------------------------------------------------------------
pluck = ( x, key ) ->
  R = x[ key ]
  delete x[ key ]
  return R

#-----------------------------------------------------------------------------------------------------------
@new_stream_from_text = ( text, settings ) ->
  ### Given a text, return a stream that has `text` written into it; as soon as you `.pipe` it to some
  other stream or transformer pipeline, those parts will get to read the text. Unlike PipeDreams v2, the
  returned stream will not have to been resumed explicitly. ###
  R = @new_stream()
  R.write text
  R.end()
  return R

#-----------------------------------------------------------------------------------------------------------
@new_stream_from_pipeline = ( pipeline, settings ) ->
  ### Given a list of transforms (a.k.a. a 'pipeline'), return a stream that has all the transforms
  successively linked with `.pipe` calls; writing to the stream will write to the first transform, and
  reading from the stream will read from the last transform. If the pipeline is an empty list,
  a simple `through2` stream is returned. ###
  throw new Error "expected a list, got a #{type}" unless ( type = CND.type_of pipeline ) is 'list'
  source  = MSP.through.obj()
  return source if pipeline.length is 0
  sink    = source
  for transform, idx in pipeline
    sink = sink.pipe transform
  return MSP.duplex source, sink, objectMode: true

#-----------------------------------------------------------------------------------------------------------
### thx to German Attanasio http://stackoverflow.com/a/28564000/256361 ###
@isa_stream = ( x ) -> x instanceof ( require 'stream' ).Stream


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
    return MSP.through.obj main, flush
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
  return MSP.through.obj main, flush


#===========================================================================================================
# SENDING DATA
#-----------------------------------------------------------------------------------------------------------
@send = ( me, data ) ->
  me.write data
  return me

#-----------------------------------------------------------------------------------------------------------
@end = ( me ) ->
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
@$split = ( matcher, mapper, settings ) ->
  ### https://github.com/mcollina/split2 ###
  return ( require 'split2' ) matcher, mapper, settings

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
@$parse_csv = ( options ) ->
  field_names = null
  options    ?= {}
  headers     = options[ 'headers'    ] ? true
  delimiter   = options[ 'delimiter'  ] ? ','
  qualifier   = options[ 'qualifier'  ] ? '"'
  ### http://stringjs.com ###
  stringfoo   = require 'string'
  #.........................................................................................................
  return @$ ( record, send ) =>
    if record?
      values = ( stringfoo record ).parseCSV delimiter, qualifier, '\\'
      if headers
        if field_names is null
          field_names = values
        else
          record = {}
          record[ field_names[ idx ] ] = value for value, idx in values
          send record
      else
        send values

#-----------------------------------------------------------------------------------------------------------
@$split_tsv = ( settings ) ->
  ### A fairly complex stream transform to help in reading files with data in
  [Tab-Separated Values (TSV)](http://www.iana.org/assignments/media-types/text/tab-separated-values)
  format.

  * `comments` defines how to recognize a comment. If it is a string, lines (or fields, when `first:
    'split'` has been specified) that start with the specified text are left out of the results.
    It is also possible to use a RegEx or a custom function to recognize comments.

  * `trim`: `false` for no trimming, `true` for trimming both ends of each line (with `first: 'trim'`)
    or each field (with `first: 'split'`).

  * `first`: either `'trim'` or `'split'`. No effect with `trim: false`; otherwise, indicates whether
    first the line is trimmed (which means that leading and trailing tabs are also removed), or whether
    we should first split into lines, and then trim each field individually. The `first: 'trim'` method—the
    default—is faster, but it may conflate empty fields if there are any. The `first: 'split'` method
    will first split each line using the `splitter` setting, and then trim all the fields individually.
    This has the side-effect that comments (as field values on their own, not when tacked unto a non-comment
    value) are reliably recognized and sorted out (when `comments` is set to a sensible value).

  * `splitter` defines one or more characters to split each line into fields.

  * When `empty` is set to `false`, empty lines (and lines that contain nothing but empty fields) are
    left in the stream.
  ###
  first           =       settings?[ 'first'      ] ? 'trim' # or 'split'
  trim            =       settings?[ 'trim'       ] ? yes
  splitter        =       settings?[ 'splitter'   ] ? '\t'
  skip_empty      = not ( settings?[ 'empty'      ] ? no )
  comment_pattern =       settings?[ 'comments'   ] ? '#'
  use_names       =       settings?[ 'names'      ] ? null
  #.........................................................................................................
  unless first in [ 'trim', 'split', ]
    throw new Error "### MEH ###"
  #.........................................................................................................
  ### TAINT may want to allow custom function to do trimming ###
  switch trim
    when yes
      if first is 'trim'
        $trim = => @$ ( line, send ) =>
          send line.trim()
      else
        $trim = => @$ ( fields, send ) =>
          fields[ idx ] = field.trim() for field, idx in fields
          send fields
    when no then null
    else throw new Error "### MEH ###"
  #.........................................................................................................
  ### TAINT may want to specify empty lines, fields ###
  unless skip_empty in [ true, false, ]
    throw new Error "### MEH ###"
  #.........................................................................................................
  switch type = CND.type_of comment_pattern
    when 'null', 'undefined'  then comments =  no; is_comment = ( text ) -> no
    when 'text'               then comments = yes; is_comment = ( text ) -> text.startsWith comment_pattern
    when 'regex'              then comments = yes; is_comment = ( text ) -> comment_pattern.test text
    when 'function'           then comments = yes; is_comment = ( text ) -> not not comment_pattern text
    else throw new Error "### MEH ###"
  #.........................................................................................................
  if first is 'trim'
    $skip_comments = => @$ ( line, send ) =>
      send line unless is_comment line
  else
    $skip_comments = => @$ ( fields, send ) =>
      for field, idx in fields
        # urge '7765', idx, ( rpr field ), is_comment field
        continue unless is_comment field
        fields.length = idx
        break
      send fields unless skip_empty and fields.length is 0
  #.........................................................................................................
  if skip_empty
    $skip_empty_lines = => @$ ( line, send ) => send line if line.length > 0
    if first is 'split'
      $skip_empty_fields = => @$ ( fields, send ) =>
        for field in fields
          continue if field.length is 0
          send fields
          break
        return null
  #.........................................................................................................
  use_names = null if use_names is no
  if use_names?
    names = null
    #.......................................................................................................
    if CND.isa_list use_names
      names = use_names
      $name_fields = =>
        return @$ ( fields, send ) =>
          send name_fields fields
    #.......................................................................................................
    else if use_names in [ 'inline', yes, ]
      $name_fields = =>
        is_first  = yes
        return @$ ( fields, send ) =>
          return send name_fields fields unless is_first
          is_first  = no
          names     = fields
    #.......................................................................................................
    else
      throw new Error "expected setting names to be true, false, 'inline', or a list; got #{rpr use_names}"
    #.......................................................................................................
    use_names   = yes
    name_fields = ( fields ) =>
      R = {}
      for field, idx in fields
        R[ names[ idx ] ? "field-#{idx}" ] = field
      return R
  #.........................................................................................................
  unless ( type_of_splitter = CND.type_of splitter ) in [ 'text', 'regex', 'function', ]
    throw new Error "### MEH ###"
  throw new Error "splitter as function no yet implemented" if type_of_splitter is 'function'
  $split_line = =>
    return @$ ( line, send ) =>
      send line.split splitter
  #.........................................................................................................
  pipeline = []
  pipeline.push @$split()
  pipeline.push $trim()               if first is 'trim'
  pipeline.push $skip_empty_lines()   if skip_empty
  pipeline.push $skip_comments()      if first is 'trim' and comments
  pipeline.push $split_line()
  pipeline.push $trim()               if first is 'split'
  pipeline.push $skip_comments()      if first is 'split' and comments
  pipeline.push $skip_empty_fields()  if first is 'split' and skip_empty
  pipeline.push $name_fields()        if use_names
  # pipeline.push @$ ( data ) => debug '3', JSON.stringify data if data?
  #.........................................................................................................
  return @new_stream { pipeline, }


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

#-----------------------------------------------------------------------------------------------------------
@$stop_time = ( badge_or_handler ) ->
  t0 = null
  return @$observe ( data, is_last ) =>
    t0 = +new Date() if data? and not t0?
    if is_last
      dt = ( new Date() ) - t0
      switch type = CND.type_of badge_or_handler
        when 'function'
          badge_or_handler dt
        when 'text', 'jsundefined'
          logger = CND.get_logger 'info', badge_or_handler ? 'stop time'
          logger "#{(dt / 1000).toFixed 2}s"
        else
          throw new Error "expected function or text, got a #{type}"


#===========================================================================================================
# THROUGHPUT LIMITING
#-----------------------------------------------------------------------------------------------------------
@$throttle_bytes = ( bytes_per_second ) ->
  return new ( require 'throttle' ) bytes_per_second

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
### TAINT use CND method ###
rnd_from_seed = ( seed ) ->
  return if seed? then CND.get_rnd seed else Math.random


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


