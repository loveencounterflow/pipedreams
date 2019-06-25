
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
{ assign
  jr }                    = CND
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
### TAINT use named subpatterns ###
@_datom_keypattern    = ///^
  (?<sigil>[<^>~\[\]])
  (?:(?<prefix>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+?):)?
  (?<name>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+)
  $///

#-----------------------------------------------------------------------------------------------------------
@_selector_keypattern = ///^
  (?<sigils>[<^>~\[\]]{0,6})
  (?:(?<prefix>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+?):)?
  (?<name>[^:<^>~!$%&\/()=?+*'",.;|\#\s]*)
  $///

#-----------------------------------------------------------------------------------------------------------
@_tag_pattern = ///^
  \#
  (?<tag>[^:<^>~!$%&\/\[\]{()}=?+*'",.;|\#\s]*)
  $///

#-----------------------------------------------------------------------------------------------------------
@_tag_from_selector = ( selector ) ->
  ### Return tag if `selector` is marked as tag selector, `null` otherwise. ###
  return null unless CND.isa_text selector
  return null unless ( match = selector.match @_tag_pattern )?
  return match.groups.tag

#-----------------------------------------------------------------------------------------------------------
@_match_keypattern = ( key_facets, selector_facets, settings ) ->
  return false if selector_facets.sigils? and not ( key_facets.sigil in selector_facets.sigils )
  return false if ( not selector_facets.prefix? ) and ( key_facets.prefix? )
  return false if selector_facets.prefix? and not ( key_facets.prefix is selector_facets.prefix )
  return false if selector_facets.name? and not ( key_facets.name is selector_facets.name )
  return true


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@_classify_selector = ( selector ) ->
  throw new Error "µ85175 expected a text, got a #{type}" unless ( type = type_of selector ) is 'text'
  return [ 'keypattern',  ( @_selector_as_facets selector ), ]

#-----------------------------------------------------------------------------------------------------------
@_key_as_facets       = ( key       ) -> @_key_or_pattern_as_facets key,      @_datom_keypattern
@_selector_as_facets  = ( selector  ) -> @_key_or_pattern_as_facets selector, @_selector_keypattern

#-----------------------------------------------------------------------------------------------------------
@_key_or_pattern_as_facets = ( x, re ) ->
  unless ( isa.text x ) and ( match = x.match re )?
    throw new Error "µ83744 illegal key or selector #{rpr x}"
  R = match.groups
  for k, v of R
    delete R[ k ] if v in [ '', null, undefined, ]
  return R



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@select = ( d, selector ) ->
  throw new Error "µ86606 expected a selector, got none" unless selector?
  return false unless ( ( isa.object d ) and ( d.key? ) )
  #.........................................................................................................
  stamped = false
  if selector.endsWith '#stamped'
    stamped   = true
    selector  = selector[ ... selector.length - 8 ]
    throw new Error "µ33982 selector cannot just contain tag '#stamped'" if selector is ''
  #.........................................................................................................
  throw new Error "µ37783 illegal selector #{rpr selector}" unless selector_pattern.test selector
  #.........................................................................................................
  return false if ( not stamped ) and ( d.$stamped ? false )
  return d.key is selector

selector_pattern = /^[<^>\[~\]][^<^>\[~\]]*$/



