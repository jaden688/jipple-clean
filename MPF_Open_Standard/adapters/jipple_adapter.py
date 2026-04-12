import os
import shutil
import subprocess
import tempfile
from .base_adapter import BaseMPFAdapter
from pathlib import Path
from typing import Dict, Any

class JippleAdapter(BaseMPFAdapter):
    """
    Jipple Engine Adapter.
    Translates MPF JSON data into a series of geometric JASM instructions
    to be executed by the Julia Jipple VM.
    """

    def __init__(self, mpf_data: Dict[str, Any], vm_path: str = "RippleOS/src/JippleVM.jl"):
        super().__init__(mpf_data)
        self.vm_path = os.path.abspath(vm_path)
        self.julia_bin = self._resolve_julia_bin()
        self.jasm_code = []

    @staticmethod
    def _resolve_julia_bin() -> str | None:
        explicit = os.environ.get("JULIA_BIN")
        if explicit:
            explicit_path = Path(explicit).expanduser()
            if explicit_path.exists():
                return str(explicit_path)
            raise RuntimeError(
                f"JULIA_BIN is set but does not exist: {explicit_path}"
            )

        discovered = shutil.which("julia")
        if not discovered:
            return None

        discovered_path = Path(discovered)
        if "WindowsApps" in discovered_path.parts:
            return None

        return str(discovered_path)

    def _require_julia_bin(self) -> str:
        if self.julia_bin:
            return self.julia_bin
        raise RuntimeError(
            "Julia is not available. Install Julia and ensure `julia.exe` is on PATH, "
            "or set JULIA_BIN to the full path of julia.exe."
        )

    def _run_julia_script(self, sim_script: str) -> str:
        julia_bin = self._require_julia_bin()
        with tempfile.NamedTemporaryFile(
            mode="w",
            suffix=".jl",
            delete=False,
            encoding="utf-8",
        ) as handle:
            handle.write(sim_script)
            script_path = handle.name

        try:
            result = subprocess.check_output([julia_bin, script_path], text=True)
            return result.strip()
        finally:
            try:
                os.remove(script_path)
            except OSError:
                pass

    def compile(self) -> str:
        """
        Transpile the MPF data into a JASM (Jipple Assembly) program.
        """
        self.jasm_code = []
        
        # 1. Setup the Identity (Core Terrain)
        role = self.identity.get("role", "Assistant")
        archetype = self.identity.get("archetype", "Neutral")
        
        # We'll use a hashing-like mapping to pick coordinates based on identity.
        # But for now, let's just create a generic "identity lens".
        self.jasm_code.append(f"PLACE_LENS 100 100 50 0.8")
        
        # 2. Setup the Behavior (Dams and Obstacles)
        directives = self.behavior.get("core_directives", [])
        for i, directive in enumerate(directives):
            # Each directive acts as a "dam" that restricts the chaotic noise
            # from flowing into unwanted thought-spaces.
            self.jasm_code.append(f"PLACE_DAM {100} {100-i*5} {150} {100-i*5}")

        # 3. Setup the Safety Layer (Filters)
        safety_protocols = self.safety.get("safety_protocols", [])
        for i, protocol in enumerate(safety_protocols):
            # Safety dams are placed at the final output read zone.
            self.jasm_code.append(f"PLACE_DAM 180 {20 + i*10} 200 {20 + i*10}")

        return "\n".join(self.jasm_code)

    def execute_vm_bridge(self, input_text: str, x_c: int = 100, y_c: int = 100, r: int = 50, dy: int = 30, ticks: int = 300, custom_jasm: str = None) -> list:
        """
        Executes the VM with 4 layers and a 4-leg differential bridge sensor.
        """
        safe_vm_path = self.vm_path.replace("\\", "/")
        jasm_to_run = custom_jasm if custom_jasm else self.compile()
        
        jasm_calls = []
        for line in jasm_to_run.split("\n"):
            line = line.strip()
            if line and not line.startswith("#"):
                jasm_calls.append(f'JippleVM.parse_instruction!(vm, "{line}")')

        jasm_script_block = "\n".join(jasm_calls)

        sim_script = f"""
include("{safe_vm_path}")
using .JippleVM

# Initialize VM with 4 layers for the bridge
vm = JippleVM.VM(200, 200, 4)

        # Apply Geometry to all layers
        for line in split(\"\"\"{jasm_to_run}\"\"\", "\\n")
            JippleVM.parse_instruction!(vm, line)
        end

        # Inject Parallel Signal Lines (Rotated to break axis symmetry)
        JippleVM.parse_instruction!(vm, "INJECT_LINE 10 70 190 90 100.0")
        JippleVM.parse_instruction!(vm, "INJECT_LINE 10 110 190 130 100.0")

for t in 1:500
    JippleVM.step!(vm)
end

# Read the 4-layer bridge differential
vector = JippleVM.read_bridge(vm, {x_c}, {y_c}, {r}, {dy})
for v in vector
    println(v)
end
"""
        result = self._run_julia_script(sim_script)
        return [float(x) for x in result.split("\n")]

    def execute_vm_pillars(self, input_text: str, ticks: int = 200, custom_jasm: str = None, sensor_r: int = 50) -> list:
        """
        Executes the VM and returns an 8-element vector of amplitudes.
        """
        safe_vm_path = self.vm_path.replace("\\", "/")
        jasm_to_run = custom_jasm if custom_jasm else self.compile()
        
        jasm_calls = []
        for line in jasm_to_run.split("\n"):
            line = line.strip()
            if line and not line.startswith("#"):
                jasm_calls.append(f'JippleVM.parse_instruction!(vm, "{line}")')

        jasm_script_block = "\n".join(jasm_calls)

        sim_script = f"""
include("{safe_vm_path}")
using .JippleVM

vm = JippleVM.VM(200, 200)
{jasm_script_block}
JippleVM.parse_instruction!(vm, "INJECT_NOISE 100 100 1000.0")

for t in 1:{ticks}
    JippleVM.step!(vm)
end

pillars = JippleVM.read_pillars(vm, 100, 100, {sensor_r})
for p in pillars
    println(p)
end
"""
        result = self._run_julia_script(sim_script)
        return [float(x) for x in result.split("\n")]

    def execute_vm(self, input_text: str, ticks: int = 200, custom_jasm: str = None) -> float:
        """
        Executes the compiled JASM in the Julia Jipple VM.
        """
        # Fix path for Julia (forward slashes)
        safe_vm_path = self.vm_path.replace("\\", "/")

        jasm_to_run = custom_jasm if custom_jasm else self.compile()
        
        # Wrap each JASM line in a parse_instruction! call
        jasm_calls = []
        for line in jasm_to_run.split("\n"):
            line = line.strip()
            if line and not line.startswith("#"):
                jasm_calls.append(f'JippleVM.parse_instruction!(vm, "{line}")')

        jasm_script_block = "\n".join(jasm_calls)

        # We write a temporary simulation script in Julia to bridge the execution.
        sim_script = f"""
include("{safe_vm_path}")
using .JippleVM

vm = JippleVM.VM(200, 200)

# Compiled JASM instructions
{jasm_script_block}

# Input Token Injection
JippleVM.parse_instruction!(vm, "INJECT_NOISE 1 100 10.0")

for t in 1:{ticks}
    JippleVM.step!(vm)
end

output_amp = JippleVM.read_output(vm, 150, 100, 10)
println(output_amp)
"""
        result = self._run_julia_script(sim_script)
        return float(result)
