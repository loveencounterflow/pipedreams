
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

#-----------------------------------------------------------------------------------------------------------
### TAINT use named subpatterns ###
@_event_keypattern    = ///^
  (?<sigil>[<^>~\[\]])
  (?:(?<prefix>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+?):)?
  (?<name>[^:<^>~!$%&\/()=?+*'",.;|\#\s]+)
  $///

#-----------------------------------------------------------------------------------------------------------
@_selector_keypattern = ///^
  (?<sigils>[<^>~\[\]]*)
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
  return [ 'function',    selector,     ] if CND.isa_function selector
  throw new Error "µ85175 expected a text, got a #{type}" unless ( type = CND.type_of selector ) is 'text'
  return [ 'tag',         tag,          ] if ( tag = @_tag_from_selector selector )?
  return [ 'keypattern',  ( @_selector_as_facets selector ), ]

#-----------------------------------------------------------------------------------------------------------
@_key_as_facets       = ( key       ) -> @_key_or_pattern_as_facets key,      @_event_keypattern
@_selector_as_facets  = ( selector  ) -> @_key_or_pattern_as_facets selector, @_selector_keypattern

#-----------------------------------------------------------------------------------------------------------
@_key_or_pattern_as_facets = ( x, re ) ->
  unless ( CND.isa_text x ) and ( match = x.match re )?
    throw new Error "µ83744 illegal key or selector #{rpr x}"
  R = match.groups
  for k, v of R
    delete R[ k ] if v in [ '', null, undefined, ]
  return R

#-----------------------------------------------------------------------------------------------------------
@_settings_defaults = { stamped: false, }

#-----------------------------------------------------------------------------------------------------------
@_settings_from_tags = ( tags ) ->
  R = assign {}, @_settings_defaults
  for tag from tags
    switch tag
      when 'stamped' then R.stamped = true
      else throw new Error "µ20201 illegal tag #{rpr tag}"
  return R


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@select = ( d, selectors... ) ->
  throw new Error "µ86606 expected one or more selectors, got none" if selectors.length is 0
  throw new Error "µ00922 expected object with at least a `key` property, got #{rpr d}" unless d?.key?
  #.........................................................................................................
  key_facets            = @_key_as_facets d.key
  tags                  = new Set()
  other_selectors       = []
  selectors             = CND.flatten selectors
  classes_and_selectors = []
  #.........................................................................................................
  for selector in selectors
    try
      classes_and_selectors.push @_classify_selector selector
    catch error
      error.message += "\nµ22092 datom #{jr d},\nselector #{jr selector}"
      throw error
  #.........................................................................................................
  for [ clasz, selector, ] in classes_and_selectors
    if clasz is 'tag' then  tags.add selector
    else                    other_selectors.push [ clasz, selector, ]
  #.........................................................................................................
  settings = @_settings_from_tags tags
  return false if d.stamped and not settings.stamped
  #.........................................................................................................
  for [ clasz, selector, ] in other_selectors
    is_matching = switch clasz
      when 'function'   then  selector d
      when 'keypattern' then  @_match_keypattern key_facets, selector, settings
      else throw new Error "µ86129 illegal selector class #{rpr clasz}"
    return false unless is_matching
  return true





