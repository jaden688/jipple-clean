# Jipple VM Implementation Plan (Julia)

## Overview
Building a Wave-Interference Virtual Machine (Jipple) that executes high-performance wave physics for token-weight computation.

## Scope Definition
### In Scope
- Core Memory State (CMS) tensor management.
- Discretized wave propagation update loop.
- Basic Geometric Modifiers (Lenses and Dams).
- A CLI wrapper in Julia to run Jipple code.
### Out of Scope
- Full-scale LLM training.
- 3D visual rendering of the waves (for now).

## Implementation Phases

### Phase 1: Core CMS & Propagation (The Engine)
- **Goal**: Implement the basic 2D wave equation update loop in Julia.
- **Steps**:
  1. [ ] Setup `JippleVM.jl` with `CMS` struct.
  2. [ ] Implement `step!(vm::JippleVM)` to calculate the next amplitude state.
  3. [ ] Apply `Dams` (reflection masks) to the update.
- **Verification**: `julia test/test_propagation.jl` (must show amplitude decay and reflection).

### Phase 2: JASM Parser & Geometric Modifiers
- **Goal**: Load `.jasm` instructions and apply Lenses/Dams to the CMS.
- **Steps**:
  1. [ ] Create a parser for `PLACE_LENS` and `PLACE_DAM`.
  2. [ ] Implement the `apply_modifier!` functions to modify the scalar fields in the VM.
- **Verification**: `julia test/test_modifiers.jl` (must verify wave refraction through a lens).

### Phase 3: White Noise Power & Output Reading
- **Goal**: Inject white noise and read constructive interference as a token output.
- **Steps**:
  1. [ ] Implement the `inject_noise!` source function.
  2. [ ] Implement the `read_output` coordinate check.
- **Verification**: `julia test/test_execution.jl` (must verify that noise converges to a focal point when a lens is present).
