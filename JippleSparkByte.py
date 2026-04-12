import json
import os
import sys

# Add the adapters directory to the path so we can import the JippleAdapter
sys.path.append(os.path.abspath("MPF_Open_Standard"))
from adapters.jipple_adapter import JippleAdapter

def process_sparkbyte():
    payload_path = "data/agents/fat_agents/SparkByte_Full.json"
    with open(payload_path, "r") as f:
        data = json.load(f)
    
    # Create the Jipple Adapter
    adapter = JippleAdapter(data)
    
    # Custom SparkByte Geometry Mapping
    jasm = adapter.compile()
    
    palette = data.get("emotion_palette", [])
    for i, emotion in enumerate(palette):
        label = emotion.get("label")
        intensity = emotion.get("intensity", 0.5)
        
        # Mapping intensity to geometric properties
        if intensity > 0.6:
            jasm += f"\nPLACE_LENS {50 + i*10} {100} {15} {1.0 - intensity}"
        else:
            jasm += f"\nPLACE_DAM {10 + i*5} {10} {10 + i*5} {50}"
            
    print("--- GENERATED JASM FOR SPARKBYTE ---")
    print(jasm)
    
    # Execute in the VM
    print("\n--- EXECUTING IN JIPPLE VM ---")
    amplitude = adapter.execute_vm("Hello SparkByte!", custom_jasm=jasm)
    print(f"Resulting SparkByte Interference Amplitude: {amplitude}")

if __name__ == "__main__":
    process_sparkbyte()
