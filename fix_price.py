path = r'lib\features\admin\presentation\pages\food_management_page.dart'
src = open(path, encoding='utf-8').read()

# The bad line: SizedBox(width: 90, child: Text('₱\',
# Fix: replace with proper interpolation
bad = "SizedBox(width: 90, child: Text('\u20b1\\',"
good = "SizedBox(width: 90, child: Text('\u20b1${(food[\\'price\\'] as num).toDouble().toStringAsFixed(2)}',"

print('Found bad:', bad in src)
out = src.replace(bad, good, 1)
open(path, 'w', encoding='utf-8').write(out)
print('Done')
