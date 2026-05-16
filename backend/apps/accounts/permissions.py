from django.contrib.auth import get_user_model
from rest_framework.permissions import BasePermission

User = get_user_model()


def _guard_has_scan_access(request, access_field):
    user = request.user
    if not user.is_authenticated:
        return False

    return User.objects.filter(
        id=user.id,
        role=User.Role.GUARD,
        **{access_field: True},
    ).exists()


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "super_admin"


class IsSocietyAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "society_admin"


class IsGuard(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "guard"


class CanScanEntry(BasePermission):
    def has_permission(self, request, view):
        return _guard_has_scan_access(request, "can_scan_entry")


class CanScanExit(BasePermission):
    def has_permission(self, request, view):
        return _guard_has_scan_access(request, "can_scan_exit")


class IsSocietyAdminOfSlot(BasePermission):
    """Checks that the society admin belongs to the same society as the slot."""

    def has_object_permission(self, request, view, obj):
        if request.user.role != "society_admin":
            return False
        # obj can be a ParkingSlot or a Society
        society = getattr(obj, "society", obj)
        return request.user.society_id == society.id
