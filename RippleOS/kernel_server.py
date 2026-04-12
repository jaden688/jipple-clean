import asyncio
import json
import os
import sys
from pathlib import Path

import websockets

BASE_DIR = Path(__file__).resolve().parent
MPF_DIR = BASE_DIR.parent / "MPF_Open_Standard"
VM_PATH = BASE_DIR / "src" / "JippleVM.jl"

# Add the repo MPF implementation regardless of the caller's cwd.
sys.path.append(str(MPF_DIR))
from adapters.jipple_adapter import JippleAdapter

# A minimal placeholder "Fat Agent" payload to feed the JippleAdapter
MINIMAL_AGENT = {
    "identity": {"role": "RippleOS Kernel", "archetype": "System"},
    "behavior": {"core_directives": ["Process user requests through wave interference."]},
    "safety_layer": {"safety_protocols": ["Do not crash."]}
}

adapter = JippleAdapter(MINIMAL_AGENT, vm_path=str(VM_PATH))
MOCK_KERNEL = os.environ.get("RIPPLE_MOCK_KERNEL", "").lower() in {"1", "true", "yes", "on"}


def build_mock_response(user_input: str) -> dict:
    text = user_input.strip() or "empty input"
    return {
        "status": "success",
        "amplitude": 0.0,
        "mock": True,
        "response": (
            "Mock kernel mode: Julia is unavailable, so RippleOS is echoing a "
            f"simulated response for '{text}'."
        ),
    }

async def kernel_handler(websocket):
    print("UI Connected to RippleOS Kernel.")
    try:
        async for message in websocket:
            data = json.loads(message)
            user_input = data.get("input", "")
            
            print(f"Received input from UI: {user_input}")
            
            # Execute the Jipple VM
            # In a real OS, the input would change the JASM. Here we just run the base terrain.
            try:
                if MOCK_KERNEL:
                    response = build_mock_response(user_input)
                else:
                    amplitude = adapter.execute_vm(user_input, ticks=100)
                    
                    # Mock token mapping based on amplitude for demonstration
                    response_token = "Ripples stabilized."
                    if amplitude < 1e-50:
                        response_token = "Interference pattern matched."
                    
                    response = {
                        "status": "success",
                        "amplitude": amplitude,
                        "response": f"Jipple Engine Output: {response_token} (Amp: {amplitude})"
                    }
            except Exception as e:
                response = {
                    "status": "error",
                    "response": f"Kernel Panic: {str(e)}"
                }
                
            await websocket.send(json.dumps(response))
    except websockets.exceptions.ConnectionClosed:
        print("UI Disconnected.")

async def main():
    host = "localhost"
    port = 8765
    host = os.environ.get("RIPPLE_HOST", host)
    port = int(os.environ.get("RIPPLE_PORT", port))
    mode = "mock" if MOCK_KERNEL else "julia"
    print(f"RippleOS kernel mode: {mode}")
    print(f"RippleOS Kernel Server starting on ws://{host}:{port}...")
    async with websockets.serve(kernel_handler, host, port):
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
