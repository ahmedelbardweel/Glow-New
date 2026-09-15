import io
import sys
import colorsys
import base64
from PIL import Image
from pygltflib import GLTF2

def shift_hue(file_path, out_path):
    gltf = GLTF2().load(file_path)
    
    mat = gltf.materials[0]
    tex_index = mat.pbrMetallicRoughness.baseColorTexture.index
    texture = gltf.textures[tex_index]
    image_info = gltf.images[texture.source]
    
    buffer_view = gltf.bufferViews[image_info.bufferView]
    
    # In pygltflib, for a loaded GLB, gltf._glb_data holds the binary chunk!
    # Wait, gltf.binary_blob() method gets the binary data
    bin_data = gltf.binary_blob()
    if bin_data is None:
        print("No binary blob found!")
        return
        
    image_bytes = bin_data[buffer_view.byteOffset : buffer_view.byteOffset + buffer_view.byteLength]
    
    print("Modifying image...")
    try:
        img = Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        print("Failed to open image from bytes. Size:", len(image_bytes))
        # fallback: find where JPEG/PNG starts
        # JPEG starts with FF D8 FF E0
        # PNG starts with 89 50 4E 47
        idx = image_bytes.find(b'\x89PNG')
        if idx == -1:
            idx = image_bytes.find(b'\xff\xd8\xff')
        
        if idx != -1:
            print("Found image signature at", idx)
            image_bytes = image_bytes[idx:]
            img = Image.open(io.BytesIO(image_bytes))
        else:
            raise e
            
    img = img.convert('RGBA')
    
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a == 0: continue
            
            h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
            
            if s > 0.15 and 0.15 < h < 0.45:
                new_r, new_g, new_b = colorsys.hsv_to_rgb(0.015, s, v)
                pixels[x, y] = (int(new_r*255), int(new_g*255), int(new_b*255), a)
                
    out_io = io.BytesIO()
    img.save(out_io, format='PNG')
    new_image_bytes = out_io.getvalue()
    
    b64 = base64.b64encode(new_image_bytes).decode('utf-8')
    image_info.uri = f"data:image/png;base64,{b64}"
    image_info.bufferView = None
    
    print("Saving modified GLB...")
    gltf.save(out_path)
    print(f"Success! Saved {out_path}")

if __name__ == '__main__':
    shift_hue(sys.argv[1], sys.argv[2])
