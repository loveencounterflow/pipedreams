

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

# https://pull-stream.github.io/#pull-through
# nope https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux


#-----------------------------------------------------------------------------------------------------------
$as_type_datoms = ->
  ### Given raw data events (RDEs), turn them into signleton datoms, using the results of `CND.type_of`
  for the keys, so `'xy'` turns into `{ key: 'text', value: 'xy', }`, and `42` turns into `{ key: 'number',
  value: 42, }`. ###
  return $ ( d, send ) =>
    return send d if CND.isa_pod d
    type = CND.type_of d
    send PD.new_event "^#{type}", d
    return null

#-----------------------------------------------------------------------------------------------------------
wye_3 = ->
  #.........................................................................................................
  get_transform = ->
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
    # mainline.push PD.new_value_source "just a few words".split /\s/
    mainline.push PD.new_random_async_value_source "just a few words".split /\s/
    # mainline.push PD.$wye PD.new_value_source "JUST A FEW WORDS".split /\s/
    mainline.push PD.$wye bystream
    mainline.push $as_type_datoms()
    # mainline.push $ { last: null, }, ( d, send ) ->
    #   debug CND.plum '10109', d
    #   send PD.new_event '~end' unless d?
    #   send d
    mainline.push PD.$show title: 'confluence'
    mainline.push $async { last: null, }, ( d, send, done ) ->
      debug CND.lime '33450', d
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



############################################################################################################
unless module.parent?
  do -> await wye_3()
  # wye_4()





