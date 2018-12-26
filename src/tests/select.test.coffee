
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
# PS                        = require '../..'
# { $, $async, }            = PS



#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
select = ( d, selectors... ) ->
  throw new Error "µ29929 expected selectors, got none" if selectors.length is 0
  for selector in selectors
    return false unless _select_one selector
  return true

#-----------------------------------------------------------------------------------------------------------
_keypattern = ///^(?<sigils>[<^>~]*) \s* (?:(?<prefix>[^:<^>~\s]+?):)? \s* (?<name>[^:<^>~\s]*)$///

#-----------------------------------------------------------------------------------------------------------
_tag_from_selector = ( selector ) ->
  ### Return tag if `selector` is marked as tag selector, `null` otherwise. ###
  return null unless ( CND.isa_text selector ) and ( selector.startsWith '#' ) and ( selector.length > 1 )
  return selector[ 1 .. ]

#-----------------------------------------------------------------------------------------------------------
_classify_selector = ( selector ) ->
  return [ 'function',    selector,     ] if CND.isa_function selector
  throw new Error "µ99843 expected a text, got a #{type}" unless ( type = CND.type_of selector ) is 'text'
  return [ 'tag',         tag,          ] if ( tag = _tag_from_selector selector )?
  return [ 'keypattern',  match.groups, ] if ( match = selector.match _keypattern )?
  throw new Error "µ99843 illegal selector #{rpr selector}"

#-----------------------------------------------------------------------------------------------------------
_match_keypattern = ( d, keypattern ) ->
  sigils_ok = d[ 0 ] in keypattern.sigils
  return false unless sigils_ok
  #.........................................................................................................
  throw new Error "illegal event key #{rpr d.key}" unless ( match = d.match _keypattern )?
  if keypattern.prefix? and ( keypattern.prefix isnt '*' )
    prefix_ok = ( match.groups.prefix is keypattern.prefix )
    return false unless prefix_ok
  #.........................................................................................................
  if keypattern.name? and ( keypattern.name.length > 0 )
    name_ok = ( keypattern.name is match.groups.name )
    return false unless name_ok
  #.........................................................................................................
  return true

#-----------------------------------------------------------------------------------------------------------
_select_one = ( d, selector ) ->
  [ clasz, selector, ] = _classify_selector selector
  return switch clasz
    when 'function'   then  selector          d
    when 'tag'        then  _match_tag        d, selector
    when 'keypattern' then  _match_keypattern d, selector
  throw new Error "µ37373 illegal selector class #{rpr clasz}"


#-----------------------------------------------------------------------------------------------------------
f = ( T, method, probe, matcher, errmsg_pattern ) ->
  errmsg_pattern = if errmsg_pattern? then ( new RegExp errmsg_pattern ) else null
  try
    result = await method()
  catch error
    throw error
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
      R = ( probe.match _keypattern )?.groups ? null
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
    ]
  #.........................................................................................................
  for [ probe, matcher, errmsg_pattern, ] in probes_and_matchers
    method = ->
      [ d, selector, ] = probe
      return _select_one d, selector
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



