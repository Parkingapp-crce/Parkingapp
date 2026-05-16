from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import Vehicle
from apps.societies.models import ParkingSlot, Society


class Command(BaseCommand):
    help = "Create or reset demo users for all app roles."

    TOTAL_SOCIETIES = 2000

    def _society_seed_rows(self):
        localities = [
            ("Colaba", 18.9067, 72.8147, "400005"),
            ("Cuffe Parade", 18.9152, 72.8218, "400005"),
            ("Nariman Point", 18.9250, 72.8238, "400021"),
            ("Marine Lines", 18.9432, 72.8234, "400020"),
            ("Girgaon", 18.9543, 72.8176, "400004"),
            ("Grant Road", 18.9640, 72.8185, "400007"),
            ("Mumbai Central", 18.9695, 72.8193, "400008"),
            ("Tardeo", 18.9726, 72.8141, "400034"),
            ("Byculla", 18.9767, 72.8331, "400027"),
            ("Parel", 18.9967, 72.8406, "400012"),
            ("Lower Parel", 18.9944, 72.8258, "400013"),
            ("Worli", 19.0178, 72.8162, "400018"),
            ("Prabhadevi", 19.0166, 72.8295, "400025"),
            ("Dadar West", 19.0180, 72.8419, "400028"),
            ("Dadar East", 19.0158, 72.8494, "400014"),
            ("Matunga", 19.0274, 72.8554, "400019"),
            ("Mahim", 19.0402, 72.8402, "400016"),
            ("Sion", 19.0464, 72.8615, "400022"),
            ("Wadala", 19.0179, 72.8562, "400031"),
            ("Antop Hill", 19.0296, 72.8673, "400037"),
            ("Kurla", 19.0728, 72.8826, "400070"),
            ("Dharavi", 19.0402, 72.8544, "400017"),
            ("Bandra West", 19.0596, 72.8295, "400050"),
            ("Bandra East", 19.0608, 72.8409, "400051"),
            ("Khar", 19.0722, 72.8355, "400052"),
            ("Santacruz West", 19.0793, 72.8410, "400054"),
            ("Santacruz East", 19.0790, 72.8610, "400055"),
            ("Vile Parle West", 19.1007, 72.8397, "400056"),
            ("Vile Parle East", 19.0985, 72.8547, "400057"),
            ("Andheri West", 19.1365, 72.8290, "400058"),
            ("Andheri East", 19.1136, 72.8697, "400069"),
            ("Jogeshwari West", 19.1367, 72.8420, "400102"),
            ("Jogeshwari East", 19.1316, 72.8605, "400060"),
            ("Goregaon West", 19.1551, 72.8347, "400104"),
            ("Goregaon East", 19.1647, 72.8606, "400063"),
            ("Malad West", 19.1871, 72.8372, "400064"),
            ("Malad East", 19.1865, 72.8606, "400097"),
            ("Kandivali West", 19.2045, 72.8401, "400067"),
            ("Kandivali East", 19.2057, 72.8629, "400101"),
            ("Borivali West", 19.2320, 72.8411, "400092"),
            ("Borivali East", 19.2307, 72.8598, "400066"),
            ("IC Colony", 19.2475, 72.8424, "400103"),
            ("Dahisar East", 19.2570, 72.8652, "400068"),
            ("Dahisar West", 19.2492, 72.8526, "400068"),
            ("Powai", 19.1176, 72.9060, "400076"),
            ("Chandivali", 19.1119, 72.8946, "400072"),
            ("Saki Naka", 19.1026, 72.8897, "400072"),
            ("Ghatkopar West", 19.0929, 72.9050, "400086"),
            ("Ghatkopar East", 19.0815, 72.9081, "400077"),
            ("Vikhroli", 19.1071, 72.9260, "400079"),
            ("Kanjurmarg", 19.1314, 72.9350, "400042"),
            ("Bhandup", 19.1457, 72.9390, "400078"),
            ("Mulund West", 19.1726, 72.9563, "400080"),
            ("Mulund East", 19.1715, 72.9633, "400081"),
            ("Chembur", 19.0522, 72.9005, "400071"),
            ("Deonar", 19.0433, 72.9231, "400088"),
            ("Govandi", 19.0587, 72.9169, "400043"),
            ("Mankhurd", 19.0483, 72.9314, "400088"),
            ("Trombay", 19.0000, 72.9429, "400088"),
            ("Sewri", 18.9988, 72.8590, "400015"),
            ("Worli Sea Face", 19.0094, 72.8151, "400030"),
        ]

        rows = []
        for i in range(self.TOTAL_SOCIETIES):
            area, base_lat, base_lng, area_pincode = localities[i % len(localities)]
            cluster = i // len(localities)
            lat_offset = ((cluster % 9) - 4) * 0.0016
            lng_offset = (((cluster // 9) % 9) - 4) * 0.0018
            micro_lat = ((i % 5) - 2) * 0.00035
            micro_lng = (((i // 5) % 5) - 2) * 0.00035

            latitude = round(base_lat + lat_offset + micro_lat, 6)
            longitude = round(base_lng + lng_offset + micro_lng, 6)

            rows.append(
                {
                    "name": f"Demo Society {i + 1:04} - {area}",
                    "address": f"{area}, Sector {(i % 22) + 1}, Plot {(i % 41) + 1}",
                    "city": "Mumbai",
                    "state": "Maharashtra",
                    "pincode": area_pincode,
                    "latitude": latitude,
                    "longitude": longitude,
                    "contact_email": f"support{i + 1:04}@parkwise.demo",
                    "contact_phone": f"+919700{i + 1:06}",
                }
            )

        return rows

    def _admin_email_for_index(self, index):
        if index == 0:
            return "admin@parking.com"
        if index == 1:
            return "admin2@parking.com"
        if index == 2:
            return "admin3@parking.com"
        return f"admin{index + 1:03}@parking.com"

    def _set_user_fields(self, user, item, encoded_password):
        user.full_name = item["full_name"]
        user.phone = item["phone"]
        user.role = item["role"]
        user.society = item["society"]
        user.is_active = True
        user.is_staff = item["role"] == "super_admin"
        user.is_superuser = item["role"] == "super_admin"
        user.password = encoded_password
        user.save(
            update_fields=[
                "full_name",
                "phone",
                "role",
                "society",
                "is_active",
                "is_staff",
                "is_superuser",
                "password",
            ]
        )

    def add_arguments(self, parser):
        parser.add_argument(
            "--password",
            default="Password@123",
            help="Password to set for all demo users (default: Password@123)",
        )

    def handle(self, *args, **options):
        password = options["password"]
        user_model = get_user_model()
        encoded_password = make_password(password)

        with transaction.atomic():
            Society.objects.filter(name__startswith="Demo Society ").update(is_active=False)
            Society.objects.exclude(name__startswith="Demo Society ").update(is_active=False)

            society_seed = self._society_seed_rows()

            societies = []
            for index, row in enumerate(society_seed):
                society, _ = Society.objects.get_or_create(
                    name=row["name"],
                    defaults={
                        "address": row["address"],
                        "city": row["city"],
                        "state": row["state"],
                        "pincode": row["pincode"],
                        "latitude": row["latitude"],
                        "longitude": row["longitude"],
                        "contact_email": row["contact_email"],
                        "contact_phone": row["contact_phone"],
                        "is_active": True,
                    },
                )

                society.address = row["address"]
                society.city = row["city"]
                society.state = row["state"]
                society.pincode = row["pincode"]
                society.latitude = row["latitude"]
                society.longitude = row["longitude"]
                society.contact_email = row["contact_email"]
                society.contact_phone = row["contact_phone"]
                society.is_active = True
                society.save()
                societies.append(society)

            demo_users = [
                {
                    "email": "user@parking.com",
                    "full_name": "Demo Resident One",
                    "phone": "+919999900001",
                    "role": "user",
                    "society": societies[0],
                },
                {
                    "email": "user2@parking.com",
                    "full_name": "Demo Resident Two",
                    "phone": "+919999900002",
                    "role": "user",
                    "society": societies[1],
                },
                {
                    "email": "user3@parking.com",
                    "full_name": "Demo Resident Three",
                    "phone": "+919999900003",
                    "role": "user",
                    "society": societies[2],
                },
                {
                    "email": "guard@parking.com",
                    "full_name": "Demo Guard One",
                    "phone": "+919999900201",
                    "role": "guard",
                    "society": societies[0],
                },
                {
                    "email": "guard2@parking.com",
                    "full_name": "Demo Guard Two",
                    "phone": "+919999900202",
                    "role": "guard",
                    "society": societies[1],
                },
                {
                    "email": "superadmin@parking.com",
                    "full_name": "Demo Super Admin",
                    "phone": "+919999900301",
                    "role": "super_admin",
                    "society": None,
                },
            ]

            for index, society in enumerate(societies):
                demo_users.append(
                    {
                        "email": self._admin_email_for_index(index),
                        "full_name": f"Society Owner Admin {index + 1:03}",
                        "phone": f"+919810{index + 1:06}",
                        "role": "society_admin",
                        "society": society,
                    }
                )

            for index in range(min(50, len(societies))):
                demo_users.append(
                    {
                        "email": f"guard{index + 3:03}@parking.com",
                        "full_name": f"Society Guard {index + 3:03}",
                        "phone": f"+919820{index + 1:06}",
                        "role": "guard",
                        "society": societies[index],
                    }
                )

            users_by_email = {}
            created_count = 0
            updated_count = 0
            for item in demo_users:
                user, created = user_model.objects.get_or_create(
                    email=item["email"],
                    defaults={
                        "full_name": item["full_name"],
                        "phone": item["phone"],
                        "role": item["role"],
                        "society": item["society"],
                    },
                )

                self._set_user_fields(user, item, encoded_password)
                users_by_email[item["email"]] = user

                if created:
                    created_count += 1
                else:
                    updated_count += 1

            for index, society in enumerate(societies):
                area_prefix = society.name.split()[-1][:3].upper()
                resident_owner = None
                if index == 0:
                    resident_owner = users_by_email.get("user@parking.com")
                elif index == 1:
                    resident_owner = users_by_email.get("user2@parking.com")
                elif index == 2:
                    resident_owner = users_by_email.get("user3@parking.com")

                demo_slots = [
                    (f"{area_prefix}-A1", "car", "society", "120.00", "P1", None),
                    (f"{area_prefix}-A2", "car", "society", "100.00", "P1", None),
                    (f"{area_prefix}-B1", "bike", "society", "60.00", "P2", None),
                    (f"{area_prefix}-C1", "car", "resident", "90.00", "P2", resident_owner),
                    (f"{area_prefix}-C2", "bike", "society", "55.00", "P3", None),
                    (f"{area_prefix}-D1", "car", "society", "110.00", "P3", None),
                ]

                for slot_number, slot_type, ownership_type, hourly_rate, floor, owner in demo_slots:
                    slot, _ = ParkingSlot.objects.get_or_create(
                        society=society,
                        slot_number=slot_number,
                        defaults={
                            "slot_type": slot_type,
                            "ownership_type": ownership_type,
                            "hourly_rate": hourly_rate,
                            "floor": floor,
                            "owner": owner,
                            "state": ParkingSlot.SlotState.AVAILABLE,
                            "is_active": True,
                        },
                    )
                    slot.slot_type = slot_type
                    slot.ownership_type = ownership_type
                    slot.hourly_rate = hourly_rate
                    slot.floor = floor
                    slot.owner = owner
                    slot.state = ParkingSlot.SlotState.AVAILABLE
                    slot.is_active = True
                    slot.save()

            demo_vehicles = [
                ("user@parking.com", "MH01DEMO1234", "Demo Hatchback"),
                ("user2@parking.com", "MH01DEMO2345", "Demo Sedan"),
                ("user3@parking.com", "MH01DEMO3456", "Demo Scooter"),
            ]

            for email, registration_no, make_model in demo_vehicles:
                demo_user = users_by_email.get(email)
                if not demo_user:
                    continue

                vehicle_type = (
                    Vehicle.VehicleType.BIKE
                    if "Scooter" in make_model
                    else Vehicle.VehicleType.CAR
                )
                vehicle, _ = Vehicle.objects.get_or_create(
                    user=demo_user,
                    registration_no=registration_no,
                    defaults={
                        "vehicle_type": vehicle_type,
                        "make_model": make_model,
                        "is_active": True,
                    },
                )
                vehicle.vehicle_type = vehicle_type
                vehicle.make_model = make_model
                vehicle.is_active = True
                vehicle.save()

        self.stdout.write(
            self.style.SUCCESS(
                f"Demo users are ready. Created={created_count}, Updated={updated_count}, "
                f"Societies={self.TOTAL_SOCIETIES}"
            )
        )
