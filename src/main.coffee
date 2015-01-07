

############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'PIPEDREAMS2'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
### https://github.com/rvagg/through2 ###
through2                  = require 'through2'
#...........................................................................................................
BNP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'
# # TEXT                      = require 'coffeenode-text'
#...........................................................................................................
### https://github.com/dominictarr/event-stream ###
ES                        = require 'event-stream'

#===========================================================================================================
# GENERIC METHODS
#-----------------------------------------------------------------------------------------------------------
# @create_readstream            = HELPERS.create_readstream             .bind HELPERS
# @create_readstream_from_text  = HELPERS.create_readstream_from_text   .bind HELPERS
# @pimp_readstream              = HELPERS.pimp_readstream               .bind HELPERS
# @merge                        = ES.merge                              .bind ES
@$split                       = ES.split                              .bind ES
# @$chain                       = ES.pipeline                           .bind ES
# @through                      = ES.through                            .bind ES
# @duplex                       = ES.duplex                             .bind ES
# @as_readable                  = ES.readable                           .bind ES
# @read_list                    = ES.readArray                          .bind ES


#===========================================================================================================
# REMIT
#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  cache     = null
  on_end    = null
  #.........................................................................................................
  get_send = ( self ) ->
    R         = (  data ) -> self.emit 'data',  data # if data?
    R.error   = ( error ) -> self.emit 'error', error
    R.end     =           -> self.emit 'end'
    return R
  #.........................................................................................................
  switch arity = method.length
    #.......................................................................................................
    when 2
      #.....................................................................................................
      on_data = ( data ) ->
        # debug '©3w9', send
        send = get_send @ unless send?
        method data, send
    #.......................................................................................................
    when 3
      cache = []
      #.....................................................................................................
      on_data = ( data ) ->
        # debug '©3w9', send, data
        if cache.length is 0
          cache[ 0 ] = data
          return
        send = get_send @ unless send?
        [ cache[ 0 ], data, ] = [ data, cache[ 0 ], ]
        method data, send, null
      #.....................................................................................................
      on_end = ->
        send  = get_send @ unless send?
        end   = => @emit 'end'
        if cache.length is 0
          data = null
        else
          data = cache[ 0 ]
          cache.length = 0
        method data, send, end
    #.......................................................................................................
    else
      throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  return ES.through on_data, on_end


#===========================================================================================================
# OMITTING VALUES
#-----------------------------------------------------------------------------------------------------------
@$skip_first = ( n = 1 ) ->
  count = 0
  return @remit ( data, send ) ->
    count += +1
    send data if count > n


#===========================================================================================================
# SPECIALIZED STREAMS
#-----------------------------------------------------------------------------------------------------------
@create_throughstream = ( P... ) ->
  R = through2.obj P...
  R.setMaxListeners 0
  return R


#===========================================================================================================
# COUNTING
#-----------------------------------------------------------------------------------------------------------
@$count = ( label, handler = null ) ->
  count = 0
  return @remit ( data, send, end ) =>
    count += 1 if data?
    unless end?
      send.done data
    else
      if handler?
        handler null, count
      else
        info "encountered #{count} #{label}"
      end()


#===========================================================================================================
# SORT AND SHUFFLE
#-----------------------------------------------------------------------------------------------------------
@$dense_sort = ( key = 1, first_idx = 0, handler = null ) ->
  ### Given a stream of `data` items with an index available as `data[ key ]`, re-emit data items in order
  such that indexes are ordered, and no items are left out. This is is called 'dense sort' as it presupposes
  that no single index is left out of the sequence, such that whenever an item with index `n` is seen, it
  can be passed on as soon as all items with index m < n have been seen and passed on. Conversely, any item
  whose predecessors have not yet been seen and passed on must be buffered. The method my be called as
  `$dense_sort k, n0`, where `k` is the key to pick up the index from each data item (defaulting to `1`,
  i.e. assuming an 'event list' whose first item is the index event name, the second is the index, and
  the rest represents the payload), and `n0` is the lowest index (defaulting to `0` as
  well).

  In contradistinction to 'agnostic' sorting (which must buffer all data until the stream has ended), the
  hope in a dense sort is that buffering will only ever occur over few data items which should hold as long
  as the stream originates from a source that emitted items in ascending order over a reasonably 'reliable'
  network (i.e. one that does not arbitrarily scramble the ordering of packages); however, it is always
  trivial to cause the buffering of *all* data items by withholding the first data item until all others
  have been sent; thus, the performance of this method cannot be guaranteed.

  To ensure data integrity, this method will throw an exception if the stream should end before all items
  between `n0` and the last seen index have been sent (i.e. in cases where the stream was expected to be
  dense, but turned out to be sparse), and when a duplicate index has been detected.

  You may pass in a `handler` that will be called after the entire stream has been processed; that function,
  if present, will be called with a pair `[ n, m, ]` where `n` is the total number of events encountered,
  and `m <= n` is the maximal number of elements that had to be buffered at any one single point in time.
  `m` will equal `n` if the logically first item happened to arrive last (and corresponds to the number of
  items that have to be buffered with 'sparse', agnostic sorting); `m` will be zero if all items happened
  to arrive in their logical order (the optimal case). ###
  #.........................................................................................................
  key_is_function = TYPES.isa_function key
  buffer          = []
  ### Amount of buffered items: ###
  buffer_size     = 0
  ### Index of most recently sent item: ###
  previous_idx    = first_idx - 1
  ### Index of first item in buffer: ###
  smallest_idx    = Infinity
  ### 'Backlog' of the range of indexes that have already been sent out: ###
  min_legal_idx   = 0
  max_buffer_size = 0
  event_count     = 0
  sent_count      = 0
  #.........................................................................................................
  buffer_event = ( idx, event ) =>
    smallest_idx  = Math.min smallest_idx, idx
    buffer[ idx ] = event
    buffer_size  += +1
    return null
  #.........................................................................................................
  send_buffered_events = ( send ) =>
    ### Refuse to send anything unless all events with smaller indexes have already been sent: ###
    return if sent_count < ( smallest_idx - first_idx )
    loop
      ### Terminate loop in case nothing is in the buffer or we have reached an empty position: ###
      if buffer_size < 1 or not ( event = buffer[ smallest_idx ] )?
        min_legal_idx = smallest_idx
        break
      #.....................................................................................................
      ### Remove event to be sent from buffer (making it a sparse list in most cases), adjust sentinels and
      send event: ###
      delete buffer[ smallest_idx ]
      previous_idx    = smallest_idx
      max_buffer_size = Math.max max_buffer_size, buffer_size
      smallest_idx   += +1
      buffer_size    += -1
      sent_count     += +1
      send event
  #.........................................................................................................
  return @remit ( event, send, end ) =>
    #.......................................................................................................
    if event?
      event_count  += +1
      idx           = if key_is_function then key event else event[ key ]
      # debug '©7DpAG', min_legal_idx, idx
      return send.error new Error "duplicate index #{rpr idx}" if idx < min_legal_idx
      #.....................................................................................................
      if buffer_size is 0 and idx is previous_idx + 1
        ### In case no items are in the buffer and the current index is the one after the previous index, we
        can send on the event immediately: ###
        previous_idx = idx
        sent_count += +1
        send event
      #.....................................................................................................
      else
        ### Otherwise, we put the event into the buffer under its index; should the position in the buffer
        not be vacant, we emit an error. Afterwards, we try to emit as many events from the buffer as
        possible: ###
        return send.error new Error "duplicate index #{rpr idx}" if buffer[ idx ]?
        buffer_event idx, event
        send_buffered_events send
    #.......................................................................................................
    if end?
      ### Lastly, let's emit all remaining events in the buffer; should there be any elements left, we issue
      an error: ###
      send_buffered_events send
      warn buffer if buffer_size > 0 # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      send.error new Error "detected missing events" if buffer_size > 0
      handler [ event_count, max_buffer_size, ] if handler?
      end()

#-----------------------------------------------------------------------------------------------------------
# @$shuffle =

# #-----------------------------------------------------------------------------------------------------------
# @$dither = ( min_dt = 0, max_dt = 100 ) ->
#   t1 = +new Date()
#   return @remit ( event, send, end ) =>
#     if event?
#       dt  = BNP.random_integer min_dt, max_dt
#       t1  = Math.max ( +new Date() ) + dt, t1
#       debug '©aXmhU', t1
#       do ( dt ) ->
#         setTimeout ( -> debug '©74GA6', dt, 'send'; send event ), dt
#     if end?
#       dt  = ( +new Date() ) - t1 + 1
#       debug '©P9MJD', ( +new Date() ), t1, dt
#       # do ( dt ) ->
#       #   setTimeout ( -> debug '©7smSz', dt, 'end'; end() ), dt



#===========================================================================================================
# AGGREGATION
#-----------------------------------------------------------------------------------------------------------
@$collect = ->
  collector = []
  return @remit ( event, send, end ) =>
    if event?
      collector.push event
    if end?
      send collector
      end()

#===========================================================================================================
# REPORTING
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  my_show = TRM.get_logger 'info', badge ? '*'
  return @remit ( record, send ) =>
    my_show rpr record
    send record








