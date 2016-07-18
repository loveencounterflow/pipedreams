
# PipeDreams Plugin: TSV


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Usage](#usage)
- [API](#api)
- [@$split_tsv = ( settings ) ->](#split_tsv---settings---)
- [@$as_tsv = ( names..., settings ) ->](#as_tsv---names-settings---)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Usage

## API


## @$split_tsv = ( settings ) ->

A stream transform to help in reading files with data in
[Tab-Separated Values (TSV)](http://www.iana.org/assignments/media-types/text/tab-separated-values)
format. It accepts a stream of buffers or text, splits it into
lines, and splits each line into fields (using the tab character, U+0009). In the process
it can also skip empty and blank lines, omit comments, and name fields.

+ `comments` defines how to recognize a comment. If it is a string, lines and individual fields that start
  with the specified text are left out of the results. It is also possible to use a RegEx or a custom
  function to recognize comments.

+ When `empty` is set to `false`, empty lines (and lines that contain nothing but empty fields) are
  left in the stream.

* If `settings[ 'names' ]` is set to `'inline'`, field names are gleaned from the first non-discarded line
  of input; if it is a list of `n` elements, it defines labels for the first `n` columns of data. Columns
  with no defined name will be labelled as `'field-0'`, `'field-5'` and so on, depending on the zero-based
  index of the respective column. Where naming of fields is used, each TSV data line will be turned into a
  JS object with the appropriately named members, such as `{ name: 'John', age: 32, 'field-2': 'lawyer', }`;
  where no naming is used, lists of values are sent into the stream, such as `[ 'John', 32, 'lawyer', ]`.

Observe that `$split_tsv` has been (experimentally) factored out into a plugin of sorts; to use it, be sure
has no interesting return value, but will provide `D.$split_tsv` for you to use.
to `require 'pipedreams/lib/plugin-split-tsv'` after your `D = require 'pipedreams'` statement. This import

## @$as_tsv = ( names..., settings ) ->



