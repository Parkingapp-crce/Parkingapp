import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()
from apps.societies.models import ParkingSlot
from apps.societies.serializers import ParkingSlotSerializer
slot = ParkingSlot.objects.first()
print(ParkingSlotSerializer(slot).data)
