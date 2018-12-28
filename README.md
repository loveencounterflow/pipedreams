

## PipeDreams Datoms (Data Events)

Data streams—of which [pull-streams](https://pull-stream.github.io/),
[PipeStreams](https://github.com/loveencounterflow/pipestreams), and [NodeJS
Streams](https://nodejs.org/api/stream.html) are examples—do their work by
sending pieces of data (that originate from a data source) through a number of
transforms (to finally end up in a data sink).*

> (\*) I will ignore here alternative ways of dealing with streams, especially
> the [`EventEmitter` way of dealing with streamed
> data](https://nodejs.org/api/stream.html#stream_api_for_stream_consumers).
> When I say 'streams', I also implicitly mean 'pipelines'; when I say
> 'pipelines', I also implicitly mean 'pipelines to stream data' and 'streams'
> in general.

When NodeJS streams started out, the thinking about those streams was pretty
much confined to saying that ['a stream is a series of
bytes'](http://dominictarr.com/post/145135293917/history-of-streams). Already back then,
an alternative view took hold (I'm slightly paraphrasing here):

> The core interpretation was that stream could be buffers or strings - but the
> userland interpretation was that a stream could be anything that is
> serializeable [...] it was a sequence of buffers, bytes, strings or objects.
> Why not use the same api?

I will no repeat here [what I've written about perceived shortcomings of NodeJS
streams](https://github.com/loveencounterflow/pipestreams/blob/master/pipestreams-manual/chapter-00-comparison.md);
instead, let me iterate a few observations:

* When streaming, data is just data. There's no need for having [a separate
  'Object Mode'](https://nodejs.org/api/stream.html#stream_object_mode) or
  somesuch.

* There's a single exception to the above rule, and that is when the data item
  being sent down the line is `null`. This has historically—by both NodeJS
  streams and pull-streams—been regarded as a hint interpreted as a termination
  signal, and I'm not going to change that (although at some point I might as
  well).

* When starting out with streams and building fairly simple-minded piplines,
  having wither a piece of business data or else `null` to indicate termination
  is enough to satisfy most needs. However, when one goes on to build more
  complex processing scenarios, raw data is not expressive enough. For example,
  in a [more complex
  environment](https://github.com/loveencounterflow/mingkwai-typesetter/blob/master/src/tex-writer.coffee#L2527)*

> (\*) This software is just presented as a code example. It is currently not
> considered consumable for the general audience.

```
d         := { key, value, ..., $, }

key       := sigil name
          := sigil prefix ':' name

prefix    := non-empty text

sigil     := '^' # proper singleton
          := '~' # system singleton
          := '<' # start-of-region (SOR)
          := '>' # end-of-region   (EOR)

value     := any                    # payload

$         := pod                    # system-level attributes, to be copied from old to new events
```

Each `key` *must* be preceded by a `sigil` which indicates the event category.

`prefix` indicates the namespace; where missing, the default namespace is assumed.


### `select = ( d, selectors... ) ->`

The `select` method can be used to determine whether a given event `d` matches a
set of conditions; typically, one will want to use `select d, ...` to decide
whether a given event is suitable for processing by the stream transform at
hand, or whether it should be passed on unchanged.

Given an event `d` and a number of `selectors`, return whether `d` matches all
of the selectors.

Selectors can be of three kinds:

* **key patterns**: e.g. `'^prfx:myname'` will match all singular events (`^`)
  that have a namespace prefix `prfx` and a name `myname`.

* **boolean functions**: e.g. `( ( d ) -> d.value > 42 )` will match all events
  that have a `value` that is greater than `42`.

* **tags** that configure matching details: e.g. `'#stamped'` will match
  un-`stamped` events as well as `stamped` ones (which are otherwise excluded
  from matching).

A given event will be 'selected' (i.e. `select d, ...` will return `true`) only
if all conditions are met; as a consequence, `select d, '^', 'text'` ('select
singleton events whose name is `'text'`) is equivalent to `( select d, '^' ) and
( select d, 'text' )`. Incidentally, this is also equivalent to `select '^text'`
since sigils and names may be contracted into a single selector.

Observe that

* tags must appear on their own, (so `select '^text#stamped'` is not OK), and
  that

* `'#stamped'` means 'event *may* have property `{ stamped: true, }`, *not* that
  it *must* be `stamped`. In order to only select singleton `text` events that
  are also `stamped`, use a boolean function like `select d, '^text', ( ( d ) ->
  d.stamped ? false )` (which in practice you will probably want to name so you
  can write the much clearer expression `select '^text', is_stamped`).

**NOTE** One could argue that a call `select d` without any selectors should be
legal and always return `true`; while that is a perfectly logical extension, in
practice it is probably a programmer's error, which is why `select d` will throw
an error.


## Aggregate Transforms

### `$collect = ( settings ) ->`

This is an improved version of `PS.$collect()`. While `PS.$collect()` will merely
buffer all events in a list and send on that list when the stream is terminated,
`PD.$collect()` is PipeDreams



