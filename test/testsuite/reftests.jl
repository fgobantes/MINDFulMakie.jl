@testset "reftests" begin
    @show readdir(TMPDIR)
    for testfile in readdir(TMPDIR)
        testpath = joinpath(TMPDIR, testfile)
        reftestpath = joinpath(ASSETSDIR, "ref"*testfile)
        @test_reference(reftestpath, load(testpath), by=psnr_equality(PSNR_THRESHOLD))
    end
end
