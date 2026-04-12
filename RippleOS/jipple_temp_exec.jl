
include("C:/Users/J_lin/Desktop/pitreader/mcp/RippleOS/src/JippleVM.jl")
using .JippleVM

vm = JippleVM.VM(200, 200)

# Compiled JASM instructions
JippleVM.parse_instruction!(vm, "PLACE_LENS 100 100 50 0.8")
JippleVM.parse_instruction!(vm, "PLACE_DAM 100 100 150 100")
JippleVM.parse_instruction!(vm, "PLACE_DAM 180 20 200 20")

# Input Token Injection
JippleVM.parse_instruction!(vm, "INJECT_NOISE 1 100 10.0")

for t in 1:100
    JippleVM.step!(vm)
end

output_amp = JippleVM.read_output(vm, 150, 100, 10)
println(output_amp)
