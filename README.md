
**Disclaimer** PipeDreams v4 should be considered alpha-level software—expect bugs and API changes.


# PipeDreams

[![npm version](https://badge.fury.io/js/pipedreams.svg)](https://www.npmjs.com/package/pipedreams)
[![Build Status](https://travis-ci.org/loveencounterflow/pipedreams.svg?branch=master)](https://travis-ci.org/loveencounterflow/pipedreams)
![stability-almost stable](https://img.shields.io/badge/stability-almost%20stable-orange.svg)
![slogan-NodeJS streams made rad easy](https://img.shields.io/badge/slogan-NodeJS%20streams%20made%20rad%20easy-blue.svg)

Install as `npm install --save pipedreams`.

![Der Pfeifenraucher](https://github.com/loveencounterflow/pipedreams/raw/v4/art/Der%20Frosch%20und%20die%20beiden%20Enten_0015.png)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [PipeDreams](#pipedreams)
  - [Require Statement](#require-statement)
  - [Streams are Transforms, Transforms are Streams](#streams-are-transforms-transforms-are-streams)
  - [When to Call it a Day: Always Use $ 'finish'](#when-to-call-it-a-day-always-use--finish)
  - [Never Assume Your Streams to be Synchronous](#never-assume-your-streams-to-be-synchronous)
  - [Stream Creation](#stream-creation)
    - [Stream Creation API](#stream-creation-api)
  - [The Remit and Remit-Async Methods](#the-remit-and-remit-async-methods)
    - [(Synchronous) Stream Observer](#synchronous-stream-observer)
    - [Synchronous Transform, No Stream End Detection](#synchronous-transform-no-stream-end-detection)
    - [Synchronous Transform With Stream End Detection](#synchronous-transform-with-stream-end-detection)
    - [Asynchronous Transforms](#asynchronous-transforms)
    - [One-Off Tramsforms to Run at the Beginning or the Ending of a Stream](#one-off-tramsforms-to-run-at-the-beginning-or-the-ending-of-a-stream)
    - [@$ 'finish', @on_finish = ( stream, handler ) ->](#-finish-on_finish---stream-handler---)
  - [How to Send Null Without Ending the Stream](#how-to-send-null-without-ending-the-stream)
    - [Using Events instead of Data Items](#using-events-instead-of-data-items)
    - [Using a Symbolic Value for Null](#using-a-symbolic-value-for-null)
- [TL;DR: Things to Keep in Mind](#tldr-things-to-keep-in-mind)
  - [Never Assume a Stream to be Synchronous](#never-assume-a-stream-to-be-synchronous)
  - [Always Use $ 'finish' to Detect End of Stream](#always-use--finish-to-detect-end-of-stream)
  - [Never Use Null to Send, Unless You Want the Stream to End](#never-use-null-to-send-unless-you-want-the-stream-to-end)
  - [Don't Use a Pass Thru Stream in Front of a Read Stream](#dont-use-a-pass-thru-stream-in-front-of-a-read-stream)
  - [Always Use an Output and Wait for it](#always-use-an-output-and-wait-for-it)
  - [Beware of Incompatible Libraries](#beware-of-incompatible-libraries)
  - [Handle Errors Asynchronously](#handle-errors-asynchronously)
- [Plugins](#plugins)
  - [PipeDreams Plugin: Tabulate](#pipedreams-plugin-tabulate)
  - [PipeDreams Plugin: TSV](#pipedreams-plugin-tsv)
- [PipeDreams API](#pipedreams-api)
  - [@$](#)
  - [@$as_json_list = ( tags... ) ->](#as_json_list---tags---)
  - [@$as_list = ( names... ) ->](#as_list---names---)
  - [@$as_text = ( stringify ) ->](#as_text---stringify---)
  - [@$async](#async)
  - [@$batch](#batch)
  - [@$benchmark = ( title = null ) ->](#benchmark---title--null---)
  - [@$benchmark.summarize = =>](#benchmarksummarize--)
  - [@$bridge = ( stream ) ->](#bridge---stream---)
  - [@$collect](#collect)
  - [@$count](#count)
  - [@$decode = ( encoding = 'utf-8' ) ->](#decode---encoding--utf-8---)
  - [@$drop](#drop)
  - [@$filter](#filter)
  - [@$intersperse = ( joiners... ) ->](#intersperse---joiners---)
  - [@$join = ( outer_joiner = '\n', inner_joiner = ', ' ) ->](#join---outer_joiner--%5Cn-inner_joiner------)
  - [@$lockstep](#lockstep)
  - [@$parse_csv](#parse_csv)
  - [@$pass](#pass)
  - [@$sample = ( p = 0.5, options ) ->](#sample---p--05-options---)
  - [@$show](#show)
  - [@$select = ( selector, tracks ) ->](#select---selector-tracks---)
  - [@$sort = ( sorter, settings ) ->](#sort---sorter-settings---)
  - [@$split = ( matcher, mapper, settings ) ->](#split---matcher-mapper-settings---)
  - [@$spread](#spread)
  - [@$stop_time](#stop_time)
  - [@$stringify = ( stringify ) ->](#stringify---stringify---)
  - [@tap = ( stream, P..., handler ) ->](#tap---stream-p-handler---)
  - [@$tap = ( stream, settings ) ->](#tap---stream-settings---)
  - [@$throttle_bytes](#throttle_bytes)
  - [@$throttle_items](#throttle_items)
  - [@$transform = ( method ) ->](#transform---method---)
  - [@end = ( me ) ->](#end---me---)
  - [@isa_stream](#isa_stream)
  - [@isa_readable_stream = ( x ) ->](#isa_readable_stream---x---)
  - [@isa_writable_stream = ( x ) ->](#isa_writable_stream---x---)
  - [@isa_duplex_stream = ( x ) ->](#isa_duplex_stream---x---)
  - [@new_stream](#new_stream)
  - [@remit, @$, @remit_async, @$async](#remit--remit_async-async)
  - [@send = ( me, data ) ->](#send---me-data---)
- [ToDo](#todo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

**Caveat** Below examples are all written in CoffeeScript.

# PipeDreams

## Require Statement

The suggested way to `require` the PipeDreams library itself and to factor
out the most important methods for convenience is as follows:

```coffee
D               = require 'pipedreams'
{ $, $async }   = D
```

If you don't like dollar signs in your code or already use `$` for something else, you're of course free to
`D.$` or fall back to the long name, `remit`:

```coffee
D                       = require 'pipedreams'
{ remit, remit_async }  = D
```

In the below, I will assume you `require`d PipeDreams the first way, above.

## Streams are Transforms, Transforms are Streams

**In the PipeDreams world, write streams can appear anywhere in the pipeline, just like read streams; also,
streams and transforms are no different.**

How can read streams, write streams and stream transforms be the same? After all, you'd write your typical
streamy app approximately like this:

```coffee
input   = fs.createReadStream   'foo.txt'
output  = fs.createWriteStream  'bar.txt'
input
  .pipe get_transform_A()
  .pipe get_transform_B()
  .pipe get_transform_C()
  .pipe output
```

In this view, clearly, a read-stream is a source of data—something that pushes data into the stream; a
write-stream is a sink—something that accepts data from the stream; and a transform—well, a transform takes
data, does something with it, and passes it on. In other words, a transform acts like a write-stream on its
'upper' end (), and acts like a read-stream on its lower end.

In the typical NodeJS way of doing things, you can't just go on with the pipeline after a write-stream; this
would be illegal:

```coffee
# won't work
input   = fs.createReadStream 'foo.txt'
input
  .pipe get_transform_A()
  .pipe fs.createWriteStream 'bar.txt'
  .pipe get_transform_B()
```

Trying to read from a NodeJS write-stream will elicit a dry `Cannot pipe. Not readable.` complaint from the
engine. After all, this is a write-stream, right, so what should you want to read from it, right? Wrong!
Consider this simple setup:

```coffee
# won't work
fs.createReadStream 'foo.txt'
  .pipe fs.createWriteStream 'copy-1.txt'
  .pipe fs.createWriteStream 'copy-2.txt'
  .pipe fs.createWriteStream 'copy-3.txt'
```

Isn't it quite obvious that the only sensible course of action here is to A) read from `foo.txt` and B) copy
those bytes to all of `copy-1.txt`, `copy-2.txt`, `copy-3.txt`? Why not? Turns out you can *easily* achieve
the above with PipeDreams:

```coffee
# works!
D = require 'pipedreams'
D.new_stream 'read', file: 'foo.txt'
  .pipe D.new_stream 'write', file: 'copy-1.txt'
  .pipe D.new_stream 'write', file: 'copy-2.txt'
  .pipe D.new_stream 'write', file: 'copy-3.txt'
```

## When to Call it a Day: Always Use $ 'finish'

Given the asynchronous nature of NodeJS' I/O handling, stream end detection can be a fickle thing and hard
to get right. For example, when writing into a file, one might be tempted to wait for an `end` event:

```coffee
### TAINT Counter-example; don't do it this way ###
write_sample = ( handler ) =>
  input     = D.new_stream()
  output    = D.new_stream 'write', 'lines', { file: path_1, }
  pipeline  = input
    .pipe D.$show()
    .pipe output
  #.......................................................................................................
  pipeline.on 'end', handler
  #.......................................................................................................
  D.send input, data for data in [ 'foo', 'bar', 'baz', ]
  D.end input
```

Stress tests have shown this pattern to produce a certain percentage of failures (1 in 10, but that might
depend on details of the writing process).

On the other hand, the pattern below passes tests; here, we use the PipeDreams `$ 'finish'` transform:

```coffee
write_sample = ( handler ) =>
  input   = D.new_stream()
  output  = D.new_stream 'write', 'lines', { file: path_1, }
  input
    .pipe D.$show()
    .pipe output
    .pipe $ 'finish', handler
  #.......................................................................................................
  D.send input, data for data in [ 'foo', 'bar', 'baz', ]
  D.end input
```



## Never Assume Your Streams to be Synchronous

As a general note that users should keep in mind, please observe that no
guarantee is made that any given stream works in a synchronous manner. More
specifically and with regard to the most typical usage pattern: never deal
with pipelined data 'right below' the pipeline definition, always do that
from inside a stream transform.

<strike>Here's an example from `src/tests.coffee`: we create a stream, define a pipeline to split the text into
lines and collect those lines into a list; then, we write a multi-line string to it and end the stream. When
we now look at what's ended up in the collector, we find that the last line is missing. This may come as a
surprise, since nothing in the code suggests that the thing should not work in a simple top-down manner:

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
</strike>

**Update**: The above code is no longer valid and has been removed; however, the following code is
still valid

In order for the code to meet expectations, remember to always grab your results from within a stream
transform; commonly, this is done with `$ 'finish'`:

```coffee
@[ "(v4) new_stream_from_text (2)" ] = ( T, done ) ->
  collector = []
  input     = D.new_stream()
  input
    .pipe D.$split()
    .pipe $ ( line, send, end ) =>
      if line?
        send line
        collector.push line
      if end?
        T.eq collector, [ "first line", "second line", ]
        end()
    .pipe $ 'finish', handler
  input.write "first line\nsecond line"
  input.end()
```

## Stream Creation

PipeDreams simplifies and unifies most common stream creation tasks by providing a (fairly) easy-to-use and
flexible interface via its `new_stream` methods. For the future, it is planned to make that API extensible
with plug-ins.

The simplest possible use is to call `s = D.new_stream()` without any arguments, which will give you a
[through2](https://github.com/rvagg/through2) stream that you can use as source, as sink or as transform.
Here is a very simple example, a function that accepts a callback handler (because all streams are assumed
to be asynchronous); it constructs a strem named `input`, writes two strings to it, and ends it. The
pipeline is set up with three PipeDreams API calls: the first to split (and, actually re-join) the data
events into lines (sans newline characters); the second to print out data events, and the last one to detect
the stream's `finish` event and call the callback:

```coffee
f = ( done ) ->
  input = D.new_stream()
  input
    .pipe D.$split()
    .pipe D.$show()
    .pipe $ 'finish', done
  input.write "helo\nworld"
  input.write "!"
  input.end()
  return null
```

This ultra-simple streaming will do nothing but print out:

```
'helo'
'world!'
```

Throughstreams can appear in any role in a stream pipeline: as sources, throughputs, or sinks of data.
To demonstrate that, let's modify the above a little (`rpr` being a helper derived from `util.inspect`):

```coffee
f = ( done ) ->
  input   = D.new_stream()
  thruput = D.new_stream()
  output  = D.new_stream()
  #.........................................................................................................
  input
    .pipe D.$split()
    .pipe thruput
    .pipe output
    .pipe $ 'finish', done
  #.........................................................................................................
  thruput
    .pipe $ ( data ) -> log 'thruput', rpr data
  #.........................................................................................................
  output
    .pipe $ ( data ) -> log 'output', rpr data
  #.........................................................................................................
  input.write "helo\nworld"
  input.write "!"
  input.end()
  return null
```

The only surprise here is the somewhat weird ordering of what lines this function prints to the console:

```
output 'helo'
thruput 'helo'
output 'world!'
thruput 'world!'
thruput null
output null
```

One might have expected the text from `thruput` to come *before* that from `ouput`, but the general rule is:
**do not rely on a specific ordering of events across different stream transform; only the preservation of
order *within* a given transform is guaranteed**.

### Stream Creation API

`D.new_stream` has a somewhat unusual call signature; its general format is (if you excuse my failed attempt
at writing a sort-of BNF):

```coffee
D.new_stream [ hints... ], [ kind: seed ], [ settings ]
```

All parts are optional. `hints` consists of zero or more 'keywords', 'tags' or 'flags'—single-word strings
that switch various behaviors of the stream on or off. `hints` are followed by an (also optional)
single-element key/value object whose key specifies the `kind` of stream to be built; `settings` is another
object that provides space for more stream-specific settings.

There are currently 6 'kinds' of streams that `new_stream` can return; the simplest one—a featureless
throughstream returned when `new_stream` is called without arguments—we have already encountered.

The most useful ones are `file` and `pipeline` streams. A `file` stream reads from or writes to a file on
disk, and PipeDreams `new_stream` acts as an interface to NodeJS' `fs.createReadStream` and
`fs.createWriteStream`, as the case may be. The minimal file stream is created with a 'kind' of 'file' (or,
equivalently, 'path'—pick one), and a 'seed' that specifies the file's location. Without any hints, you get
a file read stream that emits buffers, so for example

```coffee
input = D.new_stream file: '/tmp/foo.txt'
input.pipe D.$show()
```

might spit out `<Buffer 68 65 6c 6f 20 77 6f 72 6c 64 0a c3 a4 ...>` or something similar (should the file
indeed exists). If you


* `'ascii'`—for 7-bit ASCII data only. This encoding method is very fast and will strip the high bit if set.

* `'utf-8'`, `'utf8'`—Multibyte encoded Unicode characters.

* `'utf16le'`—2 or 4 bytes, little-endian encoded Unicode characters. Surrogate pairs (U+10000 to U+10FFFF)
  are supported.

* `'ucs2'`—Alias of 'utf16le'.

* `'base64'`—Base64 string encoding. When creating a buffer from a string, this encoding will also correctly
  accept "URL and Filename Safe Alphabet" as specified in RFC 4648, Section 5.

* `'binary'`—A way of encoding the buffer into a one-byte (latin-1) encoded string. The string 'latin-1' is
  not supported. Instead, pass 'binary' to use 'latin-1' encoding.

* `'hex'`—Encode each byte as two hexadecimal characters.



```coffee
path = '/tmp/foo.txt'
D.new_stream file: path
D.new_stream 'read', file: path
D.new_stream 'utf-8', { path, }
D.new_stream 'read', 'lines', { path, }
D.new_stream { path, }
```

```coffee
D.new_stream 'write', file: path
D.new_stream 'write', 'lines', { file: '/tmp/foo.txt', }
```

* 'file' / 'path'
* 'pipeline'
* 'text'
* 'url'
* 'transform'
* 'duplex'

```coffee
@new_stream = ( P... ) ->

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

D.new_stream 'devnull'
```


**D.new_stream** **hints**\* { **kind** **:** **locator**, }

Examples:

```coffee
source = D.new_stream()

source = D.new_stream pipeline: [ $square(), ( $multiply 2 ), ]

pipeline  = [ $square(), ( $multiply 2 ), ]
source    = D.new_stream { pipeline, }

path    = '../package.json'
input   = D.new_stream { path, }
output  = D.new_stream 'write', path: '/tmp/foo.txt'

```

Kinds:

```coffee
text
pipeline
file
path
url
```

Hints:

```coffee
'utf-8' / 'utf8'
'binary'
'read'
'write'
'append'
'devnull'
```


## The Remit and Remit-Async Methods

The `remit` method (as well as its asynchronous companion, `remit_async`)  is
very much the centerpiece of the PipeDreams API¹. It accepts a function (call
it a 'transformation') and returns a stream transform. In case you're
familiar with the [event-stream](https://github.com/dominictarr/event-stream)
way of doing things, then PipeDreams' `remit f` is roughly equivalent
to event-stream's  `through on_data, on_end`, except you can handle both the
`on_data` and `on_end` parts in a single function `f`. `remit_async f` is
roughly equivalent to event-stream's `map f`.

**The behavior of a stream transform is governed by the number of arguments of the transformation function
and the optional `'null'` tag**.

You can call `remit` (`$`) with a function that takes one, two, or three arguments, and `remit_async`
(`$async`) with  a function that takes two, or three arguments. The suggested names of the arguments are
`data` (or whatever fits the purpose best) for the first, `send` for the second, and `end` for the third
argument, where present.

You use `send` to send data down the stream; when not present in the signature, the data is sent
for you; where present, you may call it any number of times to send an arbitrary number of items.

Where the `end` parameter is present, you must explicitly call `end()` to end the stream; otherwise, it will
remain open indefinitely. Either `data` or `end`—but not both—will be `null` on any given event. More
precisely, the stream transform will be called once for each upstream data event (if any) with `data != null`,
and then once with `data == null` and `end != null` upon stream end. The pattern to use is always:

```coffee
stream
  .pipe <...>
  .pipe $ ( data, send, end ) =>
    if data?
      <...>
    if end? # you could use a simple `else` here, but explicit is better than implicit
      <...>
      end()
  .pipe <...>
```

Where `end` is **not** given, `data` will **never** be `null`, **except** where the `'null'` tag is used,
as in `$ 'null', ( data ) =>`. Checking `data` for `null` in this kind of transforms allows you to
observe the end-of-stream event without having to bother calling it yourself.

Where `$async` is used, you *may* call `send data` any number of times, but you *must* call `send.done()`
(or `send.done data`) exactly once to signal completion of your asynchronous transform.

In a nutshell, you have the following options:


```
┌─────────────────────────────────────────┬─────────────┬─────────────┬─────────────┐
│  signature                              │ data  may   │ must call   │  must call  │
│                                         │  be null    │   end()     │ send.done() │
├─────────────────────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┐
│  $              ( data            ) ->  │             │             │             │ observers   │
│  $      'null', ( data            ) ->  │      ●      │             │             │             │
├─────────────────────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│  $              ( data, send      ) ->  │             │             │             │             │
│  $      'null', ( data, send      ) ->  │      ●      │             │             │             │
│  $              ( data, send, end ) ->  │      ●      │      ●      │             │ transforms  │
├─────────────────────────────────────────┼─────────────┼─────────────┼─────────────┤             │
│  $async         ( data, send, end ) ->  │      ●      │      ●      │      ●      │             │
└─────────────────────────────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```
<!--
│  $async         ( data, send      ) ->  │             │             │      ●      │
│  $async 'null', ( data, send      ) ->  │      ●      │             │      ●      │
 -->

You can also use `send.end()` to end the stream at any point in time and `send.error new Error "message"` to
signal an error.


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
  .pipe $ 'null', ( data ) ->
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

Since `$show`, below, is such a factory function, the transform that
it returns may hold private state within the closure, an immensely useful
technique:

```coffee
f = ( done ) ->
  $show = ->
    return $ ( data ) ->
      console.log "received data:", data

  $count = ->
    count = 0
    return $ 'null', ( data ) ->
      if data? then count += +1
      else          console.log "stream has ended; read #{count} events"

  input = D.new_stream()
  input
    .pipe D.$split()      # Convert buffer chunks into single-line strings.
    .pipe $show()
    .pipe $count()
    .pipe $ 'finish', done

  D.send input, """
    Here we write
    some lines of text
    into the stream.
    """
  D.end  input # don't forget to end the input stream
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
f = ( done ) ->
  $as_number = ->
    return $ ( data, send ) ->
      send parseFloat data

  $add = ( increment = 1 ) ->
    return $ ( n, send ) ->
      send n
      send n + increment

  $show = ->
    return $ ( data ) ->
      console.log "received data:", data

  input = D.new_stream()
  input
    .pipe D.$split()      # Convert into single-line strings.
    .pipe $as_number()
    .pipe $add 12
    .pipe D.$sort()
    .pipe $show()
    .pipe $ 'finish', done

  D.send input, "20\n10\n50\n40\n30\n"
  D.end  input
```

Output:

```
received data: 10
received data: 20
received data: 22
received data: 30
received data: 32
received data: 40
received data: 42
received data: 50
received data: 52
received data: 62
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

### One-Off Tramsforms to Run at the Beginning or the Ending of a Stream

Often you need to perform some action exactly once when a stream has just
started or just ended. In PipeDreams, this can be done by using one of the tags
`'start'`, `'stop'`, `'first'`, `'last'` or `'finish'` with a remit call.

When you look at the many ways to 'remit with a tag' listed below, you may feel
a little overwhelmed, but the API is in fact fairly straightforward:

* with `'first'` and `'last'`, you listen in for the first or the last data
  event of the stream (if any), respectively.

* when a stream ends before any data item is sent (i.o.w. when you get an empty
  stream), then `'first'` and `'last'` transforms are *only* called (with `null`
  for the `data` argument) when the `'null'` tag is present; when no `'null'`
  tag has been given, `data` will never be `null` or `undefined`.

* with `'start'` and `'stop'`, you listen in for the start and the stop of the
  stream; a transform with `'start'` will be called right *before* the first
  data event comes down the stream, and a transform with `'stop'` will be called
  right *after* the last data event has come down the stream. Both transforms
  will be called once in any event, even when the stream happens to be empty.

* `$ 'finish', ->` is much like `$ 'stop', ( send ) ->`, except that `$
  'finish', ->` is called *after* the stream has finished (at which time all
  participating transforms / streams in the pipeline should be positively done).
  Naturally, sending data into the stream makes no sense at that point in time,
  so a `'finish'` transform must not accept any arguments.

* Observe that the `'null'` tag can only be used with `'first'` and `'last'`;
  since `'start'`, `'stop'` and `'finish'` transforms do never receive data
  events, using `'null'` makes no sense there.

Call signatures:

* `$ 'first',         ( data, send ) -> ...`
* `$ 'first', 'null', ( data, send ) -> ...`
* `$ 'last',          ( data, send ) -> ...`
* `$ 'last',  'null', ( data, send ) -> ...`
* `$ 'start',         (       send ) -> ...`
* `$ 'stop',          (       send ) -> ...`
* `$ 'finish',                       -> ...`

These methods are great to sneak in additional data right in front or right behind the first or last events.
The `null` tag signals that whatever you have to add to the stream should be there in any event; as an
example, imagine you want to build a JSON serialization of a list of items. In that case, you'd sneak in a
left square bracket `[` *before* the first and a right square bracket `]` *after* the last list element, and
in case no elements are passed through the stream at all, you still want the serialization to contain both
brackets to obtain `[]`, so clearly you'd go with the `'null'` tag in this case.



### @$ 'finish', @on_finish = ( stream, handler ) ->

The recommended way to detect write completion in a piped stream is to tack a `.pipe $ 'finish', handler`
transform unto the end of your pipeline:

```coffee
f = ( handler ) ->
  ...
  input
    .pipe $do_this()
    .pipe $do_that()
    .pipe output
    .pipe $ 'finish', handler
```

Alternatively, if you have an explicit ouput stream (say, `output`) in your
pipeline, you can also call `D.on_finish output, handler`. Terminating stream
processing from handlers for other events (e.g. `'end'`) and/or of other parts
of the pipeline may lead to hard-to-find bugs. Observe that `on_finish` and
`$ 'finish'` call `handler` only upon the following turn of the JavaScript event
loop.

**Note** You should **not** attach anything in the pipeline after a
`$ 'finish'` transform, since the behavior of such a transform is not well
defined. When the `finish` event is fired, then all the stream components have
already packed their bags and are ready to return home. The very moment that
`handler` is called, the show is over, and the last batch of events may or may
not make it to any given transform below `$ 'finish'`.

## How to Send Null Without Ending the Stream

Had NodeJS streams be conceived at a point in time where JavaScript had already had
[Symbols](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Symbol), and if the
more modern, broader view of 'streams of anything' (as opposed to the more narrow view that 'all streams are
bytestreams'), chances are that using `send null` from within a stream transform would be just like sending
any other value, and something like `send Symbol.for 'end'` would've been used to signal the stream's end.

But this is not how it happened; streams were conceived as a bytes-only thing, and JavaScript had no symbols
at the time streams were added to NodeJS. As a result, some value other than a buffer had to be used, and
the most natural choice was `null`—after all, `null` represents 'no value', and when you send data, you will
never want to 'send no value' when you can instead 'not send a value', right? Turns out that's wrong.
`null`s are everywhere, like it or not: they appear in databases; they are a legal JSON value (I'd even
claim: the root value of JSON); they appear in configuration files—`null`s are everybody's favorite
Nothing-Be-Here placeholders.

Let's say you have a stream of values that you want to construct a JSON file from (demo code;
consider to use `$as_json_list` and/or `$intersperse` instead):

```coffee
f = ( path, handler ) ->
  source  = D.new_stream()
  output  = D.new_stream 'write', { path, }
  source
    .pipe $ ( data, send ) => send ( JSON.stringify data ); send ','
    .pipe D.$on_start ( send ) => send '['
    .pipe D.$on_last ( data, send ) => send ']\n'
    .pipe output
    .pipe $ 'finish', handler
  #.........................................................................................................
  D.send  source, 42
  D.send  source, 'a string'
  # D.send  source, null # uncomment to test
  D.send  source, false
  D.end   source
```

calling `f` will duly print `[42,"a string",false]` into the file specified. However, trying the same after
uncommenting the line that sends `null` into the stream will break with `stream.push() after EOF`; this is
because sending `null` causes the stream to close down. Don't do that unless you want to end the stream.

There are two ways to tunnel `null` values through stream pipelines: One is to move on from simple data
items to events; the other, to use a symbolic value in place of `null` data.

> Yet another conceivable solution lies in rewriting a number of PipeDreams methods so they write a special
> value whenever they see `null`, and send `null` whenever they see the special value for the 'end stream'
> signal. At the time of this writing, I believe it's better to stick to established conventions; after all,
> PipeDreams mission is to lower the threshold, avoid surprises, and level the learning curve.

### Using Events instead of Data Items

In my experience, writing 'something streamy' to process whatever data often
starts out as an idea how to `send transform_this data`, then `send
transform_that data`—as a sketch where those stream transforms all receive bits
of raw business source data in a piecemeal fashion, and emit bits of business
data in the targetted format. Quite often the result will look like the last
code snippet, above: lots of simple, unnamed stream transforms whose definitions
are put right in the middle of the pipeline.

There's nothing wrong with that approach, and the simplicity of it sure helps to
get started. On the downside, sending raw business data doesn't scale very far;
it tends to break down the very moment you realize that at some point in your
stream you want to communicate facts that are not part of the business data
itself, but belong to a meta level. It is then that moving from 'data items' to
'events' is appropriate.

'Using events' just means wrapping each piece of data into a container object. JavaScript's simplest
container is the list (a.k.a. the Array type), so one way of wrapping data is to always send pairs
`[ event_name, event_value, ]`. Here's what a rewritten stream transform might look like:

```coffee
f = ( path, handler ) ->
  #.......................................................................................................
  $serialize = =>
    return $ ( event, send ) =>
      [ kind, value, ] = event
      return send event unless kind is 'data'
      send [ 'json', ( JSON.stringify value ), ]
  #.......................................................................................................
  $insert_delimiters = =>
    return $ ( event, send ) =>
      [ kind, value, ] = event
      send event
      return unless kind is 'json'
      send [ 'command', 'delimiter', ]
  #.......................................................................................................
  $start_list = => D.$on_start (        send ) => send [ 'command', 'start-list', ]
  $stop_list  = => D.$on_last  ( event, send ) => send [ 'command', 'stop-list',  ]
  #.......................................................................................................
  $as_text = =>
    return $ ( event, send ) =>
      [ kind, value, ] = event
      return send value     if kind is 'json'
      return send event unless kind is 'command'
      ### Here I take the liberty to insert newlines so as to render multi-line JSON: ###
      switch command = value
        when 'delimiter' then send ',\n'
        when 'start-list' then send '[\n'
        when 'stop-list'  then send '\n]\n'
        else send.error new Error "unknown command #{rpr command}"
      return null
  #.......................................................................................................
  source  = D.new_stream()
  output  = D.new_stream 'write', { path, }
  source
    .pipe $serialize()
    .pipe $insert_delimiters()
    .pipe $start_list()
    .pipe $stop_list()
    .pipe $as_text()
    .pipe output
    .pipe $ 'finish', handler
  #.........................................................................................................
  D.send  source, [ 'data', 42,         ]
  D.send  source, [ 'data', 'a string', ]
  D.send  source, [ 'data', null,       ]
  D.send  source, [ 'data', false,      ]
  D.end   source
#.........................................................................................................
f '/tmp/foo.json', ( error ) =>
  throw error if error?
  done()
#.........................................................................................................
return null
```

This is, admittedly, a lot of code for such a simple task; however, when applications get more complex, it
often pays to deal with slightly more abstracted objects that carry richer semantics. Depending on
circumstances, one might opt for `{ named: 'values', }` instead of modelling events as `[ 'tuples', ]`, as
PODs afford more code self-documentation and extensibility. But even within the limits of this small
example, the added complexity of the event-based approach does have some justification: nowhere in the code
did we have to pay attention whether or not some piece of data is or is not `null`—wrapping *all* the data
freed us from having to treat this special value in any special ways (we traded that with the obligation to
deal with different kinds of events, to be sure).


### Using a Symbolic Value for Null

If you don't want to wrap your data into event objects, an easy way to tunnel `null`s through a pipeline
is to replace it with some other value. If you know all your business data consists of wither chunks of text
or `null`s, you can any time just send a `0` (number zero) and still keep the distinction clear. Keeping
things *that* simple, however, quickly breaks down as soon as the first user of your code does send series
of numbers into the stream.

A much more robust solution is offered by JavaScript symbols. Symbols are a new primitive data type in JS;
they have been specifically designed to be used everywhere where single values are needed that do not
conflict with existing values or APIs. They come in two flavors: private and global.

A private symbol is created as `d = Symbol 'xy'`, where `'xy'` is a text of your own choosing; it is just
used to identify the symbol, to give it some human-readable semantics. Each private symbol has its own
identity, even when the same string is used for its creation, so `( Symbol 'A' ) != ( Symbol 'A' )` always
holds. This makes private symbols great for lots of uses where a value of distinct identity—a singleton—is
needed, a value that can not (or, depending on use, is pretty hard to) be reproduced from any part of code
outside the very place where the original was instantiated.

On the other hand, a global symbol is created as `d = Symbol.for 'xy'`; the difference to private symbols is
in the availability, as it were, of the corresponding value. For all code running within the same code
context (i.e. normally the same process), `( Symbol a ) == ( Symbol b )` holds exactly when `a === b` (and
both values are strings).

In other words, a stream transform that wants to check for the occurrence of a *global* symbol for a given
string `'foo'` can just compare stream data items by saying `if data is Symbol.for 'foo'`. If it wants to
check for a *private* symbol `'foo'`, on the other hand, it **must** have access to some property of some
object that holds a reference to that symbol.

In an effort to establish standard procedures to make dealing with `null` data items easier, the PipeDreams
library provides a reference the *global* symbol for the string `'null'` as `D.NULL = Symbol.for 'null'`;
therefore, stream transforms are free to check for either `if data is D.NULL` or `if data is Symbol.for
'null'` with no difference in semantics whatsoever. The beauty of this approach: no 'ordinary / business
data type' is used, but a 'meta data type' (so chances of accidental collisions are minimized), and that
client code can insert and check for 'meta `null`s' without having to specifically reference `D.NULL`.
What's more, patterns like

```coffee
if data is Symbol.for 'null' then send "found a null!"
```

are not only memorable to the writer, they're about as readable as programming languages can get.

Let's have a look at how to use the `null` symbol:

```coffee
f = ( path, handler ) ->
  source  = D.new_stream()
  output  = D.new_stream 'write', { path, }
  source
    .pipe $ ( data, send ) => if data is Symbol.for 'null' then send 'null' else send JSON.stringify data
    .pipe $ ( data, send ) => send data; send ','
    .pipe D.$on_start (       send ) => send '['
    .pipe D.$on_last  ( data, send ) => send ']\n'
    .pipe output
    .pipe $ 'finish', handler
  #.........................................................................................................
  data_items = [ 42, 'a string', null, false, ]
  for data in data_items
    D.send source, if data is null then Symbol.for 'null' else data
  D.end source
```


<!-- ####################################################################################### -->

# TL;DR: Things to Keep in Mind

## Never Assume a Stream to be Synchronous

## Always Use $ 'finish' to Detect End of Stream

## Never Use Null to Send, Unless You Want the Stream to End


## Don't Use a Pass Thru Stream in Front of a Read Stream

Here's a Minimal Working Example, using PipeDreams' underlying
[mississippi](https://github.com/maxogden/mississippi) library (assuming its methods are well-tested and
reasonably bug-free); our only mistake is that the pipeline has a pass-thru stream *in front of* a
file read stream:

```coffee
#-----------------------------------------------------------------------------------------------------------
f = ( handler ) ->
  MSP   = require 'mississippi'
  pipeline = [
    ( MSP.through.obj() )
    ( ( require 'fs' ).createReadStream 'foo.txt', encoding: 'utf-8' )
    ]
  input = MSP.pipeline.obj pipeline...
  input
    .pipe D.$show()
  MSP.finished input, ( error ) =>
    return handler error if error
    handler()
  return null
```

Now it would be great if this code failed on pipeline construction time, preferrably with a sane error
message and a helpful pointer into our code. It does not do that; instead, it fails with an obscure message
and irrelevant (to the developper) pointers, to wit:

```
Error: premature close
    at onclose (.../pipedreams/node_modules/end-of-stream/index.js:44:54)
    at emitNone (events.js:85:20)
    at emit (events.js:179:7)
    at Duplexify._destroy (.../pipedreams/node_modules/duplexify/index.js:191:8)
    at .../pipedreams/node_modules/duplexify/index.js:174:10
    at _combinedTickCallback (node.js:370:9)
    at process._tickDomainCallback (node.js:425:11)
```

## Always Use an Output and Wait for it

## Beware of Incompatible Libraries

When re-writing the algorithms of PipeDreams for version&nbsp;4, I wanted not only to weed out some odd bugs
that appeared in strange corner cases, I also wanted to make sure that PipeDreams does not inadvertently
cause some streams to fall back into pre-Streams-v3 mode. Consequently, I had to say good-bye to e.g.
[github.com/dominictarr/event-stream](https://github.com/dominictarr/event-stream) and
[github.com/dominictarr/split](https://github.com/dominictarr/split), both of which had served their purpose
very well so far, but were no more up-to-date with the developement of NodeJS streams.

Happy at first was I when finding [github.com/mcollina/split2](https://github.com/mcollina/split2), a
library that says it "is inspired by @dominictarr split module, and it is totally API compatible with it";
further, it promises to be "based on through2 by @rvagg and [to be] fully based on Stream3". That's great!
Just swap the one for the other, done!

Sadly, that didn't work out. I'm not claiming split2 has bugs, all I can say is that it did not reliably
work within PipeDreams pipelines; the issue seems to be with stream end detection. Maybe there's something
wrong with some PipeDreams method; I just don't know. All I do know is that
[github.com/maxogden/binary-split](https://github.com/maxogden/binary-split) does work for me as advertised.

I think the takeaway here is that **NodeJS streams are pretty complex beasts**. I realize that I've put a
lot of work into understanding streams and how to use them right, and I still do think that it's a
worthwhile effort. But in all that complexity, there's always a chance that one party gets it flat wrong, or
has made some as-such-valid, but nevertheless conflicting design decisions—a fault may occur in the
PipeDreams code, in the client code (i.e. Your Code), or in some 3rd party module.

**When faced with some fault, try to write a minimal test case (also known as Minimal Working Example
(MWE))** and cleanly delineate (for example, by switching parts of the code on and off and re-running the
test) exactly where and under what conditions the test works and where and when it fails.

## Handle Errors Asynchronously

Error handling in NodeJS (and, generally, in any JavaScript VM) can be a bitch. Be it said that this
part of the language could be and should be vastly improved. For the time being, consider to use
`CND.run`.

**NOTE that running production code with `CND.run` is not recommended as it does come with a hefty
performance penalty.**


```sh
npm install --save cnd
```

To run a method, catch all the synchronous and asynchronous errors and print a stacktrace
to `process.stderr` (using `console.error`):

```coffee
CND = require `cnd`
CND.run -> f 42
```

Same as the above, but do the error handling yourself:

```coffee
CND.run ( -> f 42 ), ( error ) -> foobar()
```

Same as the last, except have CND output the error's stacktrace and be called back afterwards:

```coffee
CND.run ( -> f 42 ), null, ( error ) -> foobar()
```

NB.: `CND.run` may be made configurable in the future; as of now, it is hardwired to use colors
and always provide long (cross-event) stack traces. Colors used are blue for NodeJS VM built-ins,
green for errors originating from modules installed under `node_modules`, and yellow for everything
else.



# Plugins

## PipeDreams Plugin: Tabulate

See the [Plugin Tabulate Readme](./README-plugin-tabulate.md).

## PipeDreams Plugin: TSV

See the [Plugin TSV Readme](./README-plugin-tsv.md).


# PipeDreams API

> **Note** In the below, headings show the exact signature of each method as
> defined in the source. `@` is CoffeeScript's symbol for JavaScript's
> `this`—replace it with whatever your favorite import symbol for the PipeDreams
> library may be. In the explanatory texts, that is `D` as in the rest of this
> document.

## @$

## @$as_json_list = ( tags... ) ->

Turn a stream of data into a JSON list. The source of `$as_json_list` demonstrates
the usefulness of transform combinations:

```coffee
@$as_json_list = ( tags... ) ->
  if ( pretty = 'pretty' in tags ) and ( arity = tags.length ) > 1
    throw new Error "expected at most single tag 'pretty', go #{rpr tags}"
  if pretty then  intersperse = @$intersperse '[\n  ', ',\n  ', '\n  ]\n'
  else            intersperse = @$intersperse '[', ',', ']'
  return @new_stream pipeline: [
    ( @$stringify()   )
    ( intersperse     )
    ( @$join ''       ) ]
```

`$as_json_list` accepts a single argument; when present, that must be the string `'pretty'` to turn the
result from a one-liner (for small amounts of data) to a one-record-per-line JSON representation.
'Pretty-printed' JSON files are great because they lend themselves both to be edited in your favorite text
editor and to be efficiently processed in a linewise fashion.

## @$as_list = ( names... ) ->
Turn named attributes into list of values.


## @$as_text = ( stringify ) ->
Turn all data items into texts using `JSON.stringify` or a custom stringifier. `null` and any strings
in the data stream is passed through unaffected. Observe that buffers in the stream will very probably not
come out the way you'd expect them; this is because there's no way to know for the method what kind of
data they represent.

This method is handy to put as a safeguard right in front of a `.pipe output_file` clause to avoid
`illegal non-buffer` issues.

## @$async
## @$batch

## @$benchmark = ( title = null ) ->

(see tests)

## @$benchmark.summarize = =>

(see tests)

## @$bridge = ( stream ) ->

Make it so that the pipeline may be continued even below a writable but not
readable stream. Conceivably, this method could have be named `tunnel` as
well. Something to get you across, you get the meaning. Useful for NodeJS
writable streams which do not normally allow you to pipe something out of—in
other words, when you pipe something into, say, `fs.createWriteStream
'/tmp/foo.txt'`, you can't take that stream and pipe it somewhere else. This
won't work:

```coffee
input
  .pipe ( require 'fs' ).createWriteStream 'foo.txt'
  .pipe ( require 'fs' ).createWriteStream 'bar.txt'
```

... but this works ...

```coffee
input
  .pipe D.$bridge ( require 'fs' ).createWriteStream 'foo.txt'
  .pipe D.$bridge ( require 'fs' ).createWriteStream 'bar.txt'
```

... and this will work, too; all PipeDreams streams allow being piped from:

```coffee
input
  .pipe D.new_stream 'write', path: 'foo.txt'
  .pipe D.new_stream 'write', path: 'bar.txt'
```

## @$collect
## @$count
## @$decode = ( encoding = 'utf-8' ) ->
## @$drop
## @$filter

<!-- ## @$finish = ->

Used at the end of a pipeline to make sure data is correctly streamed till the very last item. Onle needed in some cases.
 -->

## @$intersperse = ( joiners... ) ->

Similar to `$join`, `$intersperse` allows to put extra data in between each pair of original data; in
contradistinction to `$join`, however, `$intersperse` does not stringify any data, but keeps the insertions
as separate events.

`$intersperse` expects between one and three argument, each one of which may be a function or an arbitrary
piece of data. If it receives a single argument, that value will be used as a 'mid joiner', i.e. it will be
emitted in between any two events in the stream.

If `$intersperse` is called with two arguments, it will insert the value of the first argument before the
first and after the last event in the stream. If called with three, the first argument goes to the
beginning, the second to all the in-betweens, and the last to the end of the stream. In case one of the
joiners is `null`, it will not be applied, and the same goes for joiners that are functions: if a
joiner function returns `null`, no extra data item will be sent.

This simple test case provides an overview:

```coffee
demo = ( x..., handler ) =>
  input = D.new_stream()
  input
    .pipe D.$intersperse x...
    .pipe D.$collect()
    .pipe $ ( data ) ->
      if data?
        help x, data.join ''
    .pipe $ 'finish', handler
  D.send input, 'a'
  D.send input, 'b'
  D.send input, 'c'
  D.end input
```

Here's a rundown of what resulta to expect with which kinds of signatures; it's probably best to stick to
the starred call patterns for clarity:

```coffee
### 1 way to call with 0 arguments ###
D.$intersperse()                   # 'abc'      — No-Op
#.......................................................................................................
### 2 ways to call with 1 arguments ###
D.$intersperse null                # 'abc'      — No-Op
D.$intersperse '—'                 # 'a—b—c'    — mid                   *
#.......................................................................................................
### 4 ways to call with 2 arguments ###
D.$intersperse null,  null         # 'abc'      — No-Op
D.$intersperse null,  '—'          # 'a—b—c'    — mid
D.$intersperse '{',   null         # '{abc{'    — start == stop
D.$intersperse '{',   '—'          # '{a—b—c{'  — mid, start == stop
#.......................................................................................................
### 8 ways to call with 3 arguments ###
D.$intersperse null,  null, null   # 'abc'      — No-Op
D.$intersperse null,  null, '}'    # 'abc}'     — stop                  *
D.$intersperse null,  '—',  null   # 'a—b—c'    — mid
D.$intersperse null,  '—',  '}'    # 'a—b—c}'   — mid, stop             *
D.$intersperse '{',   null, null   # '{abc'     — start                 *
D.$intersperse '{',   null, '}'    # '{abc}'    — start, stop           *
D.$intersperse '{',   '—',  null   # '{a—b—c'   — start, mid            *
D.$intersperse '{',   '—',  '}'    # '{a—b—c}'  — start, mid, stop      *
```

## @$join = ( outer_joiner = '\n', inner_joiner = ', ' ) ->

Join all strings and lists in the stream. `$join` accepts two arguments, an `outer_joiner` and an
`inner_joiner`. Joining works in three steps: First, all list encountered in the stream are joined using
the `inner_joiner`, turning each list into a string as a matter of course. In the second step, the entire
stream data is collected into a list (using PipeDreams `$collect`). In the last step, that collection is
turned into a single string by joining them with the `outer_joiner`. The `outer_joiner` defaults to a
newline, the `inner_joiner` to a comma and a space.

## @$lockstep



## @$parse_csv
## @$pass

## @$sample = ( p = 0.5, options ) ->

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

## @$show

## @$select = ( selector, tracks ) ->

Sometimes it is convenient to split up stream processing depending on the 'kind' of data item at hand. For
example, imagine you do a typesetting job where each bit coming down the line is either a typesetting
command or else a bit of text; imagine you're doing multilingual typesetting in English and Arabic or
Chinese and it's easy to see that the processing pipeline could at some point be split up like this:

```
                               │
                        ┌──────▼──────┐
                        │  all events │
                        └──────┬──────┘
                               ▼
                        ┌─────────────┐
                        │   $select   │
                        └────▼───▼────┘
       ┌─────────────────────┘   └─────┐
       ▼                               ▼
┌─────────────┐                 ┌─────────────┐
│  commands   │                 │ text events │
└──────┬──────┘                 └──────┬──────┘
       │                               ▼
       │                        ┌─────────────┐
       │                        │   $select   │
       │                        └────▼─▼─▼────┘
       │                             │ │ │
       │               ┌─────────────┘ │ └─────────────┐
       │               ▼               ▼               ▼
       │        ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
       │        │   English   │ │   Arabic    │ │   Chinese   │
       │        └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               └─────────────┐ │ ┌─────────────┘
       │                             ▼ ▼ ▼
       │                        ┌─────────────┐
       │                        │ text events │
       │                        └──────┬──────┘
       └─────────────────────┐   ┌─────┘
                             ▼   ▼
                        ┌─────────────┐
                        │  all events │
                        └──────┬──────┘
                               ▼
```

This way, we can have a 'branch' or 'track' of the pipeline that deals exclusively with commands, and
another one that deals exclusively with text events; the latter could at some point again be split up to do
some kind of text processing that only applies to a certain language or certain script.

The ususal alternative to splitting the processing into tracks is to maintain a single chain of stream
transforms. This has two disadvantages: for one thing, there will be a lot of code duplication because
almost all transforms will need some kind of almost-identical `if` statement near the top to decide which
events to deal with. On the other hand, transforms loose part of their 'innocence': a transform that, at its
heart, only wants to deal with some text snippet has, all of a sudden, been requisitioned to dabble in event
sieving as well.

Below we demonstrate a rather simpler example than the one outlined above. In that example, there are three
'translator' stream transforms that turn incoming numbers into the corresponding English, French, and German
words. Further, there's a transform that draws a separator line. These four functions are registered in the
`tracks` object. Also, there's a `dispatch` function that accepts a piece of `data` and returns an
object to indicate where to direct the incoming data.

In general, the `dispatch` function should return a plain old dictionary (POD) with the obligatory element
`key` (to select the target stream) and the facultative element `data` (to replace the data originally
passed into `$select`). The `key` element may be

* `Symbol.for 'pass'` to make `$select` pass the data through without submitting it to any kind of
  processing;
* `Symbol.for 'drop` to make `$select` drop the data;
* a stream or transform to send the value to;
* a valid key of the object or list passed as second argument to `select`;
* or a list of zero or more of any of the above to send `data` to any number of destinations.


```coffee
#------------------------------------------------------------------------------
say_it_in_english = $ ( n, send ) ->
  if n?
    switch n
      when 1 then send 'one'
      when 2 then send 'two'
      when 3 then send 'three'
      else send 'many'
  return null

#------------------------------------------------------------------------------
say_it_in_french = $ ( n, send ) ->
  switch n
    when 1 then send 'un'
    when 2 then send 'deux'
    when 3 then send 'troix'
    else send 'beaucoup'
  return null

#------------------------------------------------------------------------------
say_it_in_german = $ ( n, send ) ->
  switch n
    when 1 then send 'eins'
    when 2 then send 'zwei'
    when 3 then send 'drei'
    else send 'viele'
  return null

#------------------------------------------------------------------------------
draw_a_separator = $ ( ignore, send ) ->
  send '—————'
  return null

#------------------------------------------------------------------------------
dispatch = ( data ) ->
  return key: Symbol.for 'drop'  if data is 'drop this one'
  return key: Symbol.for 'pass'  if data is 'pass this one'
  return key: 'SEP'              if data is '---'
  [ languages, number, ] = data
  if languages is '*'   then languages = [ 'EN', 'FR', 'DE', ]
  else                       languages = ( language.toUpperCase() for language in languages.split ',' )
  return key: languages, data: number

#------------------------------------------------------------------------------
tracks =
  EN:   say_it_in_english
  FR:   say_it_in_french
  DE:   say_it_in_german
  SEP:  draw_a_separator

#------------------------------------------------------------------------------
probes = [
  [ 'fr', 1, ]
  [ 'fr', 2, ]
  [ 'fr', 3, ]
  [ 'fr', 4, ]
  'pass this one'
  '---'
  [ 'en,fr',  1, ]
  '---'
  'drop this one'
  [ '*',  1, ]
  '---'
  [ 'en', 2, ]
  '---'
  [ 'de', 3, ]
  [ 'de', 4, ]
  ]

#------------------------------------------------------------------------------
matchers = [
  "un"
  "deux"
  "troix"
  "beaucoup"
  "pass this one"
  "—————"
  "one"
  "un"
  "—————"
  "one"
  "un"
  "eins"
  "—————"
  "two"
  "—————"
  "drei"
  "viele"
  ]

#------------------------------------------------------------------------------
my_input = D.new_stream()
my_input
  .pipe D.$select dispatch, tracks
  .pipe D.$collect()
  .pipe $ ( results ) =>
    T.eq results.length, matchers.length
    T.eq results[ idx ], matcher for matcher, idx in matchers
  .pipe $ 'finish', done
#..............................................................................
D.send  my_input, probe for probe in probes
D.end   my_input
```

We send in data events that take on the form of a list as in `[ language, number, ]`, or a string that
indicates a `'special value'`. One of the special values is dropped, another one passed through (to remain
as-is), and yet another one is turned into a separator line. The remaining events indicate one or more
specific language or have an asterisk to symbolize 'all languages'; in these cases, the dispatcher turns the
language indicator into a valid target stream key and isolates the number from the data event, since the
transforms accept only a number, not a `[ language, number, ]` pair.

In the source file with the test cases, you will find a test case named `"(v4) $select (2)"`; it
demonstrates an interesting techniques to deal with multiple, stacked `$select` transforms: here, we define
a pass-through stream named `bridgehead` that serves as a mid-way entry point into the stream. We can then
direct select events to that bridgehead entry point to bypass certain stream transforms. An excerpt:

```coffee
bridgehead  = D.$pass()

dispatch_drop_and_pass_events = ( event ) ->
  return key: σ_drop     if event is 'drop this one'
  return key: bridgehead if event is 'dont process this one'
  return key: σ_pass

my_input    = D.new_stream()
my_input
  .pipe D.$select dispatch_drop_and_pass_events
  .pipe D.$select dispatch_draw_line_events,    draw_line_track
  .pipe D.$select dispatch_language_events,     language_track
  .pipe bridgehead
```

## @$sort = ( sorter, settings ) ->

Uses [github.com/mziccard/node-timsort](https://github.com/mziccard/node-timsort) for an
efficient, and, importantly, stable sort.

## @$split = ( matcher, mapper, settings ) ->

Uses [github.com/maxogden/binary-split](https://github.com/maxogden/binary-split) to split
a stream of buffers or texts into lines (in the default setting; for details
see the binary-split project page).

## @$spread
## @$stop_time

## @$stringify = ( stringify ) ->

Turns all data events into their respective JSON representations. The method
recognizes JS `Symbol`s and turns them into plain old dictionaries (a.k.a. JS
objects or 'PODs'); when sending `Symbol.for 'abc'`, this will result in the
string `{"~isa":"symbol","value":"abc"}`. Only `Symbol.for null` is special—it
will be turned into the string `null`, so you can sort-of have `null`s in your
datra stream (at least as far as JSON output is concerned).

If `stringify` is given, `D.$stringify f` is little more that `D.$transform f`, except the
return value is type-checked to be either `null` or a text.

## @tap = ( stream, P..., handler ) ->

PipeDreams `tap` is a convenience method that transforms a stream into an asynchronous value using
`$collect`, optionally thinned out to a few samples using `$sample`. Its implementation is quite
straightforward and may be used *in lieu* for documentation:

```coffee
@tap = ( stream, P..., handler ) ->
  pipeline = []
  pipeline.push stream
  pipeline.push @$sample P... if P.length > 0
  pipeline.push @$collect()
  pipeline.push @$ ( collector ) => handler null, collector
  return @_rpr "tap", "tap", null, @new_stream { pipeline, }
```

`tap` is a great tool to retrieve partial file contents, especially to obtain a random, but possibly (if
argument `seed` is used) deterministic, sample of lines from a text file. This will give you every fifth
line on average from the file identified by `path`; since `seed` is used, the lines will be the same lines
every time you run the code. Omit `seed` to obtain a (probably) different sample each time:

```coffee
file_reader = D.new_stream 'lines', { path, }
D.tap file_reader, 1 / 5, seed: 123, ( error, lines ) -> ...
```

## @$tap = ( stream, settings ) ->

Echo all events from the main stream (so to speak) into the bystream (as it were); this allows e.g. to go
on reading after a writestream, and / or turn arbitrary data events into text events that are written to a
file in the bystream while they remain unchanged in the main stream for further processing.

Note that by default, the bystream will be sent the exact same event objects as the mainstream. As long as
data events are JS primitive values (numbers, strings, `true`, `false`), that's at any rate OK. However,
lists (arrays) and general objects as well as their non-primitive elements and properties just *might* get
modified along the chain of pipelined transformations, and this can lead to hard-to-understand bugs in case
you, say, delete an item from a list in the one stream that you then inadvertently miss in the other
(seemingly unrelated) stream.

Remember, all streams should always be considered asynchronous, so in all but the simplest of cases you
should never assume knowledge about a definitve ordering. In other words, you cannot say for certain at
which point in time a given transform in the bystream will be called with respect to some other transform in
the mainstream, so its better to always program defensively.

To prevent such errors, PipeDreams `$tap` can be instructed to make a new copy of each data event (produced
with [CND.deep_copy](https://github.com/loveencounterflow/cnd)) by setting the `copy` member of the
`settings` argument to `true`:

```coffee
input
  .pipe ...
  .pipe D.$tap bystream, { copy: yes, }
  .pipe ...
```

Sometimes a shallow copy is sufficient and a deep copy is too costly; in these cases, pass in your custom
copying function, e.g. using `Object.assign` (which is fast, reliable and easy to use):

```coffee
input
  .pipe ...
  .pipe D.$tap bystream, { copy: ( data ) ->  return Object.assign [], data }
  .pipe ...
```

In the future, PipeDreams `$tap` may support symbolic values like `'deep'` and `'shallow'`; for the sake of
clarity, you can make the default explicit with `copy: false` or `copy: null`.

Conceptually, a `$tap`ped bystream 'taps' into the mainstream and produces a secondary pipeline, potentially
one with its own set of processing steps and its own targets. And, of course, nothing keeps you from tapping
into that secondary stream and so on:

```
                        ┌─────────────┐
                        │    input    │
                        └──────┬──────┘
                               │
                               ▼
                        ┌─────────────┐
                        │     $tap    │
                        └──────┬────┬─┘
                               │    └───────────────┐
                               ▼                    ▼
                        ┌─────────────┐      ┌─────────────┐
                        │  mainstream │      │   bystream  │
                        │  processing │      │  processing │
                        └──────┬──────┘      └──────┬──────┘
                               │                    ▼
                               │             ┌─────────────┐
                        ┌─────────────┐      │ write to B  │
                        │     $tap    │      └─────────────┘
                        └──────┬────┬─┘
                               │    └───────────────┐
                               ▼                    ▼
                        ┌─────────────┐      ┌─────────────┐
                        │  mainstream │      │   bystream  │
                        │  processing │      │  processing │
                        └──────┬──────┘      └──────┬──────┘
                               ▼                    ▼
                        ┌─────────────┐      ┌─────────────┐
                        │ write to A  │      │ write to C  │
                        └─────────────┘      └─────────────┘
```


## @$throttle_bytes
## @$throttle_items

## @$transform = ( method ) ->

Does nothing but `@$ ( data, send ) -> send method data`—in other words, turns a synchronous function
into a stream transform. Will send everything as received, so don't return `null` unless you want to
end the stream.


## @end = ( me ) ->

Given a stream, end it.

## @isa_stream

Return whether `x` is a stream.

## @isa_readable_stream = ( x ) ->

Return whether `x` is a stream that is readable.

## @isa_writable_stream = ( x ) ->

Return whether `x` is a stream that is writable.

## @isa_duplex_stream = ( x ) ->

Return whether `x` is a stream that is both readable and writable.

## @new_stream
`@_new_stream_from_path`, `@_new_stream_from_pipeline`, `@_new_stream_from_text`,

## @remit, @$, @remit_async, @$async

See the extensive [section on the Remit and Remit-Async Methods](#the-remit-and-remit-async-methods),
above.

## @send = ( me, data ) ->

Given a stream and some data, send / write / push that data into the stream.

>
# Backmatter
>
## Under the Hood: Base Libraries
>
> **Abstract**: PipeDreams was previously based on
> [github.com/dominictarr/event-stream](https://github.com/dominictarr/event-stream)
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
> [through2](https://github.com/rvagg/through2) provides a fairly manageable
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
### Mississippi
>
> I'm using Through2 via the
> [mississippi](https://github.com/maxogden/mississippi) collection, which
> brings a number of up-to-date and (hopefully) mutually compatible stream
> modules together in a neat bundle.
>
>
### Binary Split
>
> [github.com/maxogden/binary-split](https://github.com/maxogden/binary-split)
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

<!-- cheatcode M42 -->

# ToDo

* [X] `$as_json_line`—cast each data event as JSON plus newline character
* [ ] `$gauge` / `$progress`—display progress bar
* [X] `$tap`—deliver data events from mid-stream into another stream, without interrupting
  or changing the original pipeline
* [ ] ?retire `$bridge`—functionality replaced by `$tap`?
* [ ] replace `$as_json_line`, `$as_json_list` with `$as_json` with tags 'line', 'list'



