from pygltflib import GLTF2
import sys

def inspect_gltf(file_path):
    gltf = GLTF2().load(file_path)
    print(f"Loaded {file_path}")
    print(f"Number of materials: {len(gltf.materials)}")
    for i, mat in enumerate(gltf.materials):
        print(f"\nMaterial {i}: {mat.name}")
        if mat.pbrMetallicRoughness:
            pbr = mat.pbrMetallicRoughness
            print(f"  Base Color Factor: {pbr.baseColorFactor}")
            if pbr.baseColorTexture:
                print(f"  Base Color Texture Index: {pbr.baseColorTexture.index}")
            else:
                print("  No Base Color Texture")
        else:
            print("  No PBR Metallic Roughness")

if __name__ == '__main__':
    inspect_gltf(sys.argv[1])
