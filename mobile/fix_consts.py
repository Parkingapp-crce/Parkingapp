import re
from collections import defaultdict

with open('analyze.log', 'r') as f:
    log_lines = f.readlines()

file_errors = defaultdict(list)

for line in log_lines:
    if "Methods can't be invoked in constant expressions" in line:
        # e.g., error • Methods can't be invoked in constant expressions • apps/admin_app/lib/screens/dashboard_screen.dart:232:32
        match = re.search(r"• ([\w\/\.]+):(\d+):\d+", line)
        if match:
            filepath = match.group(1)
            lineno = int(match.group(2))
            file_errors[filepath].append(lineno)

for filepath, lines_with_errors in file_errors.items():
    with open(filepath, 'r') as f:
        content_lines = f.readlines()
    
    # We want to trace back from the error line to find the nearest 'const ' and remove it.
    for error_line_idx in sorted([l - 1 for l in lines_with_errors], reverse=True):
        # Go backwards from the error line up to 10 lines
        for back_idx in range(error_line_idx, max(-1, error_line_idx - 15), -1):
            if "const " in content_lines[back_idx]:
                content_lines[back_idx] = content_lines[back_idx].replace("const ", "", 1)
                break
                
    with open(filepath, 'w') as f:
        f.writelines(content_lines)

print(f"Fixed const errors in {len(file_errors)} files.")
