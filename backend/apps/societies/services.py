import json
import math
from decimal import Decimal
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import ssl
import certifi

from django.conf import settings
from rest_framework.exceptions import ValidationError

from apps.bookings.services import get_available_slots

from .models import Society


def _to_float(value):
    if value is None:
        return None
    return float(value)


def _request_location_json(base_url, query_params):
    url = f"{base_url}?{urlencode(query_params)}"
    request = Request(
        url,
        headers={"User-Agent": settings.GEOCODING_USER_AGENT},
    )

    try:
        import urllib.error
        import logging
        context = ssl.create_default_context(cafile=certifi.where())
        with urlopen(request, timeout=settings.GEOCODING_TIMEOUT_SECONDS, context=context) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.URLError as e:
        logging.getLogger(__name__).error(f"Geocoding req failed: {e}")
        return None


def _format_location_result(raw_result, *, fallback_label=""):
    label = raw_result.get("display_name") or fallback_label
    title, separator, remainder = label.partition(",")
    subtitle = remainder.strip() if separator else ""
    address_details = raw_result.get("address") or {}
    address_line_parts = [
        address_details.get("house_number"),
        address_details.get("road"),
        address_details.get("neighbourhood"),
        address_details.get("suburb"),
    ]
    address_line = ", ".join(part for part in address_line_parts if part)

    city = (
        address_details.get("city")
        or address_details.get("town")
        or address_details.get("village")
        or address_details.get("municipality")
        or address_details.get("hamlet")
        or ""
    )
    state = address_details.get("state") or address_details.get("state_district") or ""
    pincode = address_details.get("postcode") or ""

    return {
        "place_id": str(raw_result.get("place_id", "")),
        "title": title.strip() or fallback_label,
        "subtitle": subtitle,
        "label": label,
        "address": address_line or label,
        "city": city,
        "state": state,
        "pincode": str(pincode),
        "latitude": float(raw_result["lat"]),
        "longitude": float(raw_result["lon"]),
    }


def autocomplete_destinations(query, *, limit=None):
    payload = _request_location_json(
        settings.GEOCODING_BASE_URL,
        {
            "q": query,
            "format": "jsonv2",
            "addressdetails": 1,
            "limit": limit or settings.LOCATION_AUTOCOMPLETE_LIMIT,
        },
    )

    if not payload:
        return []

    return [_format_location_result(result) for result in payload]


def reverse_geocode_destination(latitude, longitude):
    payload = _request_location_json(
        settings.REVERSE_GEOCODING_BASE_URL,
        {
            "lat": latitude,
            "lon": longitude,
            "format": "jsonv2",
            "zoom": 18,
        },
    )

    if not payload or payload.get("error"):
        raise ValidationError("Could not resolve that map location.")

    return _format_location_result(
        payload,
        fallback_label=f"{latitude:.6f}, {longitude:.6f}",
    )


def haversine_distance_km(lat1, lon1, lat2, lon2):
    radius_km = 6371.0

    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return radius_km * c


def search_societies_by_availability(
    *,
    destination_lat,
    destination_lng,
    destination_text="",
    destination_place_id="",
    start_time,
    end_time,
    vehicle_type,
    search_radius_km=None,
):
    radius_km = search_radius_km or settings.DEFAULT_SOCIETY_SEARCH_RADIUS_KM
    destination = {
        "place_id": destination_place_id,
        "label": destination_text or f"{destination_lat:.6f}, {destination_lng:.6f}",
        "latitude": destination_lat,
        "longitude": destination_lng,
    }

    societies = Society.objects.filter(
        is_active=True,
        latitude__isnull=False,
        longitude__isnull=False,
    )

    results = []
    for society in societies:
        distance_km = haversine_distance_km(
            destination_lat,
            destination_lng,
            _to_float(society.latitude),
            _to_float(society.longitude),
        )
        if distance_km > radius_km:
            continue

        valid_slots = get_available_slots(
            society_id=society.id,
            vehicle_type=vehicle_type,
            start_time=start_time,
            end_time=end_time,
        )
        if not valid_slots:
            continue

        cheapest_rate = min(Decimal(slot.hourly_rate) for slot in valid_slots)
        results.append(
            {
                "id": str(society.id),
                "name": society.name,
                "address": society.address,
                "city": society.city,
                "state": society.state,
                "pincode": society.pincode,
                "latitude": _to_float(society.latitude),
                "longitude": _to_float(society.longitude),
                "contact_email": society.contact_email,
                "contact_phone": society.contact_phone,
                "distance_km": round(distance_km, 2),
                "available_slots": len(valid_slots),
                "starting_hourly_rate": str(cheapest_rate),
                "vehicle_type": vehicle_type,
            }
        )

    results.sort(key=lambda item: item["distance_km"])
    return {
        "destination": destination,
        "search_radius_km": radius_km,
        "results": results,
    }
