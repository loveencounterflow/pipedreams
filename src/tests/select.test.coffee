

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SELECT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
L                         = require '../select'
PD                        = require '../..'
{ $
  $async
  select }                = PD
#...........................................................................................................
types                     = require '../_types'
{ isa
  validate
  type_of }               = types


#-----------------------------------------------------------------------------------------------------------
@[ "selector keypatterns" ] = ( T, done ) ->
  probes_and_matchers = [
    ["",{"sigils":"","name":""},null]
    ["^foo",{"sigils":"^","name":"foo"},null]
    ["<foo",{"sigils":"<","name":"foo"},null]
    ["  ",null,null]
    [">foo",{"sigils":">","name":"foo"},null]
    ["<>foo",{"sigils":"<>","name":"foo"},null]
    ["<>^foo",{"sigils":"<>^","name":"foo"},null]
    ["^ foo",null,null]
    ["^prfx:foo",{"sigils":"^","prefix":"prfx","name":"foo"},null]
    ["<prfx:foo",{"sigils":"<","prefix":"prfx","name":"foo"},null]
    [">prfx:foo",{"sigils":">","prefix":"prfx","name":"foo"},null]
    ["<>prfx:foo",{"sigils":"<>","prefix":"prfx","name":"foo"},null]
    ["<>^prfx:foo",{"sigils":"<>^","prefix":"prfx","name":"foo"},null]
    ["^<>",{"sigils":"^<>","name":""},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      R = ( probe.match L._selector_keypattern )?.groups ? null
      return null unless R?
      for key, value of R
        delete R[ key ] if value is undefined
      return R
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "datom keypatterns" ] = ( T, done ) ->
  probes_and_matchers = [
    ["text",null,null]
    ["^text",{"sigil":"^","name":"text"},null]
    ["<bold",{"sigil":"<","name":"bold"},null]
    [">bold",{"sigil":">","name":"bold"},null]
    ["~collect",{"sigil":"~","name":"collect"},null]
    ["~kwic:collect",{"sigil":"~","prefix":"kwic","name":"collect"},null]
    ["<kwic:bar",{"sigil":"<","prefix":"kwic","name":"bar"},null]
    [">kwic:bar",{"sigil":">","prefix":"kwic","name":"bar"},null]
    [">!kwic:bar",null,null]
    ["<>kwic:bar",null,null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      R = ( probe.match L._datom_keypattern )?.groups ? null
      return null unless R?
      for key, value of R
        delete R[ key ] if value is undefined
      return R
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "classify_selector" ] = ( T, done ) ->
  probes_and_matchers = [
    ["#justatag",["tag","justatag"],'illegal']
    ["^bar",["keypattern",{"sigils":"^","name":"bar"}],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      probe = ( -> ) if probe.startsWith '!!!'
      R     = L._classify_selector probe
      if R[ 0 ] is 'keypattern'
        for key, value of R[ 1 ]
          delete R[ 1 ][ key ] if value is undefined
      else if R[ 0 ] is 'function'
        R[ 1 ] = null
      return R
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "select 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ {key:'^number',value:42,$stamped:true}, '^number'],false]
    [[ {key:'<italic',$stamped:true}, '<italic'],false]
    [[ {key:'<italic',$stamped:true}, '<>italic'],false]
    [[ {key:'^number',value:42}, '^number'],true]
    [[ {key:'^number',value:42,$stamped:true}, '^number#stamped'],true]
    [[ {key:'<italic',$stamped:true}, '<italic#stamped'],true]
    [[ {key:'<italic',$stamped:true}, '>italic#stamped'],false]
    [[ {key:'<italic',$stamped:true}, '<>italic#stamped'],true]
    [[ {key:'<italic'}, '<italic#stamped'],true]
    [[ {key:'<italic'}, '>italic#stamped'],false]
    [[ {key:'<italic'}, '<>italic#stamped'],true]
    [[ {key:'<italic',$stamped:true}, '>italic'],false]
    [[ {key:"*data"},'*data'],null,'illegal key or selector']
    [[ {key:"data>"},'data>'],null,'illegal key or selector']
    [[ {key:"%data"},'%data'],null,'illegal key or selector']
    [[ {key:"[data"},'[data'],true,null]
    [[ {key:"data]"},'data]'],null,'illegal key or selector']
    [[ {key:"]data"},']data'],true,null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      [ d, selectors..., ] = probe
      return PD.select d, selectors...
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "select ignores values other than PODs" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ null, '^number',],false]
    [[ 123, '^number',],false]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ d, selector, ] = probe
      try
        resolve PD.select d, selector
      catch error
        return resolve error.message
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "_regex performance, runaway test" ] = ( T, done ) ->
  ###
  See https://github.com/loveencounterflow/runaway-regex-test
  and select-benchmark in this project
  ###




############################################################################################################
unless module.parent?
  test @
  # test @[ "selector keypatterns" ]
  # test @[ "select 2" ]

