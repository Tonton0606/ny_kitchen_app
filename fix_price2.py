path = r'lib\features\admin\presentation\pages\food_management_page.dart'
src = open(path, encoding='utf-8').read()

# Fix the bad escaped quotes in the price line
old = r"SizedBox(width: 90, child: Text('\u20b1${(food[\'price\'] as num).toDouble().toStringAsFixed(2)}',"
new = "SizedBox(width: 90, child: Text('\u20b1\${(food[\"price\"] as num).toDouble().toStringAsFixed(2)}',"

print('Found:', old in src)
out = src.replace(old, new, 1)
open(path, 'w', encoding='utf-8').write(out)
print('Fixed. Checking line 495...')
lines = out.split('\n')
print(lines[494])
