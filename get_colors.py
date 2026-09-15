from pygltflib import GLTF2
import sys
from PIL import Image
import io

def get_dominant_color(file_path):
    gltf = GLTF2().load(file_path)
    
    if not gltf.materials:
        return
        
    mat = gltf.materials[0]
    if not mat.pbrMetallicRoughness or not mat.pbrMetallicRoughness.baseColorTexture:
        return
        
    tex_index = mat.pbrMetallicRoughness.baseColorTexture.index
    texture = gltf.textures[tex_index]
    image_info = gltf.images[texture.source]
    
    buffer_view = gltf.bufferViews[image_info.bufferView]
    
    with open(file_path, 'rb') as f:
        f.seek(12)
        json_chunk_length = int.from_bytes(f.read(4), 'little')
        f.seek(4, 1)
        f.seek(json_chunk_length, 1)
        bin_chunk_length = int.from_bytes(f.read(4), 'little')
        f.seek(4, 1)
        bin_data = f.read(bin_chunk_length)
        
    image_bytes = bin_data[buffer_view.byteOffset : buffer_view.byteOffset + buffer_view.byteLength]
    
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img = img.convert('RGB')
        img_1x1 = img.resize((1, 1))
        color = img_1x1.getpixel((0, 0))
        hex_color = '#{:02x}{:02x}{:02x}'.format(color[0], color[1], color[2])
        print(f"{file_path}: BaseColor Average = {hex_color} {color}")
    except Exception as e:
        print(f"{file_path}: Error {e}")

if __name__ == '__main__':
    for f in sys.argv[1:]:
        get_dominant_color(f)
