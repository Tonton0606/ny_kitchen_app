import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Replace colors
    content = content.replace("AppColors.primary.withValues", "Theme.of(context).colorScheme.primary.withValues")
    content = content.replace("AppColors.secondary.withValues", "Theme.of(context).colorScheme.error.withValues")
    content = content.replace("AppColors.primary", "Theme.of(context).colorScheme.primary")
    content = content.replace("AppColors.secondary", "Theme.of(context).colorScheme.error")
    content = content.replace("AppColors.card", "Theme.of(context).colorScheme.surfaceContainer")
    content = content.replace("AppColors.background", "Theme.of(context).colorScheme.surface")
    content = content.replace("AppColors.textLight", "Theme.of(context).colorScheme.onSurfaceVariant")
    content = content.replace("AppColors.text", "Theme.of(context).colorScheme.onSurface")
    content = content.replace("AppColors.divider", "Theme.of(context).colorScheme.outlineVariant")

    # Typography replacements (basic ones)
    content = re.sub(r'TextStyle\(fontSize:\s*28,\s*fontWeight:\s*FontWeight\.bold,\s*color:\s*Theme\.of\(context\)\.colorScheme\.onSurface\)', r'Theme.of(context).textTheme.headlineMedium!', content)
    content = re.sub(r'TextStyle\(fontSize:\s*28,\s*fontWeight:\s*FontWeight\.bold\)', r'Theme.of(context).textTheme.headlineMedium!', content)

    # Padding standardization to 24
    content = re.sub(r'EdgeInsets\.all\((20|20\.0|16|16\.0)\)', r'EdgeInsets.all(24)', content)
    content = re.sub(r'EdgeInsets\.all\((10|10\.0)\)', r'EdgeInsets.all(12)', content)

    if original != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    directory = r'c:\Users\tonton\Downloads\ny_kitchen_app\lib'
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart') and file != 'app_colors.dart' and file != 'app_theme.dart' and file != 'mock_data.dart' and file != 'responsive.dart':
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
