import os
import django

from apps.societies.models import Society, ParkingSlot

def run():
    # Remove previous societies
    Society.objects.filter(name__in=["Greenwood Heights", "Sunrise Valley"]).delete()
    print("Deleted previous dummy societies.")
    
    # Check if test society already exists, remove it
    Society.objects.filter(name="Payment Test Society").delete()

    # Create new dummy society at exact default coordinates
    s1 = Society.objects.create(
        name="Payment Test Society",
        address="Default Center, Mumbai",
        city="Mumbai",
        state="Maharashtra",
        pincode="400001",
        contact_email="test@payment.com",
        contact_phone="9999999999",
        latitude=19.0760,
        longitude=72.8777
    )
    print(f"Created society: {s1.name} at default map location.")
    
    # Add a parking slot to the society so it can be booked
    slot = ParkingSlot.objects.create(
        society=s1,
        slot_number="A-01",
        floor="1",
        slot_type="car",
        state="available",
        ownership_type="society",
        hourly_rate=50.00
    )
    print(f"Added parking slot {slot.slot_number} to {s1.name} with hourly rate ₹{slot.hourly_rate}.")

run()
