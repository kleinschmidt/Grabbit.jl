using Compat
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
        layout = Layout(config)
        
        session1files = get(layout, session=1)
        @test all(haskey(f.tags, "session") for f in session1files)
        @test all(f.tags["session"] == "1" for f in session1files)
        @test unique(f.tags["subject"] for f in session1files) ==
            [@sprintf("%02d", i) for i in 1:10]
        @test any(!haskey(f.tags, "acquisition") for f in session1files)

        @test get(layout, queries = Dict("session"=>1)) == session1files

        subj12 = get(layout, subject = [1,2])
        @test all(haskey(f.tags, "subject") for f in subj12)
        @test unique(f.tags["subject"] for f in subj12) == ["01", "02"]

        @test isempty(setdiff(subj12, vcat(get(layout, subject=1), get(layout, subject=2))))

        @test subj12 == get(layout, subject = ["01", "02"])
        @test subj12 == get(layout, subject = [1, "02"])
        @test subj12 == get(layout, subject = [2, 1])
        @test subj12 == get(layout, subject = [1, 2, 1])

        basename.(get(layout, queries=Dict("type"=>["magnitude1", "bold"]), subject="01", session=1))

    end


    @testset "excludes" begin
        layout = Layout(root, config_fn)
        @test !any(ismatch.(r"derivatives", dirname.(get(layout))))

    end
    
end
