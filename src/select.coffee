
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/SELECT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND

#-----------------------------------------------------------------------------------------------------------
@_event_keypattern    = ///^ (?<sigil>[<^>~])       (?:(?<prefix>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+?):)?     (?<name>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+) $///
@_selector_keypattern = ///^ (?<sigils>[<^>~]*) \s* (?:(?<prefix>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+?):)? \s* (?<name>[^:<^>~!$%&\/()=?+*'",.;|\#\s]*) $///

#-----------------------------------------------------------------------------------------------------------
@_tag_from_selector = ( selector ) ->
  ### Return tag if `selector` is marked as tag selector, `null` otherwise. ###
  return null unless ( CND.isa_text selector ) and ( selector.startsWith '#' ) and ( selector.length > 1 )
  return selector[ 1 .. ]

#-----------------------------------------------------------------------------------------------------------
@_match_keypattern = ( key, selector ) ->
  #.........................................................................................................
  ### TAINT code duplication ###
  unless ( CND.isa_text key ) and ( key_match = key.match @_event_keypattern )?
    throw new Error "µ83744 illegal event key #{rpr key}"
  key_facets = key_match.groups
  for k, v of key_facets
    delete key_facets[ k ] if v in [ '', null, undefined, ]
  #.........................................................................................................
  ### TAINT code duplication ###
  unless ( CND.isa_text selector ) and ( selector_match = selector.match @_selector_keypattern )?
    throw new Error "µ83744 illegal selector #{rpr selector}"
  selector_facets = selector_match.groups
  for k, v of selector_facets
    delete selector_facets[ k ] if v in [ '', null, undefined, ]
  #.........................................................................................................
  return false if selector_facets.sigils? and not ( key_facets.sigil in selector_facets.sigils )
  return false if ( not selector_facets.prefix? ) and ( key_facets.prefix? )
  return false if selector_facets.prefix? and not ( key_facets.prefix is selector_facets.prefix )
  return false if selector_facets.name? and not ( key_facets.name is selector_facets.name )
  return true


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@_classify_selector = ( selector ) ->
  return [ 'function',    selector,     ] if CND.isa_function selector
  throw new Error "µ85175 expected a text, got a #{type}" unless ( type = CND.type_of selector ) is 'text'
  return [ 'tag',         tag,          ] if ( tag = @_tag_from_selector selector )?
  return [ 'keypattern',  match.groups, ] if ( match = selector.match @_keypattern )?
  throw new Error "µ85652 illegal selector #{rpr selector}"

#-----------------------------------------------------------------------------------------------------------
@_select_one = ( d, clasz, selector, settings ) ->
  return switch clasz
    when 'function'   then  selector            d
    # when 'tag'        then  @_match_tag         d,      selector
    when 'keypattern' then  @_match_keypattern  d.key,  selector
  throw new Error "µ86129 illegal selector class #{rpr clasz}"


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@select = ( d, selectors... ) ->
  throw new Error "µ86606 expected one or more selectors, got none" if selectors.length is 0
  tags                  = []
  other_selectors       = []
  classes_and_selectors = ( @_classify_selector selector for selector in selectors )
  for [ clasz, selector, ] in classes_and_selectors
    if clasz is 'tag' then  tags.push             selector
    else                    other_selectors.push  selector
  debug '37773', [ tags, other_selectors, ]
  settings = null ### !!!!!!!!!!!!!!! ###
  for selector in other_selectors
    return false unless @_select_one d, clasz, selector, settings
  return true

