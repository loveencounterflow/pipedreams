
############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SYNCHRONIZED-CIRCULAR-PIPELINES'
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
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
PD                        = require '../..'
{ $
  $async
  select
  stamp }                 = PD
#...........................................................................................................
{ jr
  copy
  assign }                = CND
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout f, dts * 1000
defer                     = setImmediate
rpr_datom                 = ( d ) -> "#{d.key}:: #{jr d.value ? null} #{if d.stamped then 'S' else ''}"
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }


# #-----------------------------------------------------------------------------------------------------------
# @[ "synced" ] = ( T, done ) ->
#   S                   = {}
#   probes_and_matchers = [
#     [[2,3,4,5,6,7,8,9,10],[[2,1],[3,10,5,16,8,4],[],[],[6],[7,22,11,34,17,52,26,13,40,20],[],[9,28,14],[]]]
#     ]
#   #.........................................................................................................
#   for [ probe, matcher, error, ] in probes_and_matchers
#     await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
#       values      = probe
#       collector   = []
#       refillable  = []
#       bysource    = PD.new_refillable_source refillable, { repeat: 1, show: true, }
#       pipeline    = []
#       pipeline.push PD.new_value_source values
#       pipeline.push PD.$as_type_datoms()
#       pipeline.push PD.$wye bysource
#       pipeline.push PD.$watch ( d ) -> echo rpr_datom d
#       pipeline.push PD.$collect { collector, }
#       # pipeline.push PD.$watch ( d ) -> stamp d
#       # pipeline.push PD.$watch ( d ) -> echo rpr_datom d
#       # pipeline.push PD.$watch ( d ) -> echo xrpr d
#       pipeline.push PD.$drain ->
#         help 'ok'
#         resolve collector
#       PD.pull pipeline...
#   #.........................................................................................................
#   done()
#   return null

############################################################################################################
unless module.parent?
  # test @, { timeout: 30000, }
  test @[ "synced" ]

