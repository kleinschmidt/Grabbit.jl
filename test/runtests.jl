using Compat
using Grabbit
using Grabbit: parse_config
using Base.Test



# write your own tests here

@testset "Grabbit" begin
    config_fn = joinpath(Pkg.dir("Grabbit"), "test", "specs", "test.json")
    root = joinpath(Pkg.dir("Grabbit"), "test", "data", "7t_trt")

    config = parse_config(root, config_fn)

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

        # use second arg Dict with queries equivalent to kw args
        @test get(layout, Dict("session"=>1)) == session1files

        subj12 = get(layout, subject = [1,2])
        @test all(haskey(f.tags, "subject") for f in subj12)
        @test unique(f.tags["subject"] for f in subj12) == ["01", "02"]

        @test isempty(setdiff(subj12, vcat(get(layout, subject=1), get(layout, subject=2))))

        @test subj12 == get(layout, subject = ["01", "02"])
        @test subj12 == get(layout, subject = [1, "02"])
        @test subj12 == get(layout, subject = [2, 1])
        @test subj12 == get(layout, subject = [1, 2, 1])

        fs = get(layout, Dict("type"=>["magnitude1", "bold"]), subject="01", session=1)
        @test isempty(setdiff(unique(get.(fs, "type")), ["magnitude1", "bold"]))
        @test all(get.(fs, "subject") .== "01")
        @test all(get.(fs, "session") .== "1")
        @test all(get.(fs, "extension") .== "nii.gz")
    end

    @testset "Default entities" begin
        @testset "extension" begin
            layout = Layout(config)
            @test !isempty(get(layout, extension="json"))
            @test length(get(layout, subject=1, session=1, run=1, extension="json")) == 1
            @test length(get(layout, subject=1, extension="nii.gz")) == 20
            # needs to be exact match
            @test isempty(get(layout, extension="nii"))
            # ...unless provided a regex
            @test length(get(layout, subject=1, extension="nii.*")) == 20
            @test isempty(get(layout, extension=["txt", "rtf"]))
            @test length(get(layout, subject=1, extension="json")) == 4
            @test length(get(layout, subject=1, extension=["nii.gz", "json"])) == 24
        end
    end

    @testset "excludes/includes" begin
        layout = Layout(root, config_fn)
        @test !any(occursin.(r"derivatives", dirname.(get(layout))))

        config_incl = parse_config(root,
                                   joinpath(Pkg.dir("Grabbit"),
                                            "test",
                                            "specs",
                                            "test_include.json"))
        layout_incl = Layout(config_incl)
        @test !any(occursin.(r"models/excluded_model.json", path.(get(layout_incl))))
    end
    
end
