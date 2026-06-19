import os
import re

mappings = {
    'AppColors.background': 'Theme.of(context).colorScheme.surface',
    'AppColors.surface': 'Theme.of(context).colorScheme.surfaceContainerHighest',
    'AppColors.textPrimary': 'Theme.of(context).colorScheme.onSurface',
    'AppColors.textSecondary': 'Theme.of(context).colorScheme.onSurfaceVariant',
    'AppColors.textDisabled': 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)',
    'AppColors.divider': 'Theme.of(context).colorScheme.outlineVariant',
    'AppColors.outline': 'Theme.of(context).colorScheme.outline',
    'AppColors.primaryLight': 'Theme.of(context).colorScheme.tertiary',
    'AppColors.primaryDark': 'Theme.of(context).colorScheme.primaryContainer',
    'AppColors.primary': 'Theme.of(context).colorScheme.primary',
    'AppColors.secondary': 'Theme.of(context).colorScheme.secondary',
    'AppColors.errorBg': 'Theme.of(context).colorScheme.errorContainer',
    'AppColors.error': 'Theme.of(context).colorScheme.error',
}

const_strips = [
    r"const\s+Icon\s*\(",
    r"const\s+TextStyle\s*\(",
    r"const\s+BorderSide\s*\(",
    r"const\s+Divider\s*\(",
    r"const\s+Color\s*\(",
]

def refactor_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    # First, do the direct mappings
    for k, v in mappings.items():
        content = content.replace(k, v)

    # Next, we need to strip `const ` if the line now contains `Theme.of(context)`
    # Since `const` can be far away on the same logical expression, we'll do line-by-line heuristic
    # or a regex approach.
    lines = content.split('\n')
    for i in range(len(lines)):
        if "Theme.of(context)" in lines[i]:
            for pattern in const_strips:
                lines[i] = re.sub(pattern, lambda m: m.group(0).replace('const ', ''), lines[i])
            # Also just strip 'const ' if it's broadly applying to a widget containing Theme
            lines[i] = re.sub(r"const\s+([A-Z]\w*\()", r"\1", lines[i])

    content = '\n'.join(lines)
    
    if original != content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Refactored: {filepath}")

for root, _, files in os.walk('.'):
    if 'build' in root or '.dart_tool' in root:
        continue
    for file in files:
        if file.endswith('.dart'):
            refactor_file(os.path.join(root, file))

print("Done.")
