module Grabbit

using Compat
using Compat: @debug
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
# for each file: extract matching entities, generate tags, and add tags to file
#
#
# Querying:
#
# get files matching tags.
# get files matching tags, restricted by domain
# get files matching tags, restricted by extension
# get entity ids/dirs matching tags.
#
# design considerations:
#
# what's the most natural data structure for representing all this information?
# one-direction nesting (Domain [-> Domain] -> Entity -> File), or a
# many-to-many mapping (Domain -> { Entities, Files }, Entity -> { Domain,
# Files}, File -> { Domains, Entities }).  The first feels more...elegant
# somehow but the second is how the python implenentation works and is a little
# easier to reason about for querying: you just search the vector of things you
# have to find the matching ones.  But it feels like you're missing out on some
# of the benefits of having the _structure_: you don't have to search below
# something where you know there's a mismatch...but then again, the way the
# matching happens in the python one there could be a mismatch (if there's two
# `sub-NN` where there are different `NN`s...)


# python implementation does it this way:
#
# keep a list of domains. for every file, check whether domain applies by
# matching root of domain against file path.  extract entities from applicable
# domains.  match entitites against file path.  construct File object with
# applicable domains and matching entities, and add the file to the relevant
# domains/entitites
#
# layout: entities are stored with _ID_ key ("domain.name").  when getting
# unique values for entity, or count of files, searches by name and by id.
# 
# file: entities are stored with name key
#
# query by entity name, optionally with domain qualification (as domains kw)


abstract type AbstractEntity end

mutable struct Domain{E}
    name::String
    config::Dict
    root::String
    parent::Union{Domain,Void}
    entities::Dict{String,E}
end

Domain(root::AbstractString, config::AbstractString) =
    Domain(merge(Dict("root"=>root), JSON.parsefile(joinpath(root, config))))

Base.show(io::IO, d::Domain) = println(io, "Domain $(d.name) ($(d.root))")


mutable struct Entity <: AbstractEntity
    name::String
    pattern::Regex
    domain::Domain
    mandatory::Bool
end

function Domain(config::Dict, parent=nothing)
    d = Domain{Entity}(config["name"],
                       config,
                       config["root"],
                       parent,
                       Dict{String,Entity}())

    for e in config["entities"]
        e = Entity(e, d)
        d.entities[e.name] = e
    end

    return d
end

function Entity(config::Dict, domain::Domain)
    name = config["name"]
    pattern = Regex(config["pattern"])
    mandatory = convert(Bool, get(config, "mandatory", false))
    e = Entity(name, pattern, domain, mandatory)
    return e
end

Base.show(io::IO, e::Entity) = println(io, "Entity $(e.domain.name).$(e.name)")

function Base.match(entity::Entity, fn::AbstractString)
    m = match(entity.pattern, fn)
    if m !== nothing
        return m.captures[1]
    elseif entity.mandatory
        error("Mandatory entity $(entity.name) failed to match file $(f.path).")
    else
        return nothing
    end
end

mutable struct File
    path::String
    filename::String
    dirname::String
    tags::Dict
end

function File(fn::AbstractString, domain::Domain, entities::Dict{String,Entity})
    f = File(fn, basename(fn), dirname(fn), Dict())
    @debug "  Parsing file $fn"

    for entity in values(entities)
        m = match(entity, fn)
        if m !== nothing
            f.tags[entity.name] = m
            @debug "    ✔ $(entity.name): $m"
        else
            @debug "    ✘ $(entity.name)"
        end
    end
    return f
end


mutable struct Layout
    root::String
    entities::OrderedDict{String,Entity}
    domains::OrderedDict{String,Domain}
    files::Vector{File}
end

# placeholder
is_config(l::Layout, filename::AbstractString) = false
is_config(l::Layout) = f -> is_config(l, f)

exclude(::Layout, dir::AbstractString) = false
include(::Layout, dir::AbstractString) = true

function Layout(root::AbstractString, config::AbstractString)
    domain = Domain(root, config)
    entities = domain.entities
    l = Layout(root,
               OrderedDict{String,Entity}("$(domain.name).$k"=>v for (k,v) in entities),
               OrderedDict(domain.name=>domain),
               File[])

    # walk dir top down
    parsedir!(l, root, domain, entities)

    return l
end

function parsedir!(layout::Layout, current, domain::Domain, entities::Dict{String,Entity})
    @debug "Parsing directory $current"
    contents = joinpath.(current, readdir(current))
    dirs = [x for x in contents if isdir(x)]
    files = [x for x in contents if !isdir(x)]

    for config in filter(is_config(layout), files)
        error("Additional config files not supported yet.")
    end
    
    for file in files
        push!(layout.files, File(file, domain, entities))
    end

    for dir in dirs
        parsedir!(layout, dir, domain, entities)
    end

    return layout
end


export
    Domain,
    Entity,
    Layout,
    File

end # module
