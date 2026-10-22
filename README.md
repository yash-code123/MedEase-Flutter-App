# 🏥 MedEase

### *One hospital. Three roles. One app in your pocket.*

**MedEase** is a cross-platform **hospital management mobile app** built with **Flutter** and **Dart**. A single codebase serves **Patients, Doctors and Admins**, and it runs against a live REST backend shared with the MedEase website.

`Flutter` · `Dart 3.3+` · `Material 3` · `Provider` · `Dio` · `JWT Auth` · `MySQL (via REST)` · `Android Studio`

---

## 📑 Table of Contents

1. [Why MedEase?](#-why-medease)
2. [At a Glance](#-at-a-glance)
3. [Features by Role](#-features-by-role)
4. [How It Works](#-how-it-works)
5. [Tech Stack](#-tech-stack)
6. [Architecture](#-architecture)
7. [Security](#-security)
8. [API Overview](#-api-overview)
9. [Getting Started in Android Studio](#-getting-started-in-android-studio)
10. [Demo Accounts](#-demo-accounts)
11. [Presenter's Demo Script](#-presenters-demo-script)
12. [Building an APK](#-building-an-apk)
13. [Troubleshooting](#-troubleshooting)
14. [Roadmap](#-roadmap)
15. [Author](#-author)

---

## 💡 Why MedEase?

Small and mid-sized hospitals often run on paper registers, phone calls and scattered spreadsheets. That means long waiting-room queues, lost prescriptions, unclear bed availability and manual billing.

MedEase puts the whole patient journey in one app:

| Problem | MedEase's answer |
|---|---|
| Patients wait without knowing their turn | Digital **queue tokens** issued right after booking and payment |
| Appointment booking needs a phone call | **4-step in-app booking** with UPI QR payment |
| Prescriptions and reports get lost | **My Records**: everything in one timeline |
| Doctors lose time on paperwork | Single **consultation screen**: vitals, prescription and lab order together |
| Admins can't see the hospital's state | **Live dashboard**, bed map, pharmacy alerts, analytics |
| Web and mobile data drift apart | **Same backend, same database** as the website |

---

## 📊 At a Glance

| | |
|---|---|
| 👥 **User roles** | 3 (Patient, Doctor, Admin) |
| 📱 **Screens** | 22 |
| 🧩 **Data models** | 10 |
| 🔌 **Service classes** | 12 |
| 🛏️ **Ward capacity managed** | 30 beds |
| 📈 **Dashboard stat cards** | 8 |
| 💻 **Code size** | 5,000+ lines of Dart |
| 🔁 **Backend** | Shared REST API + MySQL, no separate mobile API |

---

## ✨ Features by Role

### 🧑‍⚕️ Patient

| Feature | What it does |
|---|---|
| **Sign up and login** | Self-registration and secure JWT login |
| **Home dashboard** | Quick view of upcoming appointments and activity |
| **Book appointment** | 4 steps: Department → Doctor → Time slot → Pay |
| **UPI QR payment** | QR code generated in-app to confirm the booking |
| **My Records** | Appointments, bills, prescriptions, lab results and a medical timeline |
| **Health Assistant** | Offline, rule-based chatbot for appointments, bills, tokens, labs and emergencies |
| **Profile** | View details and sign out |

### 👨‍⚕️ Doctor

| Feature | What it does |
|---|---|
| **Live queue** | See waiting patients and tap **Call Next Patient** |
| **Consultation** | Record vitals with **auto-calculated BMI**, write a prescription, order lab tests |
| **Patient history** | Review a patient's past visits before consulting |
| **Profile** | View details and sign out |

### 🛠️ Admin

| Feature | What it does |
|---|---|
| **Dashboard** | 8 live stat cards: patients, doctors, appointments, revenue (₹), vacant beds, low stock, bills, active doctors |
| **Manage doctors** | Add doctors; a login is **auto-created** for each |
| **Manage patients** | View and maintain patient records |
| **Queue and tokens** | Monitor and update token status |
| **Bed management** | Track a **30-bed ward** (vacant vs occupied) |
| **Pharmacy** | Medicine inventory with **low-stock alerts** |
| **Billing** | Overview of all bills and revenue |
| **Analytics** | Revenue trend (line chart) and department-wise chart (bar chart) |
| **Manual booking** | Book appointments on behalf of walk-in patients |

---

## 🔄 How It Works

### Patient journey

```text
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 1. Login or  │───▶│ 2. Choose    │───▶│ 3. Pick      │───▶│ 4. Select    │
  │    Sign up   │    │  Department  │    │    Doctor    │    │    Slot      │
  └──────────────┘    └──────────────┘    └──────────────┘    └──────┬───────┘
                                                                     │
                                                                     ▼
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 8. View in   │◀───│ 7. Prescribe │◀───│ 6. Doctor    │◀───│ 5. Pay via   │
  │  My Records  │    │  + Lab Order │    │   Consults   │    │  UPI QR      │
  └──────────────┘    └──────────────┘    └──────────────┘    └──────┬───────┘
                                                                     │
                                                       Queue token issued instantly
```

### System overview

```text
 ┌──────────────────────────────────┐        ┌──────────────────────────┐
 │       MedEase Flutter App        │        │     MedEase Website      │
 │                                  │        │                          │
 │   Screens ──▶ AuthProvider       │        │      Web Frontend        │
 │      │                           │        │                          │
 │      ▼                           │        └────────────┬─────────────┘
 │   Service Layer                  │                     │
 │      │                           │                     │
 │      ▼                           │                     │
 │   Dio + JWT Interceptor ◀─ token ─ Secure Storage      │
 └──────────────┬───────────────────┘                     │
                │                                         │
                └─────────────────┬───────────────────────┘
                                  ▼
                    ┌───────────────────────────┐
                    │  REST API  (Render)       │
                    └─────────────┬─────────────┘
                                  ▼
                    ┌───────────────────────────┐
                    │  MySQL Database           │
                    └───────────────────────────┘
```

Both the app and the website use the same API and database, so a booking made on either appears on both instantly.

---

## 🧰 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Framework** | Flutter, Dart | Cross-platform UI |
| **Design** | Material 3, Google Fonts (DM Sans, DM Serif Display) | Consistent, modern look |
| **State** | `provider` | App-wide auth state |
| **Networking** | `dio` | HTTP client with interceptors |
| **Security** | `flutter_secure_storage` | Encrypted JWT storage |
| **Caching** | `shared_preferences` | Lightweight local data |
| **Charts** | `fl_chart` | Revenue and department analytics |
| **Payments** | `qr_flutter` | UPI QR code generation |
| **Documents** | `pdf`, `printing`, `path_provider` | Printable bills and prescriptions (integrated, ready to wire up) |
| **Utilities** | `intl`, `dropdown_button2` | Dates, currency, dropdowns |
| **Backend** | REST API on Render, MySQL | Shared with the website |

---

## 🏗️ Architecture

```
lib/
├── main.dart                  # Entry point: MultiProvider + Material 3 theme
│
├── config/
│   ├── api_config.dart        # Base URL (overridable) + endpoint constants
│   └── theme.dart             # Brand colours and typography tokens
│
├── models/                    # Plain Dart classes mirroring backend models
│   ├── user.dart  patient.dart  doctor.dart
│   ├── appointment.dart  token_model.dart
│   ├── prescription.dart  lab_order.dart
│   └── bill.dart  bed.dart  medicine_stock.dart
│
├── services/                  # One class per resource, wrapping Dio calls
│   ├── api_client.dart        # Dio + JWT interceptor + 401 auto-logout
│   └── auth · patient · doctor · appointment · token
│       prescription · lab · billing · pharmacy · bed · chatbot
│
├── providers/
│   └── auth_provider.dart     # Login state shared across the whole app
│
├── widgets/                   # Reusable UI building blocks
│   └── stat_card · status_badge · empty_state · loading_view · section_header
│
└── screens/
    ├── splash_screen.dart
    ├── auth/      login · signup
    ├── patient/   shell · home · book appointment · my records · chatbot
    ├── doctor/    shell · home (queue) · consultation · patient history
    ├── admin/     home · doctors · patients · queue · beds
    │              analytics · pharmacy · billing · manual booking
    └── shared/    profile
```

### Key design decisions

- **Role-based navigation.** After login each role lands in its own shell (`PatientShell`, `DoctorShell`, `AdminHome`) with tailored bottom navigation.
- **Service layer.** Screens never call Dio directly; every backend resource has its own service class, which keeps UI code clean and testable.
- **Right-sized state management.** One top-level `AuthProvider`. Most screens are read-then-act, so each uses a local `FutureBuilder` instead of a heavy global store.
- **Design tokens.** Colours live in `MedEaseColors`, with a distinct accent per role (🟢 Patient teal · 🔵 Doctor blue · 🟣 Admin purple). Restyle the whole app from one file.
- **Offline-capable chatbot.** The Health Assistant uses keyword rules with no external API, so it works even when the backend is asleep.

---

## 🔐 Security

| Concern | How it's handled |
|---|---|
| **Authentication** | JWT-based login |
| **Token storage** | `flutter_secure_storage` (never plain `SharedPreferences`) |
| **Request auth** | A single Dio interceptor attaches the token to every request |
| **Session expiry** | A `401` response triggers automatic logout |
| **Role separation** | Each role sees only its own screens and actions |

---

## 🔌 API Overview

Base URL: `https://medease-patient-and-finance-system.onrender.com/api/`

| Resource | Endpoint | Used by |
|---|---|---|
| Auth | `auth/login`, `auth/signup` | All roles |
| Patients | `patients` | Admin, Doctor |
| Doctors | `doctors` | Patient, Admin |
| Appointments | `appointments`, `appointments/:id/status` | Patient, Admin |
| Tokens (queue) | `tokens`, `tokens/:id/status` | Doctor, Admin |
| Prescriptions | `prescriptions` | Doctor, Patient |
| Lab | `lab`, `lab/:id/result` | Doctor, Patient |
| Billing | `billing` | Patient, Admin |
| Pharmacy | `pharmacy`, `pharmacy/:id` | Admin |
| Beds | `beds`, `beds/:id` | Admin |

---

## 🚀 Getting Started in Android Studio

### Prerequisites

- ✅ [Android Studio](https://developer.android.com/studio) (latest stable) with the **Flutter** and **Dart** plugins
- ✅ [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.3 or newer
- ✅ JDK 17 (bundled with recent Android Studio)
- ✅ An Android emulator (AVD) **or** a physical phone with USB debugging enabled

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/yash-code123/<your-repo-name>.git
cd <your-repo-name>
```

**2. Open in Android Studio**
`File → Open…` and select the folder that contains `pubspec.yaml`.

**3. Install dependencies**
Click **Pub get** in the banner at the top of `pubspec.yaml`, or run:
```bash
flutter pub get
```

**4. Verify your setup**
```bash
flutter doctor
```

**5. Choose a device**
Select an emulator or your phone from the toolbar dropdown. To create an emulator: `Tools → Device Manager → Create Device`.

**6. Run**
Press ▶ **Run** (`Shift + F10`), or:
```bash
flutter run
```

> ⏳ **First launch:** the backend is hosted on a free Render tier and may be asleep. The first request can take **up to ~60 seconds**. Wait it out; later requests are fast.

### 🔌 Using a different backend

```bash
# Local backend from the Android emulator (10.0.2.2 = your computer's localhost)
flutter run --dart-define=MEDEASE_API_BASE_URL=http://10.0.2.2:5000/api/

# Physical device on the same Wi-Fi: use your computer's LAN IP
flutter run --dart-define=MEDEASE_API_BASE_URL=http://192.168.x.x:5000/api/
```

In Android Studio: `Run → Edit Configurations → Additional run args`.

---

## 🔑 Demo Accounts

The login screen has a **"Try a demo account"** card with one-tap fill.

| Role | Username | Password |
|---|---|---|
| 🛠️ **Admin** | `admin` | `admin123` |
| 👨‍⚕️ **Doctor** | `dr.kavitha.rao` | `doc123` |
| 🧑‍⚕️ **Patient** | `P-1001` | `patient123` |

> ⚠️ Demo credentials for a showcase database only. Never use real patient data.

---

## 🎤 Presenter's Demo Script

A suggested 5-minute walkthrough:

| # | Role | Action | What to highlight |
|---|---|---|---|
| 1 | 🧑‍⚕️ Patient | Log in as `P-1001`, book an appointment | 4-step flow, UPI QR payment |
| 2 | 🧑‍⚕️ Patient | Check the issued token | Automatic queue token |
| 3 | 👨‍⚕️ Doctor | Log in, tap **Call Next Patient** | Live queue |
| 4 | 👨‍⚕️ Doctor | Open consultation, enter height and weight | **BMI auto-calculates** |
| 5 | 👨‍⚕️ Doctor | Add a prescription and a lab order | One screen, whole consultation |
| 6 | 🧑‍⚕️ Patient | Open **My Records** | Prescription and lab order appear instantly |
| 7 | 🛠️ Admin | Log in, show the dashboard | 8 live stats, beds, low-stock alerts |
| 8 | 🛠️ Admin | Open **Analytics** | Revenue trend and department charts |
| 9 | 🌐 Web | Open the MedEase website | Same data: shared backend |

---

## 📦 Building an APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> ℹ️ Release builds currently use the debug signing key. Create your own keystore before publishing to any store.

---

## 🛠️ Troubleshooting

| Problem | Fix |
|---|---|
| App loads forever on first login | The Render server is waking up. Wait up to ~60 seconds. |
| Network errors in a **release** APK | Make sure `android.permission.INTERNET` is declared in `android/app/src/main/AndroidManifest.xml`. |
| `flutter` command not found | Add Flutter's `bin` folder to your PATH, then restart Android Studio. |
| Gradle or JDK errors | In Android Studio: `Settings → Build → Gradle`, set **Gradle JDK** to 17. |
| Can't reach local backend from emulator | Use `10.0.2.2` instead of `localhost`. |
| Dependency conflicts | Run `flutter clean` then `flutter pub get`. |

---

## 🗺️ Roadmap

- [ ] 🔔 Push notifications (FCM) for appointment and token updates
- [ ] 💳 Real UPI deep-linking with a merchant VPA (currently a placeholder)
- [ ] 🧾 "Download PDF" for bills and prescriptions (`pdf` and `printing` already integrated)
- [ ] 👆 Biometric login
- [ ] 🎨 Branded app icon and splash screen
- [ ] 🌙 Dark mode

---

## 👤 Author

**Yash**
B.E. Computer Science & Engineering (Data Science)
Vidyavardhini's College of Engineering and Technology (VCET), Vasai

| | |
|---|---|
| 🐙 GitHub | [github.com/yash-code123](https://github.com/yash-code123) |
| 💼 LinkedIn | [Yash Bhirud](https://www.linkedin.com/in/yash-bhirud-631448420) |

---

⭐ *If you found this project useful, consider giving it a star!*

*Built with Flutter and care for better healthcare workflows.*
