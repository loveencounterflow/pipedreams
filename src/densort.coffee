


############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'PIPEDREAMS2/densort'
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
# ### https://github.com/rvagg/through2 ###
# through2                  = require 'through2'
# #...........................................................................................................
# BNP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'


  # ### Given a stream of `data` items with an index available as `data[ key ]`, re-emit data items in order
  # such that indexes are ordered, and no items are left out. This is is called 'dense sort' as it presupposes
  # that no single index is left out of the sequence, such that whenever an item with index `n` is seen, it
  # can be passed on as soon as all items with index m < n have been seen and passed on. Conversely, any item
  # whose predecessors have not yet been seen and passed on must be buffered. The method my be called as
  # `$densort k, n0`, where `k` is the key to pick up the index from each data item (defaulting to `1`,
  # i.e. assuming an 'element list' whose first item is the index element name, the second is the index, and
  # the rest represents the payload), and `n0` is the lowest index (defaulting to `0` as
  # well).

  # In contradistinction to 'agnostic' sorting (which must buffer all data until the stream has ended), the
  # hope in a dense sort is that buffering will only ever occur over few data items which should hold as long
  # as the stream originates from a source that emitted items in ascending order over a reasonably 'reliable'
  # network (i.e. one that does not arbitrarily scramble the ordering of packages); however, it is always
  # trivial to cause the buffering of *all* data items by withholding the first data item until all others
  # have been sent; thus, the performance of this method cannot be guaranteed.

  # To ensure data integrity, this method will throw an exception if the stream should end before all items
  # between `n0` and the last seen index have been sent (i.e. in cases where the stream was expected to be
  # dense, but turned out to be sparse), and when a duplicate index has been detected.

  # You may pass in a `handler` that will be called after the entire stream has been processed; that function,
  # if present, will be called with a pair `[ n, m, ]` where `n` is the total number of elements encountered,
  # and `m <= n` is the maximal number of elements that had to be buffered at any one single point in time.
  # `m` will equal `n` if the logically first item happened to arrive last (and corresponds to the number of
  # items that have to be buffered with 'sparse', agnostic sorting); `m` will be zero if all items happened
  # to arrive in their logical order (the optimal case). ###

#-----------------------------------------------------------------------------------------------------------
module.exports = new_densort = ( key = 1, first_idx = 0, report_handler = null ) ->
  #.........................................................................................................
  key_is_function = TYPES.isa_function key
  buffer          = []
  buffer_size     = 0             # Amount of buffered items
  previous_idx    = first_idx - 1 # Index of most recently sent item
  smallest_idx    = Infinity      # Index of first item in buffer
  min_legal_idx   = 0             # 'Backlog' of the range of indexes that have already been sent out
  max_buffer_size = 0
  element_count   = 0
  sent_count      = 0
  #.........................................................................................................
  buffer_element = ( idx, element ) =>
    throw new Error "duplicate index #{rpr idx}" if buffer[ idx ]?
    smallest_idx  = Math.min smallest_idx, idx
    # debug '<---', smallest_idx
    buffer[ idx ] = element
    buffer_size  += +1
    return null
  #.........................................................................................................
  send_buffered_elements = ( handler ) =>
    ### Refuse to send anything unless all elements with smaller indexes have already been sent: ###
    return if sent_count < ( smallest_idx - first_idx )
    loop
      ### Terminate loop in case nothing is in the buffer or we have reached an empty position: ###
      if buffer_size < 1 or not ( element = buffer[ smallest_idx ] )?
        # smallest_idx    = Infinity if buffer_size < 1
        min_legal_idx   = Math.max min_legal_idx, smallest_idx
        break
      #.....................................................................................................
      ### Remove element to be sent from buffer (making it a sparse list in most cases), adjust sentinels and
      send element: ###
      delete buffer[ smallest_idx ]
      previous_idx    = smallest_idx
      max_buffer_size = Math.max max_buffer_size, buffer_size
      smallest_idx   += +1
      buffer_size    += -1
      sent_count     += +1
      min_legal_idx   = Math.max min_legal_idx, smallest_idx
      handler null, element
  #.........................................................................................................
  return ( element, handler ) =>
    #.......................................................................................................
    if element?
      element_count += +1
      idx            = if key_is_function then key element else element[ key ]
      if idx < min_legal_idx # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        warn 'buffer_size:      ', buffer_size
        warn 'max_buffer_size:  ', max_buffer_size
        warn 'min_legal_idx:    ', min_legal_idx
        warn 'previous_idx:     ', previous_idx
        warn 'smallest_idx:     ', smallest_idx
        warn buffer
      throw new Error "duplicate index #{rpr idx}" if idx < min_legal_idx
      #.....................................................................................................
      if buffer_size is 0 and idx is previous_idx + 1
        previous_idx    = idx
        min_legal_idx   = idx + 1
        sent_count     += +1
        smallest_idx    = Infinity if buffer_size < 1
        handler null, element
      #.....................................................................................................
      else
        buffer_element idx, element
        send_buffered_elements handler
    #.......................................................................................................
    else
      send_buffered_elements handler
      if buffer_size > 0 # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        # warn 'first_idx:        ', first_idx
        # warn 'element_count:    ', element_count
        # warn 'sent_count:       ', sent_count
        warn 'buffer_size:      ', buffer_size
        warn 'max_buffer_size:  ', max_buffer_size
        warn 'min_legal_idx:    ', min_legal_idx
        warn 'previous_idx:     ', previous_idx
        warn 'smallest_idx:     ', smallest_idx
        warn buffer
      throw new Error "detected missing elements" if buffer_size > 0
      report_handler [ element_count, max_buffer_size, ] if report_handler?
      handler null, null



