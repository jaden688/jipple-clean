using Test
include("../src/JippleVM.jl")

@testset "Jipple Noise & Output" begin
    vm = JippleVM.VM(100, 100)
    
    # Test INJECT_NOISE
    # Format: INJECT_NOISE <x> <y> <amplitude>
    JippleVM.parse_instruction!(vm, "INJECT_NOISE 1 50 1.0")
    
    # Check that amplitude is set at the boundary
    @test vm.cms.amplitude[1, 50] == 1.0
    
    # Test READ_OUTPUT
    # Format: READ_OUTPUT <x> <y> <radius>
    # Should return the peak amplitude in that region.
    vm.cms.amplitude[75, 75] = 5.0
    peak = JippleVM.read_output(vm, 75, 75, 5)
    @test peak == 5.0
end
