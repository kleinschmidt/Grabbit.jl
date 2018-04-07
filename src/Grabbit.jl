module Grabbit

using JSON
using DataStructures

# grab files with structure directory/filenames
# two steps:
# 1. parse config into entities, and then read in layout from filesystem based
#    on config
# 2. search layout given query ("get(; kw...)")

# grabbit manages this with the Layouts, Domains, Entities, and Files.  Files
# are tagged with Entities + Domains, Domains have a root path and list of
# entities (and files?).  domains apply in order of proximity (so when entities
# conflict, closer domains can "mask" top-level ones).
#
# domains are puzzling me...there's somethign weird about how the root is
# computed: https://github.com/grabbles/grabbit/issues/57.  Okay that's a bug.
# They should apply to the subdirectory their config is found in.

# The logic is:
#
# walk directory tree, from top down.
#
# if you see a config file, create a new domain and compose it with the current one.
#
# for each entry: extract matching entities
# 


# python implementation does it this way:
#
# keep a list of domains. for every file, check whether domain applies by
# matching root of domain against file path.  extract entities from applicable
# domains.  match entitites against file path.  construct File object with
# applicable domains and matching entities, and add the file to the relevant
# domains/entitites

abstract type AbstractEntity end

mutable struct Domain
    name::String
    config::Dict
    root::String
    parent::Union{Domain,Void}
    entities::Vector{<:AbstractEntity}
end

mutable struct Entity <: AbstractEntity
    name::String
    pattern::Regex
    domain::Domain
    mandatory::Bool
end


Domain(root::AbstractString, config::AbstractString) =
    Domain(merge(Dict("root"=>root), JSON.parsefile(joinpath(root, config))))

function Domain(config::Dict, parent=nothing)
    @show config
    d = Domain(config["name"],
               config,
               config["root"],
               parent,
               Entity[])
    d.entities = [Entity(e, d) for e in config["entities"]]
    return d
end


function Entity(config::Dict, domain::Domain)
    name = config["name"]
    pattern = Regex(config["pattern"])
    mandatory = convert(Bool, get(config, "mandatory", false))
    e = Entity(name, pattern, domain, mandatory)
    return e
end







export
    Domain,
    Entity

end # module
