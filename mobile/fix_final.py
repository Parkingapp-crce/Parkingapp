import os
import glob

def fix_final(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Fix surfaceContainerHighestContainerLow/High errors
    content = content.replace("Theme.of(context).colorScheme.surfaceContainerHighestContainerLow", "Theme.of(context).colorScheme.surfaceContainerHighest")
    content = content.replace("Theme.of(context).colorScheme.surfaceContainerHighestContainerHigh", "Theme.of(context).colorScheme.surfaceContainerHighest")

    # Fix specific undefined context errors
    if "admin_app/lib/screens/guards_screen.dart" in filepath:
        content = content.replace("Theme.of(context).colorScheme.error;", "const Color(0xFFEF4444);")
        content = content.replace("Theme.of(context).colorScheme.onSurfaceVariant;", "const Color(0xFF64748B);")
    
    if "admin_app/lib/screens/slot_detail_screen.dart" in filepath:
        content = content.replace("Theme.of(context).colorScheme.error;", "const Color(0xFFEF4444);")
        content = content.replace("Theme.of(context).colorScheme.onSurfaceVariant;", "const Color(0xFF64748B);")
        
    if "admin_app/lib/screens/slot_list_screen.dart" in filepath:
        content = content.replace("Theme.of(context).colorScheme.error;", "const Color(0xFFEF4444);")
        content = content.replace("Theme.of(context).colorScheme.onSurfaceVariant;", "const Color(0xFF64748B);")
        
    if "user_app/lib/screens/booking_detail_screen.dart" in filepath:
        content = content.replace("Theme.of(context).colorScheme.error;", "const Color(0xFFEF4444);")
        content = content.replace("Theme.of(context).colorScheme.onSurfaceVariant;", "const Color(0xFF64748B);")

    if "user_app/lib/screens/booking_list_screen.dart" in filepath:
        content = content.replace("Theme.of(context).colorScheme.error;", "const Color(0xFFEF4444);")
        content = content.replace("Theme.of(context).colorScheme.onSurfaceVariant;", "const Color(0xFF64748B);")

    if "premium_badge.dart" in filepath:
        content = content.replace("Theme.of(context).colorScheme.error;", "const Color(0xFFEF4444);")
        content = content.replace("Theme.of(context).colorScheme.onSurfaceVariant;", "const Color(0xFF64748B);")

    with open(filepath, 'w') as f:
        f.write(content)

for file in glob.glob("**/*.dart", recursive=True):
    fix_final(file)

