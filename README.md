# Grabbit

[![Build Status](https://travis-ci.org/kleinschmidt/Grabbit.jl.svg?branch=master)](https://travis-ci.org/kleinschmidt/Grabbit.jl)

[![codecov.io](http://codecov.io/github/kleinschmidt/Grabbit.jl/coverage.svg?branch=master)](http://codecov.io/github/kleinschmidt/Grabbit.jl?branch=master)

Based on python [grabbit](https://github.com/grabbles/grabbit).

Currently supports most basic features:

* Ingest JSON config and parse layout with `Layout(root, config_file)`.  JSON
  config files use the same format as [python
  grabbit](https://github.com/grabbles/grabbit), with some features not
  implented yet.
* Get files from layout:
    * `get(layout)` - all files
    * `get(layout, extension="txt")` - all `.txt` files
    * `get(layout, extension=["txt", "rst"])` - all `.txt` or RST files.
    * `get(layout, subject=1)` - all files tagged with the `subject` entity,
      with a value of 1 (possibly with leading zeros)
    * `get(layout, subject="1[0-9]")` - all files from subjects 10-19.
    
    Returned files are `File` structs.  You can extract the full `path`, the
    `dirname`, or the `basename` of a file, or access its `tags` (a dict of
    entity names to values).

# TODO

- [x] tests
- [ ] docs
- [ ] missing features from python grabbit:
    - [ ] multiple config files/nested domains
    - [ ] kw args in `Layout` constructor
    - [ ] query entities (e.g., get all sessions).  (supported by accessing the
      `Layout.entities` field, which is a dict of scoped `domain.entity` names to
      `Entity` structs.
    - [ ] path patterns for entities
    - [ ] writeables
    - [ ] tree queries (nearest neighbor to given file/path)
    - [ ] data types for entities
- [ ] more julian design?
    - [ ] querying interface (return iterators and use filter?)
    - [ ] more flexible queries.  should be straightforward to support ranges,
          for instance.
    - [ ] algorithm: keep track of Tags as you traverse the file hierarchy and
          propogate them back up the tree.  use tree to do queries (instead of
          traversing the list of files every time).  not that this is really a
          performance bottleneck, at least not with reasonably sized datasets.
          but it might help to make behavior more consistent and clear.
- [ ] weird edge cases
    - [ ] multiple (possibly conflicting) matches to an Entity
    - [ ] nested includes/excludes.  what short circuits when
    - [ ] matching against whole path string can lead to some weirdness (e.g. if
          you have a pattern that matches across directory breaks)
