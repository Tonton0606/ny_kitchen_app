import sys
sys.stdout.reconfigure(encoding='utf-8')
path = r'lib\features\admin\presentation\pages\food_management_page.dart'
src = open(path, encoding='utf-8').read()
lines = src.split('\n')
line495 = lines[494]
print(repr(line495[:200]))

# Now do the fix: replace the bad line
bad_snippet = "food[\\'price\\']"
good_snippet = 'food["price"]'
if bad_snippet in line495:
    print('Found bad snippet, fixing...')
    new_line = line495.replace(bad_snippet, good_snippet)
    lines[494] = new_line
    open(path, 'w', encoding='utf-8').write('\n'.join(lines))
    print('Done')
else:
    print('Bad snippet not found')
    # Try another approach - find price interpolation and fix it
    import re
    pattern = r"'\u20b1\$\{.*?\}'"
    matches = list(re.finditer(pattern, src))
    print('Regex matches:', len(matches))
    for m in matches:
        print(' ->', repr(m.group()))
