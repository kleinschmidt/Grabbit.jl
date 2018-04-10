# Grabbit

[![Build Status](https://travis-ci.org/kleinschmidt/Grabbit.jl.svg?branch=master)](https://travis-ci.org/kleinschmidt/Grabbit.jl)

[![Coverage Status](https://coveralls.io/repos/kleinschmidt/Grabbit.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/kleinschmidt/Grabbit.jl?branch=master)

[![codecov.io](http://codecov.io/github/kleinschmidt/Grabbit.jl/coverage.svg?branch=master)](http://codecov.io/github/kleinschmidt/Grabbit.jl?branch=master)

Based on python [grabbit](https://github.com/grabbles/grabbit).

# TODO

- [ ] tests
- [ ] multiple config files/nested domains
- [ ] kw args in `Layout` constructor
- [ ] query entities (e.g., get all sessions)
- [ ] path patterns for entities and writeable
- [ ] more julian design
    - [ ] querying interface (return iterators and use filter?)
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
