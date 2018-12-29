

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
# { $, $async, }            = PD

#-----------------------------------------------------------------------------------------------------------
f = ( T, method, probe, matcher, errmsg_pattern ) ->
  errmsg_pattern = if errmsg_pattern? then ( new RegExp errmsg_pattern ) else null
  try
    result = await method()
  catch error
    # throw error
    if errmsg_pattern? and ( errmsg_pattern.test error.message )
      echo CND.green jr [ probe, null, errmsg_pattern.source, ]
      T.ok true
    else
      echo CND.indigo "unexpected exception", ( jr [ probe, null, error.message, ] )
      T.fail "unexpected exception for probe #{jr probe}:\n#{error.message}"
      # return reject "failed with #{error.message}"
    return null
  if CND.equals result, matcher
    T.ok true
    echo CND.lime jr [ probe, result, null, ]
  else
    T.fail "neq: result #{jr result}, matcher #{jr matcher}"
    echo CND.red jr [ probe, result, null, ]
  # return resolve result
  return result

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
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      R = ( probe.match L._selector_keypattern )?.groups ? null
      return null unless R?
      for key, value of R
        delete R[ key ] if value is undefined
      return R
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "event keypatterns" ] = ( T, done ) ->
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
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      R = ( probe.match L._event_keypattern )?.groups ? null
      return null unless R?
      for key, value of R
        delete R[ key ] if value is undefined
      return R
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "classify_selector" ] = ( T, done ) ->
  probes_and_matchers = [
    ["#justatag",["tag","justatag"],null]
    ["^bar",["keypattern",{"sigils":"^","name":"bar"}],null]
    ["!!!(->)",["function",null],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      probe = ( -> ) if probe.startsWith '!!!'
      R     = L._classify_selector probe
      if R[ 0 ] is 'keypattern'
        for key, value of R[ 1 ]
          delete R[ 1 ][ key ] if value is undefined
      else if R[ 0 ] is 'function'
        R[ 1 ] = null
      return R
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "select 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ {key:'^number',value:42}, '^number'],true]
    [[ {key:'^number',value:42,stamped:true}, '^number'],false]
    [[ {key:'^number',value:42,stamped:true}, '#stamped', '^number'],true]
    [[ {key:'<italic',stamped:true}, '#stamped', '<italic'],true]
    [[ {key:'<italic',stamped:true}, '#stamped', '>italic'],false]
    [[ {key:'<italic',stamped:true}, '#stamped', '<>italic'],true]
    [[ {key:'<italic'}, '#stamped', '<italic'],true]
    [[ {key:'<italic'}, '#stamped', '>italic'],false]
    [[ {key:'<italic'}, '#stamped', '<>italic'],true]
    [[ {key:'<italic',stamped:true}, '<italic'],false]
    [[ {key:'<italic',stamped:true}, '>italic'],false]
    [[ {key:'<italic',stamped:true}, '<>italic'],false]
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
@[ "select 2 using lists" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ {key:'^number',value:42},              ['^number',             ]  ],true]
    [[ {key:'^number',value:42,stamped:true}, ['^number',             ]  ],false]
    [[ {key:'^number',value:42,stamped:true}, ['#stamped', '^number', ]  ],true]
    [[ {key:'<italic',stamped:true},          ['#stamped', '<italic', ]  ],true]
    [[ {key:'<italic',stamped:true},          ['#stamped', '>italic', ]  ],false]
    [[ {key:'<italic',stamped:true},          ['#stamped', '<>italic',]  ],true]
    [[ {key:'<italic'},                       ['#stamped', '<italic', ]  ],true]
    [[ {key:'<italic'},                       ['#stamped', '>italic', ]  ],false]
    [[ {key:'<italic'},                       ['#stamped', '<>italic',]  ],true]
    [[ {key:'<italic',stamped:true},          ['<italic',             ]  ],false]
    [[ {key:'<italic',stamped:true},          ['>italic',             ]  ],false]
    [[ {key:'<italic',stamped:true},          ['<>italic',            ]  ],false]
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      [ d, selectors..., ] = probe
      return PD.select d, selectors...
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "select 3" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ {key:'^number',value:42}, '^number', "( d ) => d.value > 42"],false]
    [[ {key:'^number',value:44}, '^number', "( d ) => d.value > 42"],true]
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      [ d, selectors..., ] = probe
      selectors[ selectors.length - 1 ] = eval selectors[ selectors.length - 1 ]
      return PD.select d, selectors...
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null


# first-only
# last-only
# before-start
# after-stop




############################################################################################################
unless module.parent?
  test @



