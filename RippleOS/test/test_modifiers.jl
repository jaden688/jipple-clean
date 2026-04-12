using Test
include("../src/JippleVM.jl")

@testset "JASM Parser & Modifiers" begin
    vm = JippleVM.VM(100, 100)
    
    # Test PLACE_LENS
    # Format: PLACE_LENS <x> <y> <radius> <refractive_index>
    JippleVM.parse_instruction!(vm, "PLACE_LENS 50 50 10 0.5")
    
    # Check that velocity_sq has changed in the lens region
    @test vm.cms.velocity_sq[50, 50] == 0.05 # 0.1 * 0.5
    @test vm.cms.velocity_sq[1, 1] == 0.1    # Unchanged outside
    
    # Test PLACE_DAM
    # Format: PLACE_DAM <x1> <y1> <x2> <y2>
    JippleVM.parse_instruction!(vm, "PLACE_DAM 10 10 20 10")
    
    # Check that the mask is 0.0 at the dam location
    @test vm.cms.mask[10, 10] == 0.0
    @test vm.cms.mask[15, 10] == 0.0
    @test vm.cms.mask[20, 10] == 0.0
    @test vm.cms.mask[10, 11] == 1.0 # Unchanged
end
