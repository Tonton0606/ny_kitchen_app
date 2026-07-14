import re
import os

def fix_errors():
    output = """
  error - lib\\features\\cashier\\presentation\\widgets\\order_summary_panel.dart:128:36 - Methods can't be invoked in constant expressions. - const_eval_method_invocation
  error - lib\\features\\cashier\\presentation\\widgets\\order_summary_panel.dart:178:28 - Undefined name 'context'. Try correcting the name to one that is defined, or defining the name. - undefined_identifier
  error - lib\\features\\cashier\\presentation\\widgets\\order_summary_panel.dart:179:28 - Undefined name 'context'. Try correcting the name to one that is defined, or defining the name. - undefined_identifier
  error - lib\\features\\cashier\\presentation\\widgets\\order_summary_panel.dart:190:34 - Undefined name 'context'. Try correcting the name to one that is defined, or defining the name. - undefined_identifier
  error - lib\\features\\cashier\\presentation\\widgets\\order_summary_panel.dart:191:34 - Undefined name 'context'. Try correcting the name to one that is defined, or defining the name. - undefined_identifier
"""
    # Just run dart analyze and parse its output.
    pass

import subprocess

result = subprocess.run(["dart", "analyze"], capture_output=True, text=True, cwd=r"c:\Users\tonton\Downloads\ny_kitchen_app", shell=True)
output = result.stdout

const_errors = re.findall(r"error - (.*?):(\d+):\d+ - Methods can't be invoked in constant expressions", output)
for file_path, line_str in const_errors:
    line_idx = int(line_str) - 1
    full_path = os.path.join(r"c:\Users\tonton\Downloads\ny_kitchen_app", file_path)
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        
        # trace back up to 5 lines to find 'const ' and remove it
        for i in range(line_idx, max(-1, line_idx - 15), -1):
            if "const " in lines[i]:
                lines[i] = lines[i].replace("const ", " ")
                break
        
        with open(full_path, "w", encoding="utf-8") as f:
            f.writelines(lines)

# Remove unused app_colors imports
unused_imports = re.findall(r"warning - (.*?):\d+:\d+ - Unused import: '.*?app_colors\.dart'", output)
for file_path in unused_imports:
    full_path = os.path.join(r"c:\Users\tonton\Downloads\ny_kitchen_app", file_path)
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        lines = [l for l in lines if "app_colors.dart" not in l]
        with open(full_path, "w", encoding="utf-8") as f:
            f.writelines(lines)

print("Fixes applied.")
