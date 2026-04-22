from django.urls import path

from . import views

urlpatterns = [
    path("dashboard/", views.AdminDashboardView.as_view(), name="admin-dashboard"),
    path(
        "society/dashboard/",
        views.SocietyAdminDashboardView.as_view(),
        name="society-admin-dashboard",
    ),
    path(
        "society/guards/",
        views.SocietyGuardListView.as_view(),
        name="society-guard-list",
    ),
    path(
        "society/guards/<uuid:guard_id>/approve/",
        views.SocietyGuardApproveView.as_view(),
        name="society-guard-approve",
    ),
    path(
        "society/guards/<uuid:guard_id>/reject/",
        views.SocietyGuardRejectView.as_view(),
        name="society-guard-reject",
    ),
    path(
        "societies/<uuid:society_id>/stats/",
        views.SocietyStatsView.as_view(),
        name="admin-society-stats",
    ),
]
