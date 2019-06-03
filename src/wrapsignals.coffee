
#-----------------------------------------------------------------------------------------------------------
@$wrapsignals = ->
  ###

  ```
  {"value":1,"first":true,"last":true}
  ```

  ```
  {"value":1,"first":true}
  {"value":2,"last":true}
  ```

  ```
  {"value":1,"first":true}
  {"value":2}
  {"value":3}
  {"value":4}
  {"value":5,"last":true}
  ```

  ###
  is_first  = true
  prv_d     = null
  last      = Symbol 'last'
  return @$ { last, }, ( d, send ) =>
    if d is last
      if prv_d?
        prv_d.first = true if is_first
        prv_d.last  = true
        send prv_d
    else
      if prv_d?
        send prv_d
      prv_d       = { value: d, }
      prv_d.first = true if is_first
      is_first    = false
    return null
