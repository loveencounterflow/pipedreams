

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
      echo CND.orange jr [ probe, null, error.message, ]
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
@[ "keypattern" ] = ( T, done ) ->
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
      R = ( probe.match L._keypattern )?.groups ? null
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
    [[ 'frob', '<>^frob'],null,"event key 'frob' has illegal sigil 'f'"]
    [[ '~copy', '~frob'],false]
    [[ '~copy', '~copy'],true]
    [[ '~copy', '^~copy'],true]
    [[ '~copy', '<>^~copy'],true]
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      [ d, selector, ] = probe
      return L._select_one d, selector
    await f T, method, probe, matcher, errmsg_pattern
  done()
  return null






############################################################################################################
unless module.parent?
  # include = [
  #   "async 1"
  #   "async 1 paramap"
  #   "async 2"
  #   ]
  # @_prune()
  test @



