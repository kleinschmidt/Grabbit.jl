
using Grabbit
using Base.Test



# write your own tests here

@testset "Grabbit" begin
    config = joinpath(Pkg.dir("Grabbit"), "test", "specs", "test.json")
    root = joinpath(Pkg.dir("Grabbit"), "test", "data", "7t_trt")

    @testset "Domain" begin
        d = Domain(root, config)
    end

    @testset "Layout" begin
        layout = Layout(root, config)
        session1files = get(layout, session=1)
        basename.(get(layout, queries=Dict("type"=>["magnitude1", "bold"]), subject="01", session=1))

    end


    @testset "excludes" begin
        layout = Layout(root, config)
        @test !any(ismatch.(r"derivatives", dirname.(get(layout))))

    end
    
end
