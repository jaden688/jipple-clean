
include("C:/Users/J_lin/Desktop/pitreader/mcp/RippleOS/src/JippleVM.jl")
using .JippleVM

vm = JippleVM.VM(200, 200)

# Compiled JASM instructions
JippleVM.parse_instruction!(vm, "PLACE_LENS 100 100 50 0.8")
JippleVM.parse_instruction!(vm, "PLACE_DAM 100 100 150 100")
JippleVM.parse_instruction!(vm, "PLACE_DAM 100 95 150 95")
JippleVM.parse_instruction!(vm, "PLACE_DAM 100 90 150 90")
JippleVM.parse_instruction!(vm, "PLACE_DAM 100 85 150 85")
JippleVM.parse_instruction!(vm, "PLACE_DAM 100 80 150 80")
JippleVM.parse_instruction!(vm, "PLACE_DAM 10 10 10 50")
JippleVM.parse_instruction!(vm, "PLACE_DAM 15 10 15 50")
JippleVM.parse_instruction!(vm, "PLACE_LENS 70 100 15 0.35")
JippleVM.parse_instruction!(vm, "PLACE_DAM 25 10 25 50")
JippleVM.parse_instruction!(vm, "PLACE_DAM 30 10 30 50")
JippleVM.parse_instruction!(vm, "PLACE_LENS 100 100 15 0.30000000000000004")
JippleVM.parse_instruction!(vm, "PLACE_DAM 40 10 40 50")
JippleVM.parse_instruction!(vm, "PLACE_DAM 45 10 45 50")
JippleVM.parse_instruction!(vm, "PLACE_DAM 50 10 50 50")
JippleVM.parse_instruction!(vm, "PLACE_LENS 140 100 15 0.19999999999999996")
JippleVM.parse_instruction!(vm, "PLACE_DAM 60 10 60 50")
JippleVM.parse_instruction!(vm, "PLACE_DAM 65 10 65 50")
JippleVM.parse_instruction!(vm, "PLACE_LENS 170 100 15 0.30000000000000004")
JippleVM.parse_instruction!(vm, "PLACE_DAM 75 10 75 50")
JippleVM.parse_instruction!(vm, "PLACE_DAM 80 10 80 50")
JippleVM.parse_instruction!(vm, "PLACE_LENS 200 100 15 0.30000000000000004")
JippleVM.parse_instruction!(vm, "PLACE_DAM 90 10 90 50")

# Input Token Injection
JippleVM.parse_instruction!(vm, "INJECT_NOISE 1 100 10.0")

for t in 1:200
    JippleVM.step!(vm)
end

output_amp = JippleVM.read_output(vm, 150, 100, 10)
println(output_amp)
