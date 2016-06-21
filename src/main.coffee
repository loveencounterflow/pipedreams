

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
stringfoo                 = require 'string'

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
@new_file_readstream = ->          throw new Error "new_file_readstream not implemented"
@new_file_readlinestream = ->      throw new Error "new_file_readlinestream not implemented"
@new_file_writestream = ->         throw new Error "new_file_writestream not implemented"

#-----------------------------------------------------------------------------------------------------------
### thx to German Attanasio http://stackoverflow.com/a/28564000/256361 ###
@isa_stream = ( x ) -> x instanceof ( require 'stream' ).Stream

#===========================================================================================================
# TRANSFORM CREATION
#-----------------------------------------------------------------------------------------------------------
@remit = @$ = ( method ) ->
  arity       = method.length
  throw new Error "method with #{arity} arguments not supported" unless arity in [ 1, 2, 3, ]
  has_error   = no
  flush       = null
  #.........................................................................................................
  if arity is 1
    main = ( chunk, encoding, callback ) ->
      method chunk
      callback null, chunk
    flush = ( callback ) ->
      method null
      callback()
    return MSP.through.obj main, flush
  #.........................................................................................................
  if arity is 3
    flush = ( callback ) ->
      send = get_send @, callback
      end  = ->
        callback() unless has_error
        return null
      method null, send, end
      return null
  #.........................................................................................................
  get_send = ( self, callback ) ->
    ### TAINT do we have to re-construct `send` on each call, or can we recycle the same function? ###
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
    return R
  #.........................................................................................................
  main = ( chunk, encoding, callback ) ->
    send = get_send @, callback
    method chunk, send
    callback() unless has_error
    return null
  #.....................................................................................................
  return MSP.through.obj main, flush

#-----------------------------------------------------------------------------------------------------------
@$async_v4 = ( method ) ->



# #-----------------------------------------------------------------------------------------------------------
# @$async_v4 = ( method ) ->
#   unless 2 <= ( arity = method.length ) <= 3
#     throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
#   #.........................................................................................................
#   # Z                 = []
#   has_end_argument  = arity is 3
#   _send_end         = null
#   _stream_end       = null
#   #.........................................................................................................

#   #.........................................................................................................
#   return @new_stream_from_pipeline []

# #-----------------------------------------------------------------------------------------------------------
# @_$async_single = ( method ) ->
#   unless ( arity = method.length ) is 2
#     throw new Error "expected a method with an arity of 2, got one with an arity of #{arity}"
#   return $map ( input_data, handler ) =>
#     done        = ( output_data ) => if output_data? then handler null, output_data else handler()
#     done.error  = ( error )       => handler error
#     method input_data, done

# #-----------------------------------------------------------------------------------------------------------
# @$async = ( method ) ->
#   unless 2 <= ( arity = method.length ) <= 3
#     throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
#   #.........................................................................................................
#   Z                 = []
#   has_end_argument  = arity is 3
#   input             = @new_stream()
#   output            = @new_stream()
#   _send_end         = null
#   _stream_end       = null
#   #.........................................................................................................
#   $wait_for_stream_end = =>
#     return @$ ( data, send, end ) =>
#       send data if data?
#       # debug '7765', ( CND.truth CND.isa_function send.end )
#       _send_end = send.end
#       if end?
#         if has_end_argument then  _stream_end = end
#         else                      end()
#   #.........................................................................................................
#   $call = =>
#     return @_$async_single ( event, done ) =>
#       #.....................................................................................................
#       _send = ( data ) =>
#         Z.push data
#         return null
#       #.....................................................................................................
#       _send.done = ( data ) =>
#         _send data if data?
#         done Object.assign [], Z
#         Z.length = 0
#       #.....................................................................................................
#       _send.end = _send_end
#       #.....................................................................................................
#       method event, _send, _stream_end
#       return null
#   #.........................................................................................................
#   $spread = =>
#     return @$ ( collection, send, end ) =>
#       send event for event in collection
#       if end?
#         end()
#   #.........................................................................................................
#   input
#     .pipe $wait_for_stream_end()
#     .pipe $call()
#     .pipe $spread()
#     .pipe output
#   #.........................................................................................................
#   return @new_stream pipeline: [ input, output, ]

# #-----------------------------------------------------------------------------------------------------------
# @$async_OLD = ( method ) ->
#   unless ( arity = method.length ) is 2
#     throw new Error "expected a method with an arity of 2, got one with an arity of #{arity}"
#   return $map ( input_data, handler ) =>
#     ### TAINT should add `done.end`, `done.pause` and so on ###
#     done        = ( output_data ) => if output_data? then handler null, output_data else handler()
#     done.error  = ( error )       => handler error
#     method input_data, done

#-----------------------------------------------------------------------------------------------------------
@$bridge = ( stream ) ->
  ### Make it so that the pieline may be continued even below a writable but not readable stream. ###
  throw new Error "expected a single argument, got #{arity}"        unless ( arity = arguments.length ) is 1
  throw new Error "expected a stream, got a #{CND.type_of stream}"  unless @isa_stream stream
  throw new Error "expected a writable stream"                      if not stream.writable
  throw new Error "expected a writable, non-readable stream"        if     stream.readable
  #.........................................................................................................
  return @$ ( data, send, end ) =>
    if data?
      stream.write data
      send data
    if end?
      stream.end() unless stream is process.stdout
      # throw error unless ( message = error[ 'message' ] )? and message.endsWith "cannot be closed."
      end()

#===========================================================================================================
# SPLITTING & JOINING
#-----------------------------------------------------------------------------------------------------------
@$join = ( joiner = '\n' ) ->
  ### Join all strings in the stream using a `joiner`, which defaults to newline, so `$join` is the inverse
  of `$split()`. The current version only supports strings, but buffers could conceivably be made to work as
  well. ###
  return @combine [
    @$collect()
    @$ ( collection, send ) =>
      send collection.join joiner
    ]
  return null


#===========================================================================================================
# COMBINING STREAM TRANSFORMS
#-----------------------------------------------------------------------------------------------------------
@combine = ( transforms... ) ->
  warn message = "combine is deprecated; use new_stream_from_pipeline instead"
  throw new Error message
  return combine transforms...


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
  fallback  = settings?[ 'fallback' ]
  idx_1     = 0
  idx_2     = 0
  buffer_1  = []
  buffer_2  = []
  _send     = null
  _end_1    = null
  _end_2    = null
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
# SPECIALIZED STREAMS
# #-----------------------------------------------------------------------------------------------------------
# @spawn_and_read = ( P... ) ->
#   ### from https://github.com/alessioalex/spawn-to-readstream:

#   Make child process spawn behave like a read stream (buffer the error, don't emit end if error emitted).

#   ```js
#   var toReadStream = require('spawn-to-readstream'),
#       spawn        = require('child_process').spawn;

#   toReadStream(spawn('ls', ['-lah'])).on('error', function(err) {
#     throw err;
#   }).on('end', function() {
#     console.log('~~~ DONE ~~~');
#   }).on('data', function(data) {
#     console.log('ls data :::', data.toString());
#   });
#   ```
#   ###
#   readstream_from_spawn     = require 'spawn-to-readstream'
#   spawn                     = ( require 'child_process' ).spawn
#   return readstream_from_spawn spawn P...

# #-----------------------------------------------------------------------------------------------------------
# @spawn_and_read_lines = ( P... ) ->
#   last_line = null
#   R         = @new_stream()
#   input     = @spawn_and_read P...
#   #.........................................................................................................
#   input
#     .pipe @$split()
#     .pipe @$ ( line, send, end ) =>
#       #.....................................................................................................
#       if line?
#         R.write last_line if last_line?
#         last_line = line
#       #.....................................................................................................
#       if end?
#         R.write last_line if last_line? and last_line.length > 0
#         R.end()
#         end()
#   #.........................................................................................................
#   return R


#===========================================================================================================
# NO-OP
#-----------------------------------------------------------------------------------------------------------
@$pass_through = -> @$ ( data, send ) -> send data


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
@$aggregate = ( initial_value, on_data, on_end = null ) ->
  ### `$aggregate` allows to compose stream transformers that act on the entire stream. Aggregators may

  * replace all data items with a single item;
  * observe the entire stream and either add or print out summary values.

  `$aggregate` should be called with two or three arguments:
  * `initial_value` is the base value that represents the value of the aggregator when it never
    gets to see any data; for a count or a sum that would be `0`, for a list of all data items, that would
    be an empty list, and so on.
  * `on_data` is the handler for each data items. It will be called as `on_data data, send`. Whatever
    value the data handler returns becomes the next value of the aggregator. If you want to *keep* data
    ittems in the stream, you must call `send data`; if you want to *omit* data items (and maybe later on
    replace them with the aggregate), do not call `send data`.
  * `on_end`, when given, will be called as `on_end current_value, send` after the last data item has come
    down the stream, but before `end` is emitted on the stream. It gives you the chance to perform some
    data transformation on your aggregate. If `on_end` is not given, the default operation is to just send
    on the current value of the aggregate.

  See `$count` and `$collect` for examples of aggregators.

  Note that unlike `Array::reduce`, handlers will not be given much context; it is your obligation to do
  all the bookkeeping—which should be a simple and flexible thing to implement using JS closures.
  ###
  throw new Error "$aggregate temporarily on hold"
  current_value = initial_value
  return @$ ( data, send, end ) =>
    if data?
      current_value = on_data data, send
    if end?
      if on_end? then on_end current_value, send else send current_value
      end()

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
  return $ ( data, send, end ) ->
    collector.push data if data?
    if end?
      send collector
      end()

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  end       = settings?[ 'end'      ] ? no
  return @$ ( data, send ) =>
    unless type = ( CND.type_of data ) is 'list'
      return send.error new Error "expected a list, got a #{rpr type}"
    for value, idx in data
      send if indexed then [ idx, value, ] else value
    send null if end

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
  throw new Error "expected 0 or 1 argument, got #{arity}" unless 0 <= ( arity = method.length ) <= 1
  return @$ ( data, send, end ) ->
    send data if data?
    if end?
      return method end if arity is 1
      method()
      end()

#-----------------------------------------------------------------------------------------------------------
@$on_start = ( method ) ->
  is_first = yes
  return @$ ( data, send ) ->
    method send if is_first
    is_first = no
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
@$observe = ( method ) ->
  ### Call `method` for each piece of data; when `method` has returned with whatever result, send data on.
  ###
  # return @$filter ( data ) -> method data; return true
  switch arity = method.length
    when 1
      return @$ ( data ) => method data
    when 2
      return @$ ( data, send, end ) =>
        if data?
          method data, false
          send data
        if end?
          method null, true
          end()
  throw new Error "expected method with arity 1 or 2, got one with arity #{arity}"

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
  Throttle = require 'throttle'
  return new Throttle bytes_per_second

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
# CSV
#-----------------------------------------------------------------------------------------------------------
@$parse_csv = ( options ) ->
  field_names = null
  options    ?= {}
  headers     = options[ 'headers'    ] ? true
  delimiter   = options[ 'delimiter'  ] ? ','
  qualifier   = options[ 'qualifier'  ] ? '"'
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


#===========================================================================================================
# GENERIC METHODS
#-----------------------------------------------------------------------------------------------------------
### https://github.com/dominictarr/sort-stream ###
@$sort                        = require 'sort-stream'
@$split                       = require 'split2'

