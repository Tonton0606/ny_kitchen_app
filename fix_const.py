import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Remove `const ` before widgets/constructors that are now dynamic
    # Just removing all `const ` is a sledgehammer, but safe for unblocking compilation
    # Let's target specific consts that usually wrap Theme.of
    content = re.sub(r'const\s+(Text|Icon|TextStyle|Padding|Container|BoxDecoration|Border|Divider|SizedBox|DataColumn|DataCell|DataRow|ListTile|NavigationRailDestination|EdgeInsets|Color|Row|Column|Expanded|Align|Center|Widget|Card|SingleChildScrollView|DataTable)', r'\1', content)
    
    # Also fix lists that are const
    content = re.sub(r'const\s+\[', '[', content)

    # Some remaining `const` might be left like `const EdgeInsets...` which was replaced by `EdgeInsets...`
    # Let's do a broad `const ` removal for safety, except for `const` variables at class level
    # Actually, the above should catch 99% of them. Let's also do:
    content = content.replace('const  ', ' ')
    
    if original != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    directory = r'c:\Users\tonton\Downloads\ny_kitchen_app\lib'
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
