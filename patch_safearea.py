import os

has_bottom_button = [
    'child_quiz_screen.dart',
    'child_quiz_intro_screen.dart',
    'child_mission_complete_screen.dart',
    'story_preview_screen.dart',
    'child_story_viewer_screen.dart',
    'add_story_screen.dart',
    'admin_actions_bottom_sheet.dart',
    'logout_helper.dart'
]

def process_file(filepath):
    filename = os.path.basename(filepath)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'SafeArea(' not in content:
        return
        
    print(f'Processing {filename}')
    
    # We want to replace exactly "SafeArea(" with "SafeArea(top: false, bottom: x,"
    if filename in has_bottom_button:
        new_content = content.replace('SafeArea(', 'SafeArea(top: false, bottom: true, ')
    else:
        new_content = content.replace('SafeArea(', 'SafeArea(top: false, bottom: false, ')
        
    # Prevent double replacement if script is run multiple times
    new_content = new_content.replace('SafeArea(top: false, bottom: true, top: false, bottom: true, ', 'SafeArea(top: false, bottom: true, ')
    new_content = new_content.replace('SafeArea(top: false, bottom: false, top: false, bottom: false, ', 'SafeArea(top: false, bottom: false, ')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
