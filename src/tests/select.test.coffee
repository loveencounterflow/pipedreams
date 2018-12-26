

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
# PS                        = require '../..'
# { $, $async, }            = PS



#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null


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
      echo CND.crimson "unexpected exception", ( jr [ probe, null, error.message, ] )
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
    ["  ",{"sigils":"","name":""},null]
    [">foo",{"sigils":">","name":"foo"},null]
    ["<>foo",{"sigils":"<>","name":"foo"},null]
    ["<>^foo",{"sigils":"<>^","name":"foo"},null]
    ["^ foo",{"sigils":"^","name":"foo"},null]
    ["<  foo",{"sigils":"<","name":"foo"},null]
    ["> foo",{"sigils":">","name":"foo"},null]
    ["<> foo",{"sigils":"<>","name":"foo"},null]
    ["^<> foo",{"sigils":"^<>","name":"foo"},null]
    ['< > ^ foo',null,"Cannot read property 'groups' of null"]
    ["^prfx:foo",{"sigils":"^","prefix":"prfx","name":"foo"},null]
    ["<prfx:foo",{"sigils":"<","prefix":"prfx","name":"foo"},null]
    [">prfx:foo",{"sigils":">","prefix":"prfx","name":"foo"},null]
    ["<>prfx:foo",{"sigils":"<>","prefix":"prfx","name":"foo"},null]
    ["<>^prfx:foo",{"sigils":"<>^","prefix":"prfx","name":"foo"},null]
    ["^ prfx: foo",{"sigils":"^","prefix":"prfx","name":"foo"},null]
    ["<  prfx: foo",{"sigils":"<","prefix":"prfx","name":"foo"},null]
    ["> prfx: foo",{"sigils":">","prefix":"prfx","name":"foo"},null]
    ["<> prfx: foo",{"sigils":"<>","prefix":"prfx","name":"foo"},null]
    ["^<> prfx: foo",{"sigils":"^<>","prefix":"prfx","name":"foo"},null]
    ["< > ^ prfx: foo",null,"Cannot read property 'groups' of null"]
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
@[ "select 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[ '^frob', '^frob'],true]
    [[ '^frob', '<frob'],false]
    [[ '^frob', '<>frob'],false]
    [[ '^frob', '<^>frob'],true]
    [[ '^frob', '<>^frob'],true]
    [[ '<frob', '<>^frob'],true]
    [[ '>frob', '<>^frob'],true]
    [[ 'frob', '<>^frob'],null,"illegal event key 'frob'"]
    [[ '~copy', '~frob'],false]
    [[ '~copy', '~copy'],true]
    [[ '~copy', '^~copy'],true]
    [[ '~copy', '<>^~copy'],true]
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      [ key, selector, ]  = probe
      d                   = { key, }
      return L._select_one d, 'keypattern', selector
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "classify_selector" ] = ( T, done ) ->
#   probes_and_matchers = [
#     ["#justatag",["tag","justatag"],null]
#     ["^bar",["keypattern",{"sigils":"^","name":"bar"}],null]
#     ["!!!(->)",["function",null],null]
#     ]
#   #.........................................................................................................
#   for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
#     method = ->
#       probe = ( -> ) if probe.startsWith '!!!'
#       R     = L._classify_selector probe
#       if R[ 0 ] is 'keypattern'
#         for key, value of R[ 1 ]
#           delete R[ 1 ][ key ] if value is undefined
#       else if R[ 0 ] is 'function'
#         R[ 1 ] = null
#       return R
#     await f T, method, probe, matcher, errmsg_pattern
#   done()
#   return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "select 2" ] = ( T, done ) ->
#   probes_and_matchers = [
#     [[ {key:'^number',value:42}, '^number'],true]
#     [[ {key:'^number',value:42,stamped:true}, '^number'],false]
#     ]
#   #.........................................................................................................
#   for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
#     method = ->
#       [ d, selectors..., ] = probe
#       return L.select d, selectors...
#     await f T, method, probe, matcher, errmsg_pattern
#   done()
#   return null






############################################################################################################
unless module.parent?
  # include = [
  #   "async 1"
  #   "async 1 paramap"
  #   "async 2"
  #   ]
  # @_prune()
  test @



