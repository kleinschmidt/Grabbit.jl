__precompile__(true)

module Grabbit

using Compat
using Compat: @debug
using Compat.Printf
using JSON
using DataStructures
using ArgCheck
using Missings
using EnglishText

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

mutable struct Entity
    name::String
    pattern::Regex
    mandatory::Bool
    values::OrderedSet
end

mutable struct Domain
    name::String
    config::Dict
    root::String
    parent::Union{Domain,Compat.Nothing}
    entities::Dict{String,Entity}
    include                     # predicte function for whether to include
end

Base.show(io::IO, d::Domain) = print(io, "Domain $(d.name) ($(d.root))")



function Domain(config::Dict, parent=nothing)
    @argcheck(!all(haskey.(Ref(config), ["include", "exclude"])),
              "Cannot specify both include and exclude regex")
    
    d = Domain(config["name"],
               config,
               config["root"],
               parent,
               Dict{String,Entity}(),
               make_include_predicate(config))

    for e in config["entities"]
        e = Entity(e)
        d.entities[e.name] = e
    end

    return d
end

make_include_predicate(config) =
    if haskey(config, "include")
        f -> Compat.occursin(Regex(make_pattern(config["include"])), f)
    elseif haskey(config, "exclude")
        f -> Compat.occursin(Regex(make_pattern(config["exclude"])), f) ? false : missing
    else
        f -> missing
    end

_include(d::Domain, f::AbstractString) = d.include(f) & _include(d.parent, f)
_include(::Compat.Nothing, f::AbstractString) = missing
include(d::Domain, f::AbstractString) = (incl = _include(d, f); incl === missing ? true : incl)
# curry
include(d::Domain) = f -> include(d, f)

function Entity(config::Dict)
    name = config["name"]
    pattern = Regex(config["pattern"])
    mandatory = convert(Bool, get(config, "mandatory", false))
    e = Entity(name, pattern, mandatory, OrderedSet())
    return e
end

Base.show(io::IO, e::Entity) = println(io, "Entity $(e.name)")

function match!(entity::Entity, fn::AbstractString)
    m = match(entity.pattern, fn)
    if m !== nothing
        value = m.captures[1]
        push!(entity.values, value)
        return value
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

Base.show(io::IO, f::File) = show(io, f.path)

function File(fn::AbstractString, domain::Domain, entities::Dict{String,Entity})
    f = File(fn, basename(fn), dirname(fn), Dict())
    @debug "  Parsing file $fn"

    for entity in values(entities)
        m = match!(entity, fn)
        if m !== nothing
            f.tags[entity.name] = m
            @debug "    ✔ $(entity.name): $m"
        else
            @debug "    ✘ $(entity.name)"
        end
    end
    return f
end

tags(f::File) = f.tags
path(f::File) = f.path
Base.basename(f::File) = f.filename
Base.dirname(f::File) = f.dirname


mutable struct Layout
    root::String
    entities::OrderedDict{String,Entity}
    mandatory::Set{Entity}
    domains::OrderedDict{String,Domain}
    files::Vector{File}
    config_filenames::Set{String}
end

function Base.show(io::IO, layout::Layout)
    files = ItemQuantity( length(layout.files), "file")
    print(io, "Layout of $files in $(layout.root)")
    for (domain_name, domain) in layout.domains
        print(io, "\n  Domain \"$domain_name\":")
        maxlen = maximum(length(k) for k in keys(domain.entities))
        for (k, e) in domain.entities
            print(io, "\n    ")
            print(io, rpad("\"$k\"", maxlen+3))
            chars_left = displaysize(io)[2] - (maxlen+3) - 4
            reprs = []
            for v in e.values
                r = repr(v)
                if chars_left < length(r)+5
                    push!(reprs, "…")
                    break
                else
                    push!(reprs, repr(v))
                    chars_left -= length(r)+2
                end
            end
            print(io, "[")
            join(io, reprs, ", ")
            print(io, "]")
        end
    end
end

function Base.showcompact(io::IO, layout::Layout)
    files = ItemQuantity( length(layout.files), "file")
    domains = ItemQuantity(length(layout.domains), "domain")
    entities = ItemQuantity(length(layout.entities), "entity")
    print(io, "Layout of $files in $(layout.root) ($entities in $domains)")
end

# placeholder
is_config(l::Layout, filename::AbstractString) = false
is_config(l::Layout) = f -> is_config(l, f)

"""
    parse_config(root, config)

Read in config JSON file (relative to root), adding a "root" key if it's missing
"""
parse_config(root::AbstractString, config::AbstractString) =
    merge(Dict("root"=>root), JSON.parsefile(joinpath(root, config)))

Layout(root::AbstractString, config::AbstractString) = Layout(parse_config(root, config))


const DEFAULT_ENTITIES =
    OrderedDict("extension" => Entity("extension",
                               r"\.([^/]*?)$",
                               false,
                               OrderedSet()))

function Layout(config::Dict)
    root = config["root"]
    domain = Domain(config)
    entities = merge(Dict(DEFAULT_ENTITIES), domain.entities)

    # filenames to look for inside tree to create new domains
    config_files = get(config, "config_filename", [])
    
    l = Layout(root,
               merge(DEFAULT_ENTITIES,
                     OrderedDict{String,Entity}("$(domain.name).$k"=>v for (k,v) in entities)),
               Set{Entity}(e for (k, e) in entities if e.mandatory),
               OrderedDict(domain.name=>domain),
               File[],
               config_files)

    # walk dir top down
    parsedir!(l, root, domain, entities)

    return l
end

Layout(r, e, m, d, f, config_files::AbstractString) =
    Layout(r, e, m, d, f, Set{String}((config_files, )))
Layout(r, e, m, d, f, config_files::AbstractArray) =
    Layout(r, e, m, d, f, Set{String}(string(f) for f in config_files))

function parsedir!(layout::Layout, current, domain::Domain, entities::Dict{String,Entity})
    @debug "Parsing directory $current"
    contents = [joinpath(current, x) for x in readdir(current) if include(domain, x)]
    dirs = filter(isdir, contents)
    files = filter(!isdir, contents)

    configs = filter(is_config(layout), files)
    filter!(!is_config(layout), files)

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

################################################################################
# Querying a layout
################################################################################

make_pattern(val::Number) = "0*$val"
make_pattern(val::AbstractArray) = "(" * join(make_pattern.(val), "|") * ")"
make_pattern(val) = "$val"

function make_regex(val, regex_search=false)
    pattern = make_pattern(val)
    regex_search ? Regex(pattern) : Regex("^$pattern\$")
end

function make_query(layout, filters)
    filters = Dict(string(k)=>make_regex(v) for (k,v) in filters)
    function(f::File)
        @debug "Querying file $(f.filename):"
        for (name, filter) in filters
            if !haskey(f.tags, name)
                @debug "  ✘ no $name"
                return false
            elseif !Compat.occursin(filter, f.tags[name])
                @debug "  ✘ $name ($(f.tags[name])) ≠ $(filter.pattern)"
                return false
            else
                @debug "  ✔ $name = $(filter.pattern)"
            end
        end
        return true
    end
end

function Base.get(layout::Layout; queries=Dict(), kw...)
    queries = merge!(Dict{Any,Any}(kw), queries)
    query = make_query(layout, queries)
    filter(query, layout.files)
end

function tags(layout)
    # get all the tags, in teh form of a Dict(entity=>values)
    ts = Dict()
    for (k, e) in layout.entities
        vals = get!(ts, e.name, OrderedSet())
        union!(vals, e.values)
    end
    return ts
end

export
    Domain,
    Entity,
    Layout,
    File,
    basename,
    dirname,
    path,
    get,
    tags

end # module
