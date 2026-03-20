## ⚙️ Setup Instructions

### 🔹 1. Clone the repository

```
git clone <repo-url>
cd login
```

---

### 🔹 2. Backend Setup

```
cd backend_node
npm install
```

Create `.env` file:

```
copy .env.example .env   (Windows)
```

OR

```
cp .env.example .env     (Mac/Linux)
```

Add values:

```
DATABASE_URL=your_database_url
JWT_SECRET=your_secret_key
```

Run backend:

```
node server.js
```

---

### 🔹 3. Prisma Setup

```
npx prisma generate
npx prisma migrate deploy
```

---

### 🔹 4. Flutter Setup

```
cd ../park_app
flutter pub get
```

Run app:

```
flutter run
```

---

### ⚠️ Important

* Use `http://10.0.2.2:3000` for emulator
* Use your laptop IP for real device

---

## 📦 Required Tools

* Node.js (v18+ recommended)
* Flutter SDK
* Android Studio / Emulator
* Git
