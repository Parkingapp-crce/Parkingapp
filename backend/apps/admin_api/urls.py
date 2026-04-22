from django.urls import path

from . import views

urlpatterns = [
    path("dashboard/", views.AdminDashboardView.as_view(), name="admin-dashboard"),
    path(
        "societies/<uuid:society_id>/stats/",
        views.SocietyStatsView.as_view(),
        name="admin-society-stats",
    ),
]
