
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/VARIOUS-PULL-STREAMS'
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
PD                        = require '../..'
{ $
  select
  $async }                = PD
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }

# https://pull-stream.github.io/#pull-through
# nope https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux


#-----------------------------------------------------------------------------------------------------------
$as_type_datoms = ->
  ### Given raw data events (RDEs), turn them into singleton datoms, using the results of `CND.type_of`
  for the keys, so `'xy'` turns into `{ key: 'text', value: 'xy', }`, and `42` turns into `{ key: 'number',
  value: 42, }`. ###
  return $ ( d, send ) =>
    debug '29209', d, CND.type_of d
    return send d if CND.isa_pod d
    type = CND.type_of d
    if type is 'text' and d.startsWith '~'
      send PD.new_datom d, null
    else
      send PD.new_datom "^#{type}", d
    return null

#-----------------------------------------------------------------------------------------------------------
wye_3 = ->
  #.........................................................................................................
  provide_$end = ->
    @$end = ->
      # a sink function: accept a source...
      return ( read ) ->
        # ...but return another source!
        return ( abort, handler ) ->
          read abort, ( error, data ) ->
            # if the stream has ended, pass that on.
            return handler error if error
            debug @symbols.end
            return handler true if data is @symbols.end
            handler null, data
            return null
          return null
        return null
  provide_$end.apply PD
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    bysource  = PD.new_push_source()
    byline    = []
    # byline.push PD.new_value_source "JUST A FEW WORDS".split /\s/
    byline.push bysource
    byline.push $ { last: null, }, ( d, send ) ->
      debug CND.red '22922', jr d
      send d
    # byline.push PD.$watch ( d ) -> whisper 'bystream', jr d
    byline.push $as_type_datoms()
    bystream = PD.pull byline...
    #.......................................................................................................
    mainline = []
    mainline.push PD.new_random_async_value_source "just a few words ~stop".split /\s+/
    mainline.push $as_type_datoms()
    mainline.push $ ( d, send ) -> send if ( select d, '~stop' ) then PD.symbols.end else d
    mainline.push PD.$wye bystream
    # mainline.push $ { last: null, }, ( d, send ) ->
    #   debug CND.plum '10109', d
    #   send PD.new_datom '~end' unless d?
    #   send d
    mainline.push $async { last: null, }, ( d, send, done ) ->
      echo '33450', xrpr d
      if d?
        if ( select d, '^text' )
          defer -> bysource.send d.value.length
          send d
          done()
        else
          send d
          done()
      else
        defer -> bysource.send null
        # bysource.end()
        send d
        done()
      return null
    mainline.push PD.$collect()
    mainline.push PD.$show title: 'mainstream'
    mainline.push PD.$drain -> help 'ok'; resolve()
    PD.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
wye_4 = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    bysource  = PD.new_push_source()
    byline    = []
    byline.push bysource
    byline.push PD.$watch ( d ) -> whisper 'bystream', jr d
    bystream = PD.pull byline...
    #.......................................................................................................
    mainline = []
    mainline.push PD.new_value_source [ 5, 7, ]
    mainline.push PD.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PD.$wye bystream
    mainline.push PD.$show title: 'confluence'
    mainline.push $ ( d, send ) ->
      if d < 1.001
        send null
      else
        send d
        bysource.send Math.sqrt d
    mainline.push PD.$map ( d ) -> d.toFixed 3
    mainline.push PD.$collect()
    mainline.push PD.$show title: 'mainstream'
    mainline.push PD.$drain -> help 'ok'; resolve()
    PD.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  debug 'finish'
  return null


#-----------------------------------------------------------------------------------------------------------
@wye_with_duplex_pair = ->
  new_duplex_pair     = require 'pull-pair/duplex'
  [ client, server, ] = new_duplex_pair()
  clientline          = []
  serverline          = []
  refillable          = []
  extra_stream        = PS.new_refillable_source refillable, { repeat: 10, show: true, }
  # extra_stream        = PS.new_push_source()
  #.........................................................................................................
  # pipe the second duplex stream back to itself.
  serverline.push PS.new_merged_source server, extra_stream
  # serverline.push client
  serverline.push PS.$defer()
  serverline.push PS.$watch ( d ) -> urge d
  serverline.push $ ( d, send ) -> send d * 10
  serverline.push server
  PS.pull serverline...
  #.........................................................................................................
  clientline.push PS.new_value_source [ 1, 2, 3, ]
  # clientline.push PS.$defer()
  clientline.push client
  # clientline.push PS.$watch ( d ) -> extra_stream.send d if d < 30
  clientline.push PS.$watch ( d ) -> refillable.push d if d < 30
  clientline.push PS.$collect()
  clientline.push PS.$show()
  # clientline.push client
  clientline.push PS.$drain()
  PS.pull clientline...
  #.........................................................................................................
  return null



############################################################################################################
unless module.parent?
  do ->
    await wye_3()
    # await wye_4()
  # wye_4()





