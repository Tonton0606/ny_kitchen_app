import sys
path = r'lib\features\admin\presentation\pages\food_management_page.dart'
src = open(path, encoding='utf-8').read()
lines = src.split('\n')
line495 = lines[494]
# Print repr so we see escapes
print(repr(line495[:200]))
