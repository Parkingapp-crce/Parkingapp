from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import Vehicle
from apps.societies.models import ParkingSlot, Society


class Command(BaseCommand):
    help = "Fast bulk seeder for 2000 Mumbai societies with owner admins and slots."

    TOTAL = 2000

    LOCALITIES = [
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
    ]

    @staticmethod
    def admin_email(index):
        if index == 0:
            return "admin@parking.com"
        if index == 1:
            return "admin2@parking.com"
        if index == 2:
            return "admin3@parking.com"
        return f"admin{index + 1:04}@parking.com"

    def handle(self, *args, **options):
        user_model = get_user_model()
        encoded_password = make_password("Password@123")

        with transaction.atomic():
            Society.objects.exclude(name__startswith="Demo Society ").update(is_active=False)
            Society.objects.filter(name__startswith="Demo Society ").delete()

            societies = []
            for i in range(self.TOTAL):
                area, base_lat, base_lng, pincode = self.LOCALITIES[i % len(self.LOCALITIES)]
                cluster = i // len(self.LOCALITIES)
                lat_offset = ((cluster % 9) - 4) * 0.0016
                lng_offset = (((cluster // 9) % 9) - 4) * 0.0018
                micro_lat = ((i % 5) - 2) * 0.00035
                micro_lng = (((i // 5) % 5) - 2) * 0.00035
                societies.append(
                    Society(
                        name=f"Demo Society {i + 1:04} - {area}",
                        address=f"{area}, Sector {(i % 22) + 1}, Plot {(i % 41) + 1}",
                        city="Mumbai",
                        state="Maharashtra",
                        pincode=pincode,
                        latitude=round(base_lat + lat_offset + micro_lat, 6),
                        longitude=round(base_lng + lng_offset + micro_lng, 6),
                        contact_email=f"support{i + 1:04}@parkwise.demo",
                        contact_phone=f"+919700{i + 1:06}",
                        is_active=True,
                    )
                )
            Society.objects.bulk_create(societies, batch_size=500)

            societies = list(
                Society.objects.filter(name__startswith="Demo Society ", is_active=True).order_by("name")
            )

            base_users = [
                ("user@parking.com", "Demo Resident One", "+919999900001", societies[0], "user"),
                ("user2@parking.com", "Demo Resident Two", "+919999900002", societies[1], "user"),
                ("user3@parking.com", "Demo Resident Three", "+919999900003", societies[2], "user"),
                ("guard@parking.com", "Demo Guard One", "+919999900201", societies[0], "guard"),
                ("guard2@parking.com", "Demo Guard Two", "+919999900202", societies[1], "guard"),
                ("superadmin@parking.com", "Demo Super Admin", "+919999900301", None, "super_admin"),
            ]

            for email, full_name, phone, society, role in base_users:
                user, _ = user_model.objects.get_or_create(
                    email=email,
                    defaults={
                        "full_name": full_name,
                        "phone": phone,
                        "role": role,
                    },
                )
                user.full_name = full_name
                user.phone = phone
                user.role = role
                user.society = society
                user.is_active = True
                user.is_staff = role == "super_admin"
                user.is_superuser = role == "super_admin"
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

            existing_admins = {
                user.email: user
                for user in user_model.objects.filter(email__iendswith="@parking.com")
            }
            used_phones = set(
                phone
                for phone in user_model.objects.values_list("phone", flat=True)
                if phone
            )

            def next_unique_phone(seed_index):
                candidate = 7710000000 + seed_index
                while True:
                    phone = f"+91{candidate}"
                    if phone not in used_phones:
                        used_phones.add(phone)
                        return phone
                    candidate += 1

            create_admins = []
            update_admins = []
            for i, society in enumerate(societies):
                email = self.admin_email(i)
                full_name = f"Society Owner Admin {i + 1:04}"
                existing = existing_admins.get(email)

                if existing is None:
                    create_admins.append(
                        user_model(
                            email=email,
                            full_name=full_name,
                            phone=next_unique_phone(i),
                            role="society_admin",
                            society=society,
                            is_active=True,
                            is_staff=False,
                            is_superuser=False,
                            password=encoded_password,
                        )
                    )
                else:
                    existing.full_name = full_name
                    existing.role = "society_admin"
                    existing.society = society
                    existing.is_active = True
                    existing.is_staff = False
                    existing.is_superuser = False
                    existing.password = encoded_password
                    update_admins.append(existing)

            if create_admins:
                user_model.objects.bulk_create(create_admins, batch_size=500)
            if update_admins:
                user_model.objects.bulk_update(
                    update_admins,
                    [
                        "full_name",
                        "role",
                        "society",
                        "is_active",
                        "is_staff",
                        "is_superuser",
                        "password",
                    ],
                    batch_size=500,
                )

            user1 = user_model.objects.get(email="user@parking.com")
            user2 = user_model.objects.get(email="user2@parking.com")
            user3 = user_model.objects.get(email="user3@parking.com")

            ParkingSlot.objects.filter(society__name__startswith="Demo Society ").delete()

            slots = []
            for i, society in enumerate(societies):
                code = f"{i + 1:04}"
                owner = user1 if i == 0 else user2 if i == 1 else user3 if i == 2 else None
                slots.append(
                    ParkingSlot(
                        society=society,
                        slot_number=f"{code}-A1",
                        floor="P1",
                        slot_type="car",
                        state="available",
                        ownership_type="society",
                        owner=None,
                        hourly_rate="120.00",
                        is_active=True,
                    )
                )
                slots.append(
                    ParkingSlot(
                        society=society,
                        slot_number=f"{code}-B1",
                        floor="P2",
                        slot_type="bike",
                        state="available",
                        ownership_type="society",
                        owner=None,
                        hourly_rate="60.00",
                        is_active=True,
                    )
                )
                slots.append(
                    ParkingSlot(
                        society=society,
                        slot_number=f"{code}-C1",
                        floor="P3",
                        slot_type="car",
                        state="available",
                        ownership_type="resident",
                        owner=owner,
                        hourly_rate="90.00",
                        is_active=True,
                    )
                )

            ParkingSlot.objects.bulk_create(slots, batch_size=1000)

            vehicles = [
                ("user@parking.com", "MH01DEMO1234", "Demo Hatchback", "car"),
                ("user2@parking.com", "MH01DEMO2345", "Demo Sedan", "car"),
                ("user3@parking.com", "MH01DEMO3456", "Demo Scooter", "bike"),
            ]
            for email, registration_no, make_model, vehicle_type in vehicles:
                user = user_model.objects.get(email=email)
                vehicle, _ = Vehicle.objects.get_or_create(
                    user=user,
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
                vehicle.save(update_fields=["vehicle_type", "make_model", "is_active"])

        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded Mumbai dataset: societies={self.TOTAL}, admins={self.TOTAL}, slots={self.TOTAL * 3}"
            )
        )
