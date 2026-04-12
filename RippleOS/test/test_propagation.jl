using Test
include("../src/JippleVM.jl")

@testset "Jipple Core Propagation" begin
    # Initialize a 100x100 CMS
    vm = JippleVM.VM(100, 100)
    
    # Check that initial amplitude is zero
    @test all(vm.cms.amplitude .== 0.0)
    
    # Inject a single pulse at the center
    vm.cms.amplitude[50, 50] = 1.0
    
    # Take a step
    JippleVM.step!(vm)
    
    # After one step, the center amplitude should have changed 
    # and the wave should start to spread to its neighbors.
    @test vm.cms.amplitude[50, 50] != 1.0
    @test any(vm.cms.amplitude[49:51, 49:51] .!= 0.0)
end
