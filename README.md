


# PipeDreams

![stability-experimental-red](https://img.shields.io/badge/stability-experimental-red.svg)
![npm-0.2.5-yellowgreen](https://img.shields.io/badge/npm-0.2.5-yellowgreen.svg)
![motivation-字面明快排字機-yellow](https://img.shields.io/badge/motivation-字面明快排字機-yellow.svg)

A library to make creating NodeJS streams and transforms sort-of simple.

Install as `npm install --save pipedreams2`.

![Der Pfeifenraucher](https://github.com/loveencounterflow/pipedreams/raw/v4/art/Der%20Frosch%20und%20die%20beiden%20Enten_0015.png)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [PipeDreams v4 API](#pipedreams-v4-api)
  - [Require Statement](#require-statement)
  - [remit (aka $) and remit_async (aka $async)](#remit-aka--and-remit_async-aka-async)
  - [Never Assume Your Streams to be Synchronous](#never-assume-your-streams-to-be-synchronous)
  - [Stream Creation](#stream-creation)
  - [The Remit and Remit-Async Methods](#the-remit-and-remit-async-methods)
    - [(Synchronous) Stream Observer](#synchronous-stream-observer)
    - [Synchronous Transform, No Stream End Detection](#synchronous-transform-no-stream-end-detection)
    - [Synchronous Transform With Stream End Detection](#synchronous-transform-with-stream-end-detection)
    - [Asynchronous Transforms](#asynchronous-transforms)
    - [@$](#@)
    - [@$as_text = ( stringify ) ->](#@as_text---stringify---)
    - [@$async](#@async)
    - [@$batch](#@batch)
    - [@$collect](#@collect)
    - [@$count](#@count)
    - [@$filter](#@filter)
    - [@$join = ( joiner = '\n' ) ->](#@join---joiner--%5Cn---)
    - [@$lockstep](#@lockstep)
    - [@$on_end](#@on_end)
    - [@$on_first](#@on_first)
    - [@$on_start](#@on_start)
    - [@$parse_csv](#@parse_csv)
    - [@$pass_through](#@pass_through)
    - [@$sample = ( p = 0.5, options ) ->](#@sample---p--05-options---)
    - [@$show](#@show)
    - [@$sort](#@sort)
    - [@$sort = ( sorter, settings ) ->](#@sort---sorter-settings---)
    - [@$split = ( matcher, mapper, settings ) ->](#@split---matcher-mapper-settings---)
    - [@$split_tsv = ( settings ) ->](#@split_tsv---settings---)
    - [@$spread](#@spread)
    - [@$stop_time](#@stop_time)
    - [@$throttle_bytes](#@throttle_bytes)
    - [@$throttle_items](#@throttle_items)
    - [@end = ( me ) ->](#@end---me---)
    - [@isa_stream](#@isa_stream)
    - [@new_stream](#@new_stream)
    - [@new_stream_from_pipeline](#@new_stream_from_pipeline)
    - [@new_stream_from_text](#@new_stream_from_text)
    - [@remit](#@remit)
    - [@remit_async](#@remit_async)
    - [@run](#@run)
    - [@send = ( me, data ) ->](#@send---me-data---)
- [Backmatter](#backmatter)
  - [Under the Hood: Base Libraries](#under-the-hood-base-libraries)
    - [Through2](#through2)
  - [What's in a Name?](#whats-in-a-name)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

**Caveat** Below examples are all written in CoffeeScript.


# PipeDreams v4 API

## Require Statement

The suggested way to `require` the PipeDreams library itself and to factor
out the most important methods for convenience is as follows:

```coffee
D               = require 'pipedreams'
{ $
  $async }      = D
```

If you don't like dollar signs in your code or `$` is already used for something
else, you can either use `D.$` or `D.remit` or, alternatively,

```coffee
D               = require 'pipedreams'
{ remit
  remit_async } = D
```

In the below, I will assume you `require`d PipeDreams the first way, above.

## remit (aka $) and remit_async (aka $async)

The `remit` method (as well as its asynchronous companion, `remit_async`)  is
very much the centerpiece of the PipeDreams API¹. It accepts a function (call
it a 'transformation') and returns a stream transform. In case you're
familiar with the [*event-stream*](https://github.com/dominictarr/event-stream)
way of doing things, then PipeDreams' `remit f` is roughly equivalent
to event-stream's  `through on_data, on_end`, except you can handle both the
`on_data` and `on_end` parts in a single function `f`. `remit_async f` is
roughly equivalent to event-stream's `map f`.


## Never Assume Your Streams to be Synchronous

As a general note that users should keep in mind, please observe that no
guarantee is made that any given stream works in a synchronous manner. More
specifically and with regard to the most typical usage pattern: never deal
with pipelined data 'right below' the pipeline definition, always do that
from inside a stream transform.

Here's an example from `src/tests.coffee`: we create a stream, define a
pipeline to split the text into lines and collect those lines into a list;
then, we write a multi-line string to it and end the stream. When we now look
at what's ended up in the collector, we find that the last line is  missing.
This may come as a surprise, since nothing in the code suggests that the thing
should not work in a simple top-down manner:

```coffee
@[ "(v4) new_stream_from_text doesn't work synchronously" ] = ( T, done ) ->
  collector = []
  input     = D.new_stream()
  input
    .pipe D.$split()
    .pipe $ ( line, send ) =>
      send line
      collector.push line
  input.write "first line\nsecond line"
  input.end()
  T.eq collector, [ "first line", ] # <-- we're missing the last line here
  done()
```

In order for the code to meet expectations, remember to always grab
your results from within a stream transform; commonly, this is either
done by using a [Synchronous Transform With Stream End Detection](#synchronous-transform-with-stream-end-detection),
or `D.$on_end`:

```coffee
@[ "(v4) new_stream_from_text (2)" ] = ( T, done ) ->
  collector = []
  input     = D.new_stream()
  input
    .pipe D.$split()
    .pipe $ ( line, send ) =>
      send line
      collector.push line
    .pipe D.$on_end =>
      T.eq collector, [ "first line", "second line", ]
      done()
  input.write "first line\nsecond line"
  input.end()
```

## Stream Creation

```coffee
@new_stream = ( settings ) ->

D.new_stream()
D.new_stream pipeline: [ transform, transform, ..., ]
D.new_stream text: "helo world"

D.new_stream           file: "/tmp/foo.txt"
D.new_stream 'read',   file: "/tmp/foo.txt"
D.new_stream 'write',  file: "/tmp/foo.txt"
D.new_stream 'append', file: "/tmp/foo.txt"

D.new_stream           path: "/tmp/foo.txt"
D.new_stream 'read',   path: "/tmp/foo.txt"
D.new_stream 'write',  path: "/tmp/foo.txt"
D.new_stream 'append', path: "/tmp/foo.txt"

D.new_stream           url: "/tmp/foo.txt"
D.new_stream 'read',   url: "/tmp/foo.txt"
D.new_stream 'write',  url: "/tmp/foo.txt"
D.new_stream 'append', url: "/tmp/foo.txt"
```

**D.new_stream** **hints**\* { **kind** **:** **locator**, }




## The Remit and Remit-Async Methods

The behavior of the stream transform—the return value of calling `remit` or
`remit_async` with a transformation function—is governed by the arity (the number of
arguments) of the transformation; you can call `remit` (`$`) with a function
that takes one, two, or three arguments, and `remit_async` (`$async`) with  a
function that takes two, or three arguments. In a nutshell, you have the
following options:

```coffee
$ ( data ) ->
$ ( data, send ) -> ...
$ ( data, send, end ) -> ...
$async ( data, send ) -> ...
$async ( data, send, end ) -> ...
```

where `data` is the current data event that comes down the stream, `send`
(where used) is a method that send data down the stream, and `end` (where used
and when actually present in the call) is a method to signal that the stream
should be ended. `send` is used as `send some_data`; it always has a member
`send.end()` to end the stream at some arbitrary point in time, and a
`send.error "message"` member to indicate that something has gone wrong.
`end()`, where used and when defined, must always be called (without any
arguments).—Now for the details.

### (Synchronous) Stream Observer

When calling `$` with a function that takes **a single argument**, you get
back an **Observer**, that is, a transform that gets all the data events
passed in, but can't send any; in a manner of speaking, an observer is a
'transformation-less transform' (note, however, that in case events are
implemented as a mutable object, such as a list or a plain old object, an
observer can still mutate that event). The observer will be called once more
with `data` set to `null` when the stream is about to end:

```coffee
$ ( data ) ->
```

You can use that idiom 'inline', i.e. right within the pipeline
notation:

```coffee
input = ( require 'fs' ).createReadStream()
input
  .pipe D.$split()      # convert buffer chunks into single-line strings
  .pipe $ ( data ) ->
    if data? then console.log "received event:", data
    else          console.log "stream has ended"
  .pipe output
```

However, for any but the most one-off, simple purposes, you'll probably want
a named function; it is customary to write the transform as a factory function
that must get called once when being entered into the pipeline.

To denote the special status of a stream transform factory—a function that is
a 'factory for potentially stateful transforms that only makes sense when
being called as argument to a `.pipe` call within a stream pipeline'
(iknowiknow, that's a mouthful)—it is also customary to prefix the name with a
`$` (dollar sign).

Since `$observe`, below, is such a factory function, the transform that
it returns may hold private state within the closure, an immensely useful
technique (notwithstanding the folks who claim that everything should be pure
functions; pure functions are great but try to count using those):

```coffee
$observe = ->
  count = 0
  return $ ( data ) ->
    if data?
      count += +1
      console.log "received event:", data
    else
      console.log "stream has ended; read #{count} events"

input = ( require 'fs' ).createReadStream()
input
  .pipe D.$split()      # Convert buffer chunks into single-line strings.
  .pipe $observe()      # Don't forget to call the factory!
  .pipe output
```

In case you were wondering, `$split()` is a useful convenience method to turn
a file readstream—which, in the absence of an encoding argument, will consist
of a series of NodeJS `Buffer` objects–into a series of strings, each one
representing one line (without the trailing newline) of the source. UTF-8
encoding is silently assumed.

**Note: If you inadvertently forget to stick that `remit` call in front of
your transformation function, you'll get an obscure error message: `Cannot
read property 'on' of undefined`. Just try to remember that this symptom is
(often) caused by an omitted `remit` / `$`.**


### Synchronous Transform, No Stream End Detection

When calling `$` with a function that takes **two arguments**, you get back a
**Synchronous Transform**. A synchronous transform receives data events and
may send on as many events as it wants—zero or a thousand. The next transform
in the pipeline will be called no sooner than the transform exits, whether it
has called `send` in the process or not. In this variant, you can rely on
`data` to never be `null`:

```coffee
$ ( data, send ) -> ...
```

An example for this form is shown in the upcoming section.

### Synchronous Transform With Stream End Detection

A **Synchronous Transform with End Detection** will be called once for each
`data` item and once when the stream is about to end. It is returned by `$`
when being called with a function that takes three arguments:

```coffee
$ ( data, send, end ) -> ...
```

When the transformation eventually gets called from within the pipeline, its
third argument (call it `end`) will be `null`, except when the the stream is
about to end. When that happens, `end` is a function that **must** be called
to end the stream. In other words, when you have `end` in your signature but
forget to call it, the stream will hang on indefinitely. This can be useful in
cases where used wisely, but has the power to bring down empires when done out
of neglect.

Use synchronous transforms when you want to both mangle data as it passes by
and aggregate data across the entire stream.

```coffee
$observe = ->
  count = 0
  return $ ( data ) ->
    if data?
      count += +1
      console.log "received event:", data
    else
      console.log "stream has ended; read #{count} events"

input = D.new_stream()  # returns a `through2` stream
input
  .pipe D.$split()      # Convert buffer chunks into single-line strings.
  .pipe $observe()      # Don't forget to call the factory!
  .pipe output

for n in [ 4, 7, 9, 3, 5, 6, ]
  input.write n
input.end()
```

### Asynchronous Transforms

**Asynchronous Transforms** are constructed in a very similar fashion to their
synchronous counterparts, except you use `$async` (or, `remit_async`) in place
of `$` (or, `remit`); furthermore, there is no counterpart to the 'observer'
call signature, so `$async` has to be called with a stream transformation that
accepts eiter two or three arguments.

**Asynchronous Transforms** are suited for intermittent file and network
reads. Since those can happen at an arbitrary time in the future, async
stream transforms must always notify the pipeline when they've finished;
to do this, there's a callback method tacked unto the `send` argument called
`send.done`.

You can call `send data` as often as you like to, but you **must** call
`send.done()` (or `send.done data`) whenever you're finished—otherwise the
pipeline will hang on indefinitely:

```coffee
$async ( data, send ) -> ...
```

An **Asynchronous Transform with End Detection** will be called
once for each `data` item and once when the stream is ended, so again,
be prepared for an empty stream where it is called once with `data` being
`null`:

```coffee
$async ( data, send, end ) -> ...
```

### @$

### @$as_text = ( stringify ) ->
Turn all data items into texts using `JSON.stringify` or a custom stringifier. `null` and any strings
in the data stream is passed through unaffected. Observe that buffers in the stream will very probably not
come out the way you'd expect them; this is because there's no way to know for the method what kind of
data they represent.

This method is handy to put as a safeguard right in front of a `.pipe output_file` clause to avoid
`illegal non-buffer` issues.

### @$async
### @$batch
### @$collect
### @$count
### @$filter

### @$join = ( joiner = '\n' ) ->
Join all strings in the stream using a `joiner`, which defaults to newline, so `$join` is the inverse
of `$split()`. The current version only supports strings, but buffers could conceivably be made to work as
well.

### @$lockstep
### @$on_end
### @$on_first
### @$on_start
### @$parse_csv
### @$pass_through

### @$sample = ( p = 0.5, options ) ->

Given a `0 <= p <= 1`, interpret `p` as the *p*robability to *p*ick a given record and otherwise toss
it, so that `$sample 1` will keep all records, `$sample 0` will toss all records, and
`$sample 0.5` (the default) will toss (on average) every other record.

You can pipe several `$sample()` calls, reducing the data stream to 50% with each step. If you know
your data set has, say, 1000 records, you can cut down to a random sample of 10 by piping the result of
calling `$sample 1 / 1000 * 10` (or, of course, `$sample 0.01`).

Tests have shown that a data file with 3'722'578 records (which didn't even fit into memory when parsed)
could be perused in a matter of seconds with `$sample 1 / 1e4`, delivering a sample of around 370
records. Because these records are randomly selected and because the process is so immensely sped up, it
becomes possible to develop regular data processing as well as coping strategies for data-overload
symptoms with much more ease as compared to a situation where small but realistic data sets are not
available or have to be produced in an ad-hoc, non-random manner.

**Parsing CSV**: There is a slight complication when your data is in a CSV-like format: in that case,
there is, with `0 < p < 1`, a certain chance that the *first* line of a file is tossed, but some
subsequent lines are kept. If you start to transform the text line into objects with named values later in
the pipe (which makes sense, because you will typically want to thin out largeish streams as early on as
feasible), the first line kept will be mis-interpreted as a header line (which must come first in CSV
files) and cause all subsequent records to become weirdly malformed. To safeguard against this, use
`$sample p, headers: true` (JS: `$sample( p, { headers: true } )`) in your code.

**Predictable Samples**: Sometimes it is important to have randomly selected data where samples are
constant across multiple runs:

+ once you have seen that a certain record appears on the screen log, you are certain it will be in the
  database, so you can write a snippet to check for this specific one;

+ you have implemented a new feature you want to test with an arbitrary subset of your data. You're
  still tweaking some parameters and want to see how those affect output and performance. A random
  sample that is different on each run would be a problem because the number of records and the sheer
  bytecount of the data may differ from run to run, so you wouldn't be sure which effects are due to
  which causes.

To obtain predictable samples, use `$sample p, seed: 1234` (with a non-zero number of your choice);
you will then get the exact same
sample whenever you re-run your piping application with the same stream and the same seed. An interesting
property of the predictable sample is that—everything else being the same—a sample with a smaller `p`
will always be a subset of a sample with a bigger `p` and vice versa.

### @$show
### @$sort

### @$sort = ( sorter, settings ) ->

Uses [github.com/mziccard/node-timsort](https://github.com/mziccard/node-timsort) for an
efficient, and, importantly, stable sort.

### @$split = ( matcher, mapper, settings ) ->

Uses [github.com/mcollina/split2](https://github.com/mcollina/split2) to split
a stream of buffers or texts into lines (in the default setting; for details
see the split2 project page).

### @$split_tsv = ( settings ) ->

A fairly complex stream transform to help in reading files with data in
[Tab-Separated Values (TSV)](http://www.iana.org/assignments/media-types/text/tab-separated-values)
format. It basically accepts a stream of buffers or text, splits it into
lines, and splits each line into fields. In the process it can also skip empty
and blank lines, omit comments, and name fields.


+ `comments` defines how to recognize a comment. If it is a string, lines (or fields, when `first:
  'split'` has been specified) that start with the specified text are left out of the results.
  It is also possible to use a RegEx or a custom function to recognize comments.

+ `trim`: `false` for no trimming, `true` for trimming both ends of each line (with `first: 'trim'`)
  or each field (with `first: 'split'`).

+ `first`: either `'trim'` or `'split'`. No effect with `trim: false`; otherwise, indicates whether
  first the line is trimmed (which means that leading and trailing tabs are also removed), or whether
  we should first split into lines, and then trim each field individually. The `first: 'trim'` method—the
  default—is faster, but it may conflate empty fields if there are any. The `first: 'split'` method
  will first split each line using the `splitter` setting, and then trim all the fields individually.
  This has the side-effect that comments (as field values on their own, not when tacked unto a non-comment
  value) are reliably recognized and sorted out (when `comments` is set to a sensible value).

+ `splitter` defines one or more characters to split each line into fields.

+ When `empty` is set to `false`, empty lines (and lines that contain nothing but empty fields) are
  left in the stream.


### @$spread
### @$stop_time
### @$throttle_bytes
### @$throttle_items

### @end = ( me ) ->

Given a stream, end it.

### @isa_stream
### @new_stream
### @new_stream_from_pipeline
### @new_stream_from_text
### @remit
### @remit_async
### @run

### @send = ( me, data ) ->

Given a stream and some data, send / write / push that data into the stream.


<!-- ####################################################################################### -->


>
# Backmatter
>
## Under the Hood: Base Libraries
>
> **Abstract**: PipeDreams was previously based on
> [github.com/dominictarr/*event-stream*](https://github.com/dominictarr/event-stream)
> and did so largely successfully, but problems with aysnchronous streams did surface in some
> places.
>
> Unfortunately, *event-stream* is pegged to NodeJS streams v1 (as used in
> NodeJS v0.8), but meanwhile we've reached NodeJS streams v3 (as used in NodeJS v5.x)
>
> > For more details, see Dominic Tarr's [rundown of NodeJS Streams
> > History](http://dominictarr.com/post/145135293917/history-of-streams); worthwhile snippet:
>
> > > If node streams teach us anything, it’s that it’s very difficult to develop
> > > something as fundamental as streams inside a “core”[. Y]ou can’t change core
> > > without breaking things, because things simply assume core and never declare
> > > what aspects of core they depend on. Hence a very strong incentive occurs to
> > > simply make core always be backwards compatible, and to focus only on
> > > performance improvements. This is still a pretty good thing, except
> > > sometimes decisions get inadvertently made that have negative implications,
> > > but that isn’t apparent until it’s too late.
>
> > How very true. People should keep this in mind when they berate JavaScript as
> > a 'language with virtual no standard library at all'.
>
>
### Through2
>
> [Through2](https://github.com/rvagg/through2) provides a fairly manageable
> interface to build stream transforms on:
>
> > ```js
> > var through2 = require('through2');
> > var transform = through2([ options, ] [ transformFunction ] [, flushFunction ])
> > ```
>
> > To queue a new chunk, call `this.push(chunk)`—this can be called as many
> > times as required before the `callback()` if you have multiple pieces to
> > send on.
>
> > Alternatively, you may use `callback(err, chunk)` as shorthand for emitting
> > a single chunk or an error.
>
> > The optional `flushFunction` is provided as the last argument (2nd or 3rd,
> > depending on whether you've supplied `options`) is called just prior to the
> > stream ending. Can be used to finish up any processing that may be in
> > progress.
>
> So I wrote this simple 'demo test' (i.e. a tentative implementation as a proof
> of concept) to see whether things work out the way I need them to have. Below
> I will give the (much shorter) PipeDreams version for achieving the same
> result:
>
> ```coffee
> #-----------------------------------------------------------------------------------------------------------
> @[ "(v4) stream / transform construction with through2" ] = ( T, T_done ) ->
>   FS          = require 'fs'
>   PATH        = require 'path'
>   through2    = require 'through2'
>   t2_settings = {}
>   input       = FS.createReadStream PATH.resolve __dirname, '../package.json'
>   #.........................................................................................................
>   ### Set an arbitrary timeout for a function, report it, and execute after a while; used to
>   simulate some kind of asynchronous DB or network retrieval stuff: ###
>   delay = ( name, f ) =>
>     dt = CND.random_integer 1, 1500
>     # dt = 1
>     whisper "delay for #{rpr name}: #{dt}ms"
>     setTimeout f, dt
>   #.........................................................................................................
>   ### The main transform method accepts a line, takes it out of the stream unless it matches
>   either `"name"` or `"version"`, trims it, and emits two events (formatted as lists) per remaining
>   line. This method must be free (a.k.a. bound, using a slim arrow) so we can use `@push`. ###
>   transform_main = ( line, encoding, handler ) ->
>     throw new Error "unknown encoding #{rpr encoding}" unless encoding is 'utf8'
>     return handler() unless ( /"(name|version)"/ ).test line
>     line = line.trim()
>     delay line, =>
>       @push [ 'first-chr', ( Array.from line )[ 0 ], ]
>       handler null, [ 'text', line, ]
>   #.........................................................................................................
>   ### The 'flush' transform is called once, right before the stream has ended; the callback must be called
>   exactly once, and it's possible to put additional 'last-minute' data into the stream by calling `@push`.
>   Because we have to access `this`/`@`, the method must again be free and not bound, but of course we
>   can set up an alias for `@push`: ###
>   transform_flush = ( done ) ->
>     push = @push.bind @
>     delay 'flush', =>
>       push [ 'message', "ok", ]
>       push [ 'message', "we're done", ]
>       done()
>   #.........................................................................................................
>   input
>     .pipe D.$split()
>     .pipe through2.obj t2_settings, transform_main, transform_flush
>     .pipe D.$show()
>     .pipe D.$on_end => T_done()
> ```
>
> I'm using Through2 via the
> [mississippi](https://github.com/maxogden/mississippi) collection, which
> brings a number of up-to-date and (hopefully) mutually compatible stream
> modules together in a neat bundle.
>
>
## What's in a Name?
>
> The name of the *remit* method is probably be best understood as an arbitrary piece
> of terminology. According to the
> [American Heritage Dictionary](https://ahdictionary.com/word/search.html?q=remit&submit.x=0&submit.y=0)
> it means, inter alia, *to refrain from exacting (a tax or penalty, for example); cancel*;
> *to refer (a case) to another court for further consideration or action*; *to refer
> (a matter) to a committee or authority for decision*, and also *to transmit (money in payment)*.
> Somehow PipeDreams' `remit` does a bit of all of these things:
> `remit` itself 'refrains' from doing anything with the business data that we build that
> pipeline of stream transforms for; instead, that data is 'remitted' (re-sent) to the function
> that `remit` accepts as argument. `remit` helps to 'transmit' (not money in payment but
> business data from source to sink). Transform functions built with `remit` are not meant
> to be used—called with business data—directly; rather, like factory functions
> they accept an optional configuration and return another (possibly stateful) function
> to do the transformation work.

