
using Grabbit
using Base.Test

config = joinpath(Pkg.dir("Grabbit"), "test", "specs", "test.json")
root = joinpath(Pkg.dir("Grabbit"), "test", "data", "7t_trt")

d = Domain(root, config)

layout = Layout(root, config)

# write your own tests here
session1files = get(layout, session=1)
basename.(get(layout, queries=Dict("type"=>["magnitude1", "bold"]), subject="01", session=1))

@test !any(ismatch.(r"derivatives", dirname.(get(layout))))
