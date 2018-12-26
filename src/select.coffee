
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
@_keypattern = ///^(?<sigils>[<^>~]*) \s* (?:(?<prefix>[^:<^>~\s]+?):)? \s* (?<name>[^:<^>~\s]*)$///

#-----------------------------------------------------------------------------------------------------------
@_tag_from_selector = ( selector ) ->
  ### Return tag if `selector` is marked as tag selector, `null` otherwise. ###
  return null unless ( CND.isa_text selector ) and ( selector.startsWith '#' ) and ( selector.length > 1 )
  return selector[ 1 .. ]

#-----------------------------------------------------------------------------------------------------------
@_classify_selector = ( selector ) ->
  return [ 'function',    selector,     ] if CND.isa_function selector
  throw new Error "µ99843 expected a text, got a #{type}" unless ( type = CND.type_of selector ) is 'text'
  return [ 'tag',         tag,          ] if ( tag = @_tag_from_selector selector )?
  return [ 'keypattern',  match.groups, ] if ( match = selector.match @_keypattern )?
  throw new Error "µ99843 illegal selector #{rpr selector}"

#-----------------------------------------------------------------------------------------------------------
@_match_keypattern = ( d_key, keypattern ) ->
  throw new Error "µ77784 illegal event key #{rpr d_key}" unless ( CND.isa_text d_key ) and ( d_key.length > 1 )
  sigil = d_key[ 0 ]
  throw new Error "µ77784 event key #{rpr d_key} has illegal sigil #{rpr sigil}" unless ( sigil in '<^>~' )
  sigils_ok = sigil in keypattern.sigils
  return false unless sigils_ok
  #.........................................................................................................
  throw new Error "µ77784 illegal event key #{rpr d_key}" unless ( match = d_key.match @_keypattern )?
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
@_select_one = ( d, selector ) ->
  [ clasz, selector, ] = @_classify_selector selector
  return switch clasz
    when 'function'   then  selector          d
    when 'tag'        then  _match_tag        d, selector
    when 'keypattern' then  @_match_keypattern d, selector
  throw new Error "µ37373 illegal selector class #{rpr clasz}"

