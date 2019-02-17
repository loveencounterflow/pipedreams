
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/RECYCLE'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PD                        = require '..'
{ $, $async, }            = PD
{ assign
  is_empty
  jr }                    = CND


#-----------------------------------------------------------------------------------------------------------
@new_sync_event = -> PD.new_system_event 'sync'

#-----------------------------------------------------------------------------------------------------------
@$unwrap_recycled = ->
  ### If the event is a `~recycle` event, send its associated `~sync` event, if any, then its value;
  otherwise, send the event itself. ###
  q1        = [] ### priority queue for recycled events       ###
  q2        = [] ### secondary queue for newly arrived events ###
  waiting   = false
  # sent_sync = false
  my_sync   = @new_sync_event()
  return $ ( d, send ) =>
    # urge '77833-1', "#{d.sigil}#{d.key}:#{jr d.value ? null}"
    #.......................................................................................................
    ### If event is this circle's sync, send next event from q2, followed by my sync, and set state to
    waiting (for the sync to recycle back to here). If there's nothing left in the q2, that means we are
    done for the time being, and can stop waiting. ###
    if d is my_sync
      waiting = false
      # debug '77833-2', jr { waiting, q1, q2, }
      unless is_empty q1
        ### send next recycled event from the priority queue: ###
        waiting = true
        send q1.pop()
        # debug '77833-3', jr { waiting, q1, q2, }
        send my_sync
      else unless is_empty q2
        ### TAINT must wrap other circles' syncs so they don't get picked up by this circle's transforms ###
        waiting = true
        send q2.pop()
        # debug '77833-4', jr { waiting, q1, q2, }
        send my_sync
    #.......................................................................................................
    ### If event is recycling, put it into the priority queue to send it right after sync has recycled: ###
    else if @is_recycling d
      if waiting
        q1.unshift d.value
        # debug '77833-5', jr { waiting, q1, q2, }
      else
        send d.value
        # debug '77833-6', jr { waiting, q1, q2, }
      # send d.value
    #.......................................................................................................
    ### If we're in waiting state, q2 the event: ###
    else if waiting
      q2.unshift d
      # debug '77833-7', jr { waiting, q1, q2, }
    #.......................................................................................................
    else
      waiting = true
      # debug '77833-8', jr { waiting, q1, q2, }
      send d
      send my_sync
    return null

#-----------------------------------------------------------------------------------------------------------
@$recycle = ( resend ) ->
  ### Stream transform to send events either down the pipeline (using `send`) or
  to an alternate destination, using the `resend` method ( the only argument to
  this function). Normally, this will be the `send` method of a push source, but
  it could be any function that accepts a single event as argument. ###
  return $ { last: PD._symbols.end, }, ( d, send ) =>
    return resend PD._symbols.end unless d?
    if      ( @is_sync      d ) then resend d
    else if ( @is_recycling d ) then resend d
    else send d
    return null

#-----------------------------------------------------------------------------------------------------------
@recycling = ( d, sync = null ) ->
  PD.new_system_event 'recycle', d, if sync? then { sync, } else null

#-----------------------------------------------------------------------------------------------------------
@is_recycling = ( d ) ->
  ### Return whether event is a recycling wrapper event. ###
  return ( d.key is '~recycle' )

#-----------------------------------------------------------------------------------------------------------
@is_recycling_sync = ( d ) ->
  ### Return whether event is a sync event that accompanies a recycling event. ###
  return ( d.key is '~sync' ) and ( d.value > 0 )

#-----------------------------------------------------------------------------------------------------------
@is_sync = ( d ) ->
  ### Return whether event is a recycling wrapper event. ###
  return ( d.key is '~sync' )




