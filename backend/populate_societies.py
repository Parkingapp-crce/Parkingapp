import os
import django
import sys

from apps.societies.models import Society

def populate():
    if Society.objects.filter(name="Greenwood Heights").exists():
        print("Societies already exist.")
        return

    s1 = Society.objects.create(
        name="Greenwood Heights",
        address="123 Park Avenue, Downtown",
        city="Mumbai",
        state="Maharashtra",
        pincode="400001",
        contact_email="admin@greenwood.com",
        contact_phone="9876543210",
        latitude=18.9220,
        longitude=72.8347
    )
    
    s2 = Society.objects.create(
        name="Sunrise Valley",
        address="456 Link Road, Andheri West",
        city="Mumbai",
        state="Maharashtra",
        pincode="400053",
        contact_email="contact@sunrisevalley.com",
        contact_phone="9876543211",
        latitude=19.1363,
        longitude=72.8277
    )
    
    print(f"Created society: {s1.name} (Code: {s1.join_code})")
    print(f"Created society: {s2.name} (Code: {s2.join_code})")

populate()
