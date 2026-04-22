from django.urls import path

from . import views

urlpatterns = [
    path("", views.SocietyListCreateView.as_view(), name="society-list-create"),
    path("public/", views.PublicSocietyListView.as_view(), name="society-public-list"),
    path(
        "destinations/autocomplete/",
        views.DestinationAutocompleteView.as_view(),
        name="destination-autocomplete",
    ),
    path(
        "destinations/reverse-geocode/",
        views.DestinationReverseGeocodeView.as_view(),
        name="destination-reverse-geocode",
    ),
    path("search/", views.SocietyAvailabilitySearchView.as_view(), name="society-search"),
    path("<uuid:pk>/", views.SocietyDetailView.as_view(), name="society-detail"),
    path("<uuid:society_id>/slots/", views.SlotListCreateView.as_view(), name="slot-list-create"),
    path(
        "<uuid:society_id>/slots/<uuid:pk>/",
        views.SlotUpdateView.as_view(),
        name="slot-update",
    ),
    path(
        "<uuid:society_id>/slots/<uuid:pk>/block/",
        views.SlotBlockView.as_view(),
        name="slot-block",
    ),
    path(
        "<uuid:society_id>/slots/<uuid:pk>/unblock/",
        views.SlotUnblockView.as_view(),
        name="slot-unblock",
    ),
    path(
        "<uuid:society_id>/slots/<uuid:pk>/availability/",
        views.SlotAvailabilityWindowListCreateView.as_view(),
        name="slot-availability",
    ),
]
