module Grabbit

# grab files with structure directory/filenames
# two steps:
# 1. read in layout from filesystem based on config struct/file
# 2. search layout given query.

# grabbit manages this with the Layouts, Domains, Entities, and Files.  Files
# are tagged with Entities + Domains, Domains have a root path and list of
# entities (and files?).  domains apply in order of proximity (so when entities
# conflict, closer domains can "mask" top-level ones).
#
# domains are puzzling me...there's somethign weird about how the root is
# computed: https://github.com/grabbles/grabbit/issues/57

# The logic is:
# walk directory tree, from top down.
# for each entry: extract matching entities
# 





# package code goes here

end # module
