
'use strict'


############################################################################################################
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/RECYCLE'
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
PS                        = require 'pipestreams'
{ $, $async, }            = PS
rprx                      = ( d ) -> "#{d.sigil} #{d.key}:: #{jr d.value ? null} #{jr d.stamped ? false}"
#...........................................................................................................
{ is_empty
  copy
  assign
  jr }                    = CND



###


Pipestream Events v2
====================

d         := { sigil,          key, value, ..., $, }    # implicit global namespace
          := { sigil, prefix,  key, value, ..., $, }    # explicit namespace

# `d.sigil` indicates 'regionality':

sigil     := '.' # proper singleton
          := '~' # system singleton
          := '(' # start-of-region (SOR)    # '<'
          := ')' # end-of-region   (EOR)    # '>'

# `prefix` indicates the namespace; where missing on an datom or is `null`, `undefined` or `'global'`,
# it indicates the global namespace:

prefix    := null | undefined | 'global' | non-empty text

key       := non-empty text         # typename

value     := any                    # payload

$         := pod                    # system-level attributes, to be copied from old to new datoms

###


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@stamp = ( d ) ->
  ### Set the `stamped` attribute on datom to sigil it as processed. Stamped datoms will not be selected
  by the `select` method, only by the `select_all` method. ###
  d.stamped = true
  return d


#===========================================================================================================
# RECYCLING
#-----------------------------------------------------------------------------------------------------------
@$unwrap_recycled = ->
  ### If the datom is a `~recycle` datom, send its associated `~sync` datom, if any, then its value;
  otherwise, send the datom itself. ###
  q1        = [] ### priority queue for recycled datoms       ###
  q2        = [] ### secondary queue for newly arrived datoms ###
  waiting   = false
  # sent_sync = false
  my_sync   = @new_sync_datom()
  return $ ( d, send ) =>
    # urge '77833-1', "#{d.sigil}#{d.key}:#{jr d.value ? null}"
    #.......................................................................................................
    ### If datom is this circle's sync, send next datom from q2, followed by my sync, and set state to
    waiting (for the sync to recycle back to here). If there's nothing left in the q2, that means we are
    done for the time being, and can stop waiting. ###
    if d is my_sync
      waiting = false
      # debug '77833-2', jr { waiting, q1, q2, }
      unless is_empty q1
        ### send next recycled datom from the priority queue: ###
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
    ### If datom is recycling, put it into the priority queue to send it right after sync has recycled: ###
    else if @is_recycling d
      if waiting
        q1.unshift d.value
        # debug '77833-5', jr { waiting, q1, q2, }
      else
        send d.value
        # debug '77833-6', jr { waiting, q1, q2, }
      # send d.value
    #.......................................................................................................
    ### If we're in waiting state, q2 the datom: ###
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
@$recycle = ( push ) ->
  ### Stream transform to send datoms either down the pipeline (using `send`) or
  to an alternate destination, using the `push` method ( the only argument to
  this function). Normally, this will be the `push` method of a push source, but
  it could be any function that accepts a single datom as argument. ###
  return $ ( d, send ) =>
    if      ( @is_sync      d ) then push d
    else if ( @is_recycling d ) then push d
    else send d
    return null

#-----------------------------------------------------------------------------------------------------------
@recycling = ( d, sync = null ) ->
  @new_system_datom 'recycle', d, if sync? then { sync, } else null

#-----------------------------------------------------------------------------------------------------------
@is_recycling = ( d ) ->
  ### Return whether datom is a recycling wrapper datom. ###
  return ( d.sigil is '~' ) and ( d.key is 'recycle' )

#-----------------------------------------------------------------------------------------------------------
@is_recycling_sync = ( d ) ->
  ### Return whether datom is a sync datom that accompanies a recycling datom. ###
  return ( d.sigil is '~' ) and ( d.key is 'sync' ) and ( d.value > 0 )

#-----------------------------------------------------------------------------------------------------------
@is_sync = ( d ) ->
  ### Return whether datom is a recycling wrapper datom. ###
  return ( d.sigil is '~' ) and ( d.key is 'sync' )

# #-----------------------------------------------------------------------------------------------------------
# @new_sync_helpers = ->
#   ###
#   ###
#   buffer = []
#   #.........................................................................................................
#   hold = ( d ) =>
#     return false unless @is_sync d
#     buffer.push d
#     return true
#   #.........................................................................................................
#   recycle = =>
#     throw new Error "µ49984 sync buffer empty" if is_empty buffer
#     R       = buffer.shift()
#     R.value = ( R.value ? 0 ) + 1
#     return R
#   #.........................................................................................................
#   release = =>
#     throw new Error "µ49984 sync buffer empty" if is_empty buffer
#     return buffer.shift()
#   #.........................................................................................................
#   return { hold, release, recycle, buffer, }


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@select = ( d, prefix, sigils, keys ) ->
  ### Reject all stamped datoms: ###
  return false if @is_stamped d
  # return false if @is_recycling d
  ### TAINT avoid to test twice for arity ###
  switch arity = arguments.length
    when 3 then return @select_all d, prefix, sigils ### d, sigils, keys ###
    when 4 then return @select_all d, prefix, sigils, keys
    else throw new Error "expected 3 to 4 arguments, got #{arity}"

# #-----------------------------------------------------------------------------------------------------------
# @select_system = ( d, prefix, keys ) ->
#   ### TAINT avoid to test twice for arity ###
#   switch arity = arguments.length
#     when 2 then return @select_all d, prefix, sigils ### d, sigils, keys ###
#     when 3 then return @select_all d, prefix, sigils, keys
#     else throw new Error "expected 3 to 4 arguments, got arity"

#-----------------------------------------------------------------------------------------------------------
@select_all = ( d, prefix, sigils, keys ) ->
  ### accepts 3 or 4 arguments; when 4, then second must be prefix (only one prefix allowed);
  `sigils` and `keys` may be text or list of texts. ###
  switch arity = arguments.length
    # when 2 then [ prefix, sigils, keys, ] = [ null, prefix, sigils, ]
    when 3 then [ prefix, sigils, keys, ] = [ null, prefix, sigils, ]
    when 4 then null
    else throw new Error "expected 3 to 4 arguments, got arity"
  #.........................................................................................................
  prefix  = null if ( not prefix? ) or ( prefix is 'global' )
  sigils  ?= null
  keys  ?= null
  switch _type = CND.type_of prefix
    when 'null' then null
    when 'text' then return false unless d.prefix is prefix
    else throw new Error "expected a text or a list, got a #{_type}"
  switch _type = CND.type_of sigils
    when 'null' then null
    when 'text' then return false unless d.sigil is sigils
    when 'list' then return false unless d.sigil in sigils
    else throw new Error "expected a text or a list, got a #{_type}"
  switch _type = CND.type_of keys
    when 'null' then null
    when 'text' then return false unless d.key is keys
    when 'list' then return false unless d.key in keys
    else throw new Error "expected a text or a list, got a #{_type}"
  return true


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@is_system = ( d ) ->
  ### Return whether datom is a system datom (i.e. whether its `sigil` equals `'~'`). ###
  return d.sigil is '~'

#-----------------------------------------------------------------------------------------------------------
@is_stamped = ( d ) ->
  ### Return whether datom is stamped (i.e. already processed). ###
  return d.stamped ? false


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@new_datom = ( sigil, key, value, other... ) ->
  ### When `other` contains a key `$`, it is treated as a hint to copy
  system-level attributes; if the value of key `$` is a POD that has itself a
  key `$`, then a copy of that value is used. This allows to write `new_datom
  ..., $: d` to copy system-level attributes such as source locations to a new
  datom. ###
  if value? then  R = assign { sigil, key, value, }, other...
  else            R = assign { sigil, key,        }, other...
  ### TAINT consider to resolve recursively ###
  if ( CND.isa_pod R.$ ) and ( CND.isa_pod R.$.$ ) then R.$ = copy R.$.$
  return R

#-----------------------------------------------------------------------------------------------------------
@new_single_datom   = ( key, value, other...  ) -> @new_datom '!', key, value, other...
@new_open_datom     = ( key, value, other...  ) -> @new_datom '<', key, value, other...
@new_close_datom    = ( key, value, other...  ) -> @new_datom '>', key, value, other...
@new_system_datom   = ( key, value, other...  ) -> @new_datom '~', key, value, other...
@new_end_datom      =                           -> @new_system_datom 'end'
@new_sync_datom     =                           -> @new_system_datom 'sync'
@new_flush_datom    =                           -> @new_system_datom 'flush'
@new_text_datom     = (      value, other...  ) -> @new_single_datom 'text',    value, other...

#-----------------------------------------------------------------------------------------------------------
@new_warning = ( ref, message, d, other...  ) ->
  @new_system_datom 'warning', d, { ref, message, }, other...


############################################################################################################
L = @
do ->
  for key, value of L
    continue unless CND.isa_function value
    L[ key ] = value.bind L
  return null
