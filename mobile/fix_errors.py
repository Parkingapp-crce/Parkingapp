import re

def fix_file(path):
    with open(path, 'r') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        # Fix missing context in getter/function by using static colors or finding the surrounding widget
        if "Theme.of(context).colorScheme." in line:
            # If it's a global helper like `Color getStatusColor(String status) { return Theme.of(context).colorScheme.primary; }`
            # This is hard to regex fix generically, but let's check
            pass
            
        # Fix const errors
        lines[i] = re.sub(r"const\s+([A-Z]\w*\(.*Theme\.of\(context\))", r"\1", lines[i])
        lines[i] = re.sub(r"const\s+(EdgeInsets\..*Theme\.of\(context\))", r"\1", lines[i])
        lines[i] = re.sub(r"const\s+(BorderSide\s*\(.*Theme\.of\(context\))", r"\1", lines[i])

    with open(path, 'w') as f:
        f.writelines(lines)

import sys
for arg in sys.argv[1:]:
    fix_file(arg)
