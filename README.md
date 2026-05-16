# 🅿️ ParkWise — Smart Parking App

A full-stack parking management app built with **Flutter** (frontend) and **Django** (backend), connected to **Supabase PostgreSQL**.

---

## 🧱 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter |
| Backend | Django + Django REST Framework |
| Auth | JWT (SimpleJWT) |
| Database | Supabase PostgreSQL |

---

## ⚙️ Setup Instructions

### 🔹 1. Clone the repository
```
git clone <repo-url>
cd Parkingapp
```

---

### 🔹 2. Backend Setup
```
cd parkwise_backend
```

Create and activate virtual environment:
```
python -m venv venv

venv\Scripts\activate        (Windows)
source venv/bin/activate     (Mac/Linux)
```

Install dependencies:
```
pip install -r requirements.txt
```

Create `.env` file:
```
copy .env.example .env       (Windows)
cp .env.example .env         (Mac/Linux)
```

Add your Supabase values to `.env`:
```
DJANGO_SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2

DB_NAME=postgres
DB_USER=postgres.your-project-ref
DB_PASSWORD=your-supabase-password
DB_HOST=aws-0-ap-south-1.pooler.supabase.com
DB_PORT=5432
```

Run migrations:
```
python manage.py migrate
```

Start backend:
```
python manage.py runserver
```

Backend runs at: `http://127.0.0.1:8000`

---

### 🔹 3. Flutter Setup
```
cd park_app
flutter pub get
```

Run app:
```
flutter run
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/register` | Register new user | ❌ |
| POST | `/login` | Login + get JWT token | ❌ |
| GET | `/profile` | Get user profile | ✅ Bearer token |

---

## ⚠️ Important

- Use `http://10.0.2.2:8000` for Android emulator
- Use `http://localhost:8000` for Flutter web
- Use your laptop's local IP for real device (e.g. `http://192.168.1.x:8000`)
- Never commit your `.env` file — it's in `.gitignore` ✅

---

## ✅ Demo Login Setup (mobile/apps/*)

For the new app family under `mobile/apps/*`, use the `backend/` service with `/api/v1/*` endpoints.

From `backend/`, create/reset demo users:

```
python manage.py seed_demo_users
```

Default password for all demo users:

```
Password@123
```

Demo accounts:

- `user@parking.com` (user app)
- `user2@parking.com` (user app)
- `user3@parking.com` (user app)
- `admin@parking.com` (admin app)
- `admin2@parking.com` (admin app)
- `admin3@parking.com` (admin app)
- `guard@parking.com` (guard app)
- `guard2@parking.com` (guard app)
- `superadmin@parking.com` (super admin app)

---

## 📦 Required Tools

- Python 3.10+
- Flutter SDK
- Android Studio / Emulator
- Git