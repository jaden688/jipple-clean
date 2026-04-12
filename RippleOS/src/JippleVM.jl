module JippleVM

export VM, LayerCMS, step!, parse_instruction!, read_bridge

mutable struct LayerCMS
    amplitude::Matrix{Float64}
    prev_amplitude::Matrix{Float64}
    velocity_sq::Matrix{Float64}
    mask::Matrix{Float64}
end

mutable struct VM
    layers::Vector{LayerCMS}
    width::Int
    height::Int
    oscillators::Vector{Dict{String, Any}}
    
    function VM(w::Int, h::Int, num_layers::Int=4)
        layers = [LayerCMS(zeros(w, h), zeros(w, h), fill(0.1, w, h), ones(w, h)) for _ in 1:num_layers]
        new(layers, w, h, [])
    end
end

"""
    parse_instruction!(vm::VM, line::String)
    Parses a single JASM instruction and applies it to ALL layers.
"""
function parse_instruction!(vm::VM, line::AbstractString)
    parts = split(line)
    isempty(parts) && return
    
    cmd = parts[1]
    
    if cmd == "INJECT_OSC"
        x, y, a, freq = parse(Int, parts[2]), parse(Int, parts[3]), parse(Float64, parts[4]), parse(Float64, parts[5])
        push!(vm.oscillators, Dict("x"=>x, "y"=>y, "a"=>a, "freq"=>freq, "t"=>0))
    elseif cmd == "INJECT_OSC_LINE"
        x1, y, x2, a, freq = parse(Int, parts[2]), parse(Int, parts[3]), parse(Int, parts[4]), parse(Float64, parts[5]), parse(Float64, parts[6])
        push!(vm.oscillators, Dict("x"=>x1, "y"=>y, "x2"=>x2, "a"=>a, "freq"=>freq, "t"=>0))
    else
        for l in 1:length(vm.layers)
            cms = vm.layers[l]
            if cmd == "PLACE_LENS"
                x_c, y_c, r, n = parse(Int, parts[2]), parse(Int, parts[3]), parse(Int, parts[4]), parse(Float64, parts[5])
                for x in max(1, x_c-r):min(vm.width, x_c+r), y in max(1, y_c-r):min(vm.height, y_c+r)
                    if (x-x_c)^2 + (y-y_c)^2 <= r^2
                        cms.velocity_sq[x, y] *= n
                    end
                end
            elseif cmd == "PLACE_DAM"
                x1, y1, x2, y2 = parse(Int, parts[2]), parse(Int, parts[3]), parse(Int, parts[4]), parse(Int, parts[5])
                dx, dy = abs(x2-x1), abs(y2-y1)
                sx, sy = x1<x2 ? 1 : -1, y1<y2 ? 1 : -1
                err = dx-dy
                cx, cy = x1, y1
                while true
                    if cx>=1 && cx<=vm.width && cy>=1 && cy<=vm.height; cms.mask[cx, cy] = 0.0; end
                    (cx==x2 && cy==y2) && break
                    e2 = 2*err
                    if e2 > -dy; err-=dy; cx+=sx; end
                    if e2 < dx; err+=dx; cy+=sy; end
                end
            elseif cmd == "INJECT_NOISE"
                x, y, a = parse(Int, parts[2]), parse(Int, parts[3]), parse(Float64, parts[4])
                if x>=1 && x<=vm.width && y>=1 && y<=vm.height
                    cms.amplitude[x, y] += a
                end
            elseif cmd == "INJECT_LINE"
                x1, y1, x2, y2, a = parse(Int, parts[2]), parse(Int, parts[3]), parse(Int, parts[4]), parse(Int, parts[5]), parse(Float64, parts[6])
                dx, dy = abs(x2-x1), abs(y2-y1)
                sx, sy = x1<x2 ? 1 : -1, y1<y2 ? 1 : -1
                err = dx-dy
                cx, cy = x1, y1
                while true
                    if cx>=1 && cx<=vm.width && cy>=1 && cy<=vm.height; cms.amplitude[cx, cy] += a; end
                    (cx==x2 && cy==y2) && break
                    e2 = 2*err
                    if e2 > -dy; err-=dy; cx+=sx; end
                    if e2 < dx; err+=dx; cy+=sy; end
                end
            end
        end
    end
end

"""
    read_bridge(vm::VM, x_c::Int, y_c::Int, r::Int, dy::Int)
    Implements the 4-Leg Differential Bridge (1A, 1B, 1C, 1D).
"""
function read_bridge(vm::VM, x_c::Int, y_c::Int, r::Int, dy::Int)
    half_gap = dy / 2
    dx = sqrt(max(0, r^2 - half_gap^2))
    
    pts = [
        (Int(round(x_c - dx)), Int(round(y_c - half_gap))), # 1A
        (Int(round(x_c - dx)), Int(round(y_c + half_gap))), # 1B
        (Int(round(x_c + dx)), Int(round(y_c - half_gap))), # 1C
        (Int(round(x_c + dx)), Int(round(y_c + half_gap)))  # 1D
    ]
    
    output = zeros(4)
    for l in 1:4
        A = vm.layers[l].amplitude
        v = [ (p[1]>=1 && p[1]<=vm.width && p[2]>=1 && p[2]<=vm.height) ? A[p[1], p[2]] : 0.0 for p in pts ]
        if l == 1; output[1] = v[1] - v[4];
        elseif l == 2; output[2] = v[2] - v[3];
        elseif l == 3; output[3] = v[1] - v[2];
        elseif l == 4; output[4] = v[3] - v[4]; end
    end
    return output
end

"""
    read_field(vm::VM, layer::Int)
    Returns the full amplitude matrix for a specific layer.
"""
function read_field(vm::VM, layer::Int)
    return vm.layers[layer].amplitude
end

"""
    step!(vm::VM, bridge_motion::Function=nothing)
    Steps the wave simulation and optionally moves the bridge coordinates.
"""
function step!(vm::VM, bridge_motion::Function=(t)->nothing)
    # 1. Apply Oscillators (Source Energy)
    for osc in vm.oscillators
        osc["t"] += 1
        val = osc["a"] * sin(osc["freq"] * osc["t"])
        # If it's a line oscillator, fill the row
        if haskey(osc, "x2")
            for x in osc["x"]:osc["x2"]
                for l in 1:length(vm.layers)
                    vm.layers[l].amplitude[x, osc["y"]] = val
                end
            end
        else
            for l in 1:length(vm.layers)
                vm.layers[l].amplitude[osc["x"], osc["y"]] = val
            end
        end
    end

    # 2. Update Wave Physics (Proper Wave Equation)
    for l in 1:length(vm.layers)
        cms = vm.layers[l]
        A = cms.amplitude
        A_prev = cms.prev_amplitude
        C_sq = cms.velocity_sq
        M = cms.mask
        
        # We MUST use a temp buffer to avoid destructive updates
        A_new = copy(A)
        
        for x in 2:vm.width-1
            for y in 2:vm.height-1
                u = A[x, y]
                laplacian = (A[x+1, y] + A[x-1, y] + A[x, y+1] + A[x, y-1] - 4*u)
                # Proper wave equation: u_new = 2*u - u_old + c^2 * laplacian
                A_new[x, y] = (2.0*u - A_prev[x, y] + C_sq[x, y] * laplacian) * M[x, y]
            end
        end
        cms.prev_amplitude .= A
        cms.amplitude .= A_new
    end
end

end # module
