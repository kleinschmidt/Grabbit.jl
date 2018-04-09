
using Grabbit
using Base.Test

config = joinpath(Pkg.dir("Grabbit"), "test", "specs", "test.json")
root = joinpath(Pkg.dir("Grabbit"), "test", "data", "7t_trt")

d = Domain(root, config)

layout = Layout(root, config)

# write your own tests here
