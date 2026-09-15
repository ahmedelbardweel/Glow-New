import os
import re

lib_dir = r"C:\Users\Ahmed\AndroidStudioProjects\glow_app\lib"

def get_import_path(filepath):
    rel_path = os.path.relpath(os.path.join(lib_dir, "core", "widgets", "shimmer_loading.dart"), os.path.dirname(filepath))
    return f"import '{rel_path.replace(os.sep, '/')}';"

files_to_patch = {
    r"features\content\presentation\screens\child_badges_screen.dart": "const ShimmerLoading(type: ShimmerType.grid)",
    r"features\content\presentation\screens\child_quiz_screen.dart": "const ShimmerLoading(type: ShimmerType.card)",
    r"features\content\presentation\screens\child_story_viewer_screen.dart": "const ShimmerLoading(type: ShimmerType.card)",
    r"features\content\presentation\screens\child_world_missions_screen.dart": "const ShimmerLoading()",
    r"features\content\presentation\screens\mission_questions_screen.dart": "const ShimmerLoading()",
    r"features\content\presentation\screens\mission_stories_screen.dart": "const ShimmerLoading()",
    r"features\content\presentation\screens\world_missions_screen.dart": "const ShimmerLoading()",
    r"features\dashboard\presentation\screens\admin_dashboard_screen.dart": "const ShimmerLoading()",
    r"features\dashboard\presentation\screens\parent_dashboard_screen.dart": "const ShimmerLoading()",
}

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            for key, replacement in files_to_patch.items():
                if key in filepath:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Replace CustomLoader() with replacement
                    # It might be `const CustomLoader()` or `const CustomLoader(color: ...)`
                    content = re.sub(
                        r'const\s+CustomLoader\([^)]*\)',
                        replacement,
                        content
                    )
                    
                    # Some might not have const
                    content = re.sub(
                        r'CustomLoader\(\)',
                        replacement,
                        content
                    )

                    import_str = get_import_path(filepath)
                    if "shimmer_loading.dart" not in content and replacement in content:
                        last_import_idx = content.rfind("import '")
                        if last_import_idx != -1:
                            end_of_line = content.find("\n", last_import_idx)
                            content = content[:end_of_line] + f"\n{import_str}" + content[end_of_line:]
                        else:
                            content = f"{import_str}\n" + content
                            
                    # Remove custom_loader if it's no longer used
                    if "CustomLoader" not in content and "custom_loader.dart" in content:
                        content = re.sub(r"import\s+'[^']*/custom_loader\.dart';\n", "", content)

                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {filepath} with {replacement}")

print("Done.")
