
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/FREEZE'
debug                     = CND.get_logger 'debug',     badge
{ assign
  copy
  jr }                    = CND
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
  declare
  size_of
  type_of }               = types
ICE                       = require 'icepick'

#-----------------------------------------------------------------------------------------------------------
@freeze = ( x       ) -> ICE.freeze x
@thaw   = ( x       ) -> ICE.thaw   x
@set    = ( x, k, v ) -> ICE.set    x, k, v
@unset  = ( x, k    ) -> ICE.unset  x, k

