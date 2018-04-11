
using Grabbit
using Base.Test



# write your own tests here

@testset "Grabbit" begin
    config_fn = joinpath(Pkg.dir("Grabbit"), "test", "specs", "test.json")
    root = joinpath(Pkg.dir("Grabbit"), "test", "data", "7t_trt")

    config = Grabbit.parse_config(root, config_fn)

    @testset "Domain" begin
        d = Domain(config)
    end

    @testset "Layout" begin
        layout = Layout(root, config_fn)
        session1files = get(layout, session=1)
        basename.(get(layout, queries=Dict("type"=>["magnitude1", "bold"]), subject="01", session=1))

    end


    @testset "excludes" begin
        layout = Layout(root, config_fn)
        @test !any(ismatch.(r"derivatives", dirname.(get(layout))))

    end
    
end
