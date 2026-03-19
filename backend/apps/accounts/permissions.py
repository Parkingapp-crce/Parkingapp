from rest_framework.permissions import BasePermission


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "super_admin"


class IsSocietyAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "society_admin"


class IsGuard(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "guard"


class IsSocietyAdminOfSlot(BasePermission):
    """Checks that the society admin belongs to the same society as the slot."""

    def has_object_permission(self, request, view, obj):
        if request.user.role != "society_admin":
            return False
        # obj can be a ParkingSlot or a Society
        society = getattr(obj, "society", obj)
        return request.user.society_id == society.id
