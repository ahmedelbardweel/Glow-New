import os
import glob
import re

lib_dir = r"C:\Users\Ahmed\AndroidStudioProjects\glow_app\lib"
import_statement = "import '../../../../core/widgets/custom_loader.dart';" # will adjust based on depth

def get_import_path(filepath):
    # calculate relative path to lib/core/widgets/custom_loader.dart
    rel_path = os.path.relpath(os.path.join(lib_dir, "core", "widgets", "custom_loader.dart"), os.path.dirname(filepath))
    return f"import '{rel_path.replace(os.sep, '/')}';"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Patterns to replace
    # const Center(child: CircularProgressIndicator())
    content = re.sub(
        r'const\s+Center\(\s*child:\s*CircularProgressIndicator\(\)\s*\)',
        'const CustomLoader()',
        content
    )
    
    # const Center(child: CircularProgressIndicator(color: Colors.white))
    content = re.sub(
        r'const\s+Center\(\s*child:\s*CircularProgressIndicator\(color:\s*Colors\.white\)\s*\)',
        'const CustomLoader(color: Colors.white)',
        content
    )
    
    # Center(child: CircularProgressIndicator(color: Color(0xFF9B59B6)))
    content = re.sub(
        r'Center\(\s*child:\s*CircularProgressIndicator\(color:\s*(Color\([^)]+\))\)\s*\)',
        r'CustomLoader(color: \1)',
        content
    )

    if content != original_content:
        # Need to add import if not there
        import_str = get_import_path(filepath)
        if import_str not in content:
            # find last import
            last_import_idx = content.rfind("import '")
            if last_import_idx != -1:
                end_of_line = content.find("\n", last_import_idx)
                content = content[:end_of_line] + f"\n{import_str}" + content[end_of_line:]
            else:
                content = f"{import_str}\n" + content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and file != 'custom_loader.dart':
            process_file(os.path.join(root, file))

print("Done.")
