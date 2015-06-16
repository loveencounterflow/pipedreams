

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS2'
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
#...........................................................................................................
# ### https://github.com/dominictarr/pause-stream ###
# through_aka_pausestream   = require 'through'
#...........................................................................................................
### https://github.com/dominictarr/event-stream ###
ES                        = @_ES = require 'event-stream'
#...........................................................................................................
### https://github.com/dominictarr/sort-stream ###
@$sort                    = require 'sort-stream'
#...........................................................................................................
### https://github.com/dominictarr/stream-combiner ###
combine                   = require 'stream-combiner'
#...........................................................................................................
@new_densort              = ( DS = require './densort' ).new_densort.bind DS
PIPEDREAMS                = @
LODASH                    = CND.LODASH
@HOTMETAL                 = require 'hotmetal'



#===========================================================================================================
# GENERIC METHODS
#-----------------------------------------------------------------------------------------------------------
# @create_readstream            = HELPERS.create_readstream             .bind HELPERS
# @create_readstream_from_text  = HELPERS.create_readstream_from_text   .bind HELPERS
# @pimp_readstream              = HELPERS.pimp_readstream               .bind HELPERS
# @merge                        = ES.merge                              .bind ES
@$split                       = ES.split                              .bind ES
@$map                         = ES.map                                .bind ES
# @$chain                       = ES.pipeline                           .bind ES
# @through                      = ES.through                            .bind ES
# @duplex                       = ES.duplex                             .bind ES
# @as_readable                  = ES.readable                           .bind ES
# @read_list                    = ES.readArray                          .bind ES

# #-----------------------------------------------------------------------------------------------------------
# D.$map_plus = ( transform ) ->
#   ### TAINT looks like `write` occurs too late or `end` too early ###
#   ### Like `map`, but calls `transform` one more time (hence the name) with `undefined` in place of data
#   just before the stream has ended; this gives the caller one more chance to send data. ###
#   R = ES.map transform # ( data, handler ) -> transform data, handler
#   _end = R.end.bind R
#   R.end = ->
#     transform undefined, ( error, data ) ->
#       return R.error error if error?
#       debug '©GbYu0', data
#       R.write data if data?
#       setImmediate _end
#   return R


#===========================================================================================================
# REMIT
#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  on_end    = null
  #.........................................................................................................
  get_send = ( self ) ->
    R             = (  data ) -> self.emit 'data',  data # if data?
    R.error       = ( error ) -> self.emit 'error', error
    R.end         =           -> self.emit 'end'
    R.pause       =           -> self.pause()
    R.resume      =           -> self.resume()
    R.read        =           -> self.read()
    # R[ '%self' ]  = self
    R.stream      = self
    return R
  #.....................................................................................................
  on_data = ( data ) ->
    send = get_send @ unless send?
    method data, send
  #.........................................................................................................
  switch arity = method.length
    when 2
      null
    #.......................................................................................................
    when 3
      on_end = ->
        send  = get_send @ unless send?
        end   = => @emit 'end'
        method undefined, send, end
    #.......................................................................................................
    else
      throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  return ES.through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
$ = @remit.bind @



#===========================================================================================================
# COMBINING STREAM TRANSFORMS
#-----------------------------------------------------------------------------------------------------------
@combine = ( transforms... ) ->
  return combine transforms...


#===========================================================================================================
# OMITTING VALUES
#-----------------------------------------------------------------------------------------------------------
@$skip_first = ( n = 1 ) ->
  count = 0
  return $ ( data, send ) ->
    count += +1
    send data if count > n


#===========================================================================================================
# SPECIALIZED STREAMS
#-----------------------------------------------------------------------------------------------------------
@create_throughstream = ( P... ) ->
  # R           = through2.obj P...
  ### TAINT `end` events passed through synchronously even when `write` happens asynchronously ###
  R           = ES.through P...
  write       = R.write.bind R
  end         = R.end.bind R
  #.........................................................................................................
  R.write = ( data, handler ) ->
    if handler?
      setImmediate ->
        handler null, write data
    else
      return write data
  #.........................................................................................................
  R.end = ( handler ) ->
    if handler?
      setImmediate ->
        handler null, end()
    else
      return end()
  #.........................................................................................................
  R.setMaxListeners 0
  return R


#===========================================================================================================
# NO-OP
#-----------------------------------------------------------------------------------------------------------
@$pass_through = -> $ ( data, send ) -> send data


#===========================================================================================================
# SUB-STREAMS
#-----------------------------------------------------------------------------------------------------------
@$sub = ( sub_transformer ) ->
  #.........................................................................................................
  _send   = null
  _end    = null
  cache   = undefined
  #.........................................................................................................
  source        = @create_throughstream()
  sink          = @create_throughstream()
  state         = {}
  source.ended  = false
  sub_transformer source, sink, state
  #.........................................................................................................
  sink.on   'data', ( data )  => _send data
  sink.on   'end',            => _send.end()
  #.........................................................................................................
  return $ ( data, send, end ) =>
    if data?
      _send = send
      if cache is undefined
        cache = data
      else
        source.write cache
        cache = data
    if end?
      source.ended = true
      source.write cache unless cache is undefined


#===========================================================================================================
# SORT AND SHUFFLE
#-----------------------------------------------------------------------------------------------------------
@$densort = ( key = 1, first_idx = 0, report_handler = null ) ->
  ds        = @new_densort key, first_idx, report_handler
  has_ended = no
  #.........................................................................................................
  send_data = ( send, data ) =>
  #.........................................................................................................
  signal_end = ( send ) =>
    send.end() unless has_ended
    has_ended = yes
  #.........................................................................................................
  return $ ( input_data, send, end ) =>
    #.......................................................................................................
    if input_data?
      ds input_data, ( error, output_data ) =>
        return send.error error if error?
        send output_data
    #.......................................................................................................
    if end?
      ds null, ( error, output_data ) =>
        return send.error error if error?
        if output_data? then  send output_data
        else                  signal_end send

#-----------------------------------------------------------------------------------------------------------
# @$shuffle =

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
  return ( $ ( record, send ) => send record ) if p == 1
  return ( $ ( record, send ) => null        ) if p == 0
  #.........................................................................................................
  headers = options?[ 'headers'     ] ? false
  seed    = options?[ 'seed'        ] ? null
  count   = 0
  rnd     = rnd_from_seed seed
  #.........................................................................................................
  return $ ( record, send ) =>
    count += 1
    send record if ( count is 1 and headers ) or rnd() < p


#===========================================================================================================
# AGGREGATION & DISSEMINATION
#-----------------------------------------------------------------------------------------------------------
@$aggregate = ( aggregator, on_end = null ) ->
  Z = null
  return $ ( data, send, end ) =>
    if data?
      Z = aggregator data
      send data if on_end?
    if end?
      if on_end? then on_end Z
      else            send   Z
      end()

#-----------------------------------------------------------------------------------------------------------
@$count = ( on_end = null ) ->
  count = 0
  return @$aggregate ( -> count += +1 ), on_end

#-----------------------------------------------------------------------------------------------------------
@$collect = ( on_end = null ) ->
  collector = []
  aggregator = ( data ) ->
    collector.push data
    return collector
  return @$aggregate aggregator, on_end

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  end       = settings?[ 'end'      ] ? no
  return $ ( data, send ) =>
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
  return $ ( data, send, end ) =>
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
# @$signal_end = ( signal = @eos ) ->
#   ### Given an optional `signal` (which defaults to `null`), return a stream transformer that emits
#   `signal` as last value in the stream. Observe that whatever value you choose for `signal`, that value
#   should be gracefully handled by any transformers that follow in the pipe. ###
#   on_data = null
#   on_end  = ->
#     @emit 'data', signal
#     @emit 'end'
#   return ES.through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$on_end = ( method ) ->
  ### TAINT use `$map` to turn this into an async method? ###
  switch arity = method.length
    when 0, 1, 2 then null
    else throw new Error "expected method with arity 1 or 2, got one with arity #{arity}"
  return $ ( data, send, end ) ->
    send data if data?
    if end?
      if arity is 0
        method()
        return end()
      return method end if arity is 1
      method send, end

#-----------------------------------------------------------------------------------------------------------
@$on_start = ( method ) ->
  is_first = yes
  return $ ( data, send ) ->
    method send if is_first
    is_first = no
    send data


#===========================================================================================================
# FILTERING
#-----------------------------------------------------------------------------------------------------------
@$filter = ( select ) ->
  return $ ( event, send ) =>
    send event if select event


#===========================================================================================================
# REPORTING
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  my_show = CND.get_logger 'info', badge ? '*'
  return $ ( record, send ) =>
    my_show rpr record
    send record


#===========================================================================================================
# EXPERIMENTAL: STREAM LINKING, CONCATENATING
#-----------------------------------------------------------------------------------------------------------
@$continue = ( stream ) ->
  return $ ( data, send, end ) =>
    stream.write data
    if end?
      stream.end()
      end()


#-----------------------------------------------------------------------------------------------------------
@$link = ( transforms... ) ->
  return @create_throughstream() if transforms.length is 0
  source  = sink = @create_throughstream()
  sink    = sink.pipe transform for transform in LODASH.flatten transforms
  _send   = null
  sink.on 'data', ( data ) => _send data
  return $ ( data, send ) =>
    _send = send
    source.write data


#===========================================================================================================
# HYPHENATION
#-----------------------------------------------------------------------------------------------------------
@$hyphenate = ( hyphenation = null, min_length = 4 ) ->
  hyphenate = @HOTMETAL.new_hyphenate hyphenation, min_length
  return $ ( text, send ) => send hyphenate text, min_length


#===========================================================================================================
# UNICODE LINE BREAKING
#-----------------------------------------------------------------------------------------------------------
@$break_lines = ( settings ) ->
  #.........................................................................................................
  return $ ( text, send ) =>
    send @HOTMETAL.break_lines text, settings


#===========================================================================================================
# TYPOGRAPHIC ENHANCEMENTS
#-----------------------------------------------------------------------------------------------------------
@TYPO = {}

#-----------------------------------------------------------------------------------------------------------
@TYPO.$quotes = ->
  return $ ( text, send ) => send PIPEDREAMS.HOTMETAL.TYPO.quotes text

#-----------------------------------------------------------------------------------------------------------
@TYPO.$dashes = ->
  return $ ( text, send ) => send PIPEDREAMS.HOTMETAL.TYPO.dashes text


#===========================================================================================================
# MARKDOWN
#-----------------------------------------------------------------------------------------------------------
@MD = {}

#-----------------------------------------------------------------------------------------------------------
@MD.$as_html = ->
  parser = PIPEDREAMS.HOTMETAL.MD.new_parser()
  #.........................................................................................................
  return $ ( md, send ) =>
    send PIPEDREAMS.HOTMETAL.MD.as_html md, parser


#===========================================================================================================
# HTML
#-----------------------------------------------------------------------------------------------------------
@HTML = {}

#---------------------------------------------------------------------------------------------------------
@HTML.$parse = ( settings ) ->
  return $ ( html, send ) =>
    send PIPEDREAMS.HOTMETAL.HTML.parse html, settings

#---------------------------------------------------------------------------------------------------------
@HTML.$split = ( settings ) ->
  return $ ( html, send ) =>
    send PIPEDREAMS.HOTMETAL.HTML.split html, settings

#-----------------------------------------------------------------------------------------------------------
@HTML.$slice_toplevel_tags = ->
  return $ ( me, send ) =>
    PIPEDREAMS.HOTMETAL.slice_toplevel_tags me, ( error, slice ) =>
      return send.error error if error?
      send slice

#-----------------------------------------------------------------------------------------------------------
@HTML.$unwrap = ( silent = no) ->
  return $ ( me, send ) =>
    send PIPEDREAMS.HOTMETAL.unwrap me, silent



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
  return $ ( data, send, end ) =>
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
# HELPERS
#-----------------------------------------------------------------------------------------------------------
get_random_integer = ( rnd, min, max ) ->
  return ( Math.floor rnd() * ( max + 1 - min ) ) + min

#-----------------------------------------------------------------------------------------------------------
rnd_from_seed = ( seed ) ->
  return if seed? then CND.get_rnd seed else Math.random



#===========================================================================================================
# EXPERIMENTAL
# #-----------------------------------------------------------------------------------------------------------
# @_$send_later = ->
#   #.........................................................................................................
#   R     = D.create_throughstream()
#   count = 0
#   _end  = null
#   #.....................................................................................................
#   send_end = =>
#     if _end? and count <= 0
#       _end()
#     else
#       setImmediate send_end
#   #.....................................................................................................
#   R
#     .pipe $ ( data, send, end ) =>
#       if data?
#         count += +1
#         setImmediate =>
#           count += -1
#           send data
#           debug '©MxyBi', count
#       if end?
#         _end = end
#   #.....................................................................................................
#   send_end()
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @_$pull = ->
#   queue     = []
#   # _send     = null
#   is_first  = yes
#   pull = ->
#     if queue.length > 0
#       return queue.pop()
#     else
#       return [ 'empty', ]
#   return $ ( data, send, end ) =>
#     if is_first
#       is_first = no
#       send pull
#     if data?
#       queue.unshift [ 'data', data, ]
#     if end?
#       queue.unshift [ 'end', end, ]

# #-----------------------------------------------------------------------------------------------------------
# @_$take = ->
#   return $ ( pull, send ) =>
#     # debug '©vKkJf', pull
#     # debug '©vKkJf', pull()
#     process = =>
#       [ type, data, ] = pull()
#       # debug '©bamOB', [ type, data, ]
#       switch type
#         when 'data'   then send data
#         when 'empty'  then null
#         when 'end'    then return send.end()
#         else send.error new Error "unknown event type #{rpr type}"
#       setImmediate process
#     process()




