import re
import glob

def fix_helpers(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # Find functions returning Color that don't take BuildContext but use Theme.of(context)
    # e.g., Color _getStatusColor(String status) {
    # Replace with Color _getStatusColor(BuildContext context, String status) {
    
    # 1. apps/admin_app/lib/screens/guards_screen.dart
    content = content.replace("Color _getStatusColor(String status)", "Color _getStatusColor(BuildContext context, String status)")
    content = content.replace("_getStatusColor(guard.status)", "_getStatusColor(context, guard.status)")
    
    # 2. apps/admin_app/lib/screens/slot_detail_screen.dart
    content = content.replace("Color _getStatusColor()", "Color _getStatusColor(BuildContext context)")
    content = content.replace("_getStatusColor()", "_getStatusColor(context)")
    
    # 3. apps/admin_app/lib/screens/slot_list_screen.dart
    content = content.replace("Color _getStatusColor(String status)", "Color _getStatusColor(BuildContext context, String status)")
    content = content.replace("_getStatusColor(slot.status)", "_getStatusColor(context, slot.status)")
    
    # 4. apps/user_app/lib/screens/booking_detail_screen.dart
    content = content.replace("Color _getStatusColor(String status)", "Color _getStatusColor(BuildContext context, String status)")
    content = content.replace("_getStatusColor(booking.status)", "_getStatusColor(context, booking.status)")
    content = content.replace("_getStatusColor(booking['status'])", "_getStatusColor(context, booking['status'])")
    
    # 5. apps/user_app/lib/screens/booking_list_screen.dart
    content = content.replace("Color _getStatusColor(String status)", "Color _getStatusColor(BuildContext context, String status)")
    content = content.replace("_getStatusColor(booking.status)", "_getStatusColor(context, booking.status)")

    # premium_badge.dart
    content = content.replace("Color _getBadgeColor(String status)", "Color _getBadgeColor(BuildContext context, String status)")
    content = content.replace("_getBadgeColor(status)", "_getBadgeColor(context, status)")

    if original != content:
        with open(filepath, 'w') as f:
            f.write(content)
            
for file in glob.glob("**/*.dart", recursive=True):
    fix_helpers(file)

