using Test
include("../src/JippleVM.jl")

function run_simulation()
    # Create a 200x200 CMS (Core Memory State)
    vm = JippleVM.VM(200, 200)
    
    # Place a Dam to block the top half of the noise (a slit experiment)
    JippleVM.parse_instruction!(vm, "PLACE_DAM 100 1 100 90")
    JippleVM.parse_instruction!(vm, "PLACE_DAM 100 110 100 200")
    
    # Place a Lens to focus the waves that make it through the slit
    # Format: PLACE_LENS <x> <y> <radius> <refractive_index>
    # Index < 1.0 slows the wave down. 
    JippleVM.parse_instruction!(vm, "PLACE_LENS 120 100 20 0.5")
    
    # Inject continuous noise on the left edge (x=1)
    println("Running simulation for 200 ticks...")
    for t in 1:200
        # Inject noise at the center of the left edge
        JippleVM.parse_instruction!(vm, "INJECT_NOISE 1 100 2.0")
        
        # Advance physics
        JippleVM.step!(vm)
    end
    
    # Read output at the expected focal point (right side of the lens)
    focal_amp = JippleVM.read_output(vm, 150, 100, 5)
    
    # Read output at a random dead zone (behind the dam)
    dead_amp = JippleVM.read_output(vm, 150, 50, 5)
    
    println("Focal Point Amplitude: ", focal_amp)
    println("Dead Zone Amplitude: ", dead_amp)
    
    # The focal point should be significantly higher than the dead zone
    @test focal_amp > dead_amp * 2
    
    return focal_amp, dead_amp
end

@testset "Jipple Slit & Lens Simulation" begin
    focal, dead = run_simulation()
    @test focal > 0.0
end
