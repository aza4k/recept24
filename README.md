<div align="center">

# 💊 Recept24

### Find Medicines. Compare Prices. Locate Pharmacies.

A full-stack medicine search platform built for Uzbekistan — search drugs across pharmacies in real time, compare prices, and navigate to the nearest available stock.

<br/>

[![Build](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square&logo=githubactions&logoColor=white)](https://github.com)
[![Django](https://img.shields.io/badge/Django-5.x-092E20?style=flat-square&logo=django&logoColor=white)](https://djangoproject.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Railway](https://img.shields.io/badge/Deployed%20on-Railway-7B2FBE?style=flat-square&logo=railway&logoColor=white)](https://railway.app)
[![License: MIT](https://img.shields.io/badge/License-MIT-F59E0B?style=flat-square)](LICENSE)

</div>

---

## 📸 Screenshots

<div align="center">
  <img src="screenshots/1.jpg" width="250"/>
  <img src="screenshots/2.jpg" width="250"/>
  <img src="screenshots/3.jpg" width="250"/>
</div>


## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Data Models](#-data-models)
- [API Reference](#-api-reference)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Environment Variables](#-environment-variables)
- [Deployment](#-deployment)
- [Project Structure](#-project-structure)

---

## 🔍 Overview

**Recept24** solves a daily frustration: going from pharmacy to pharmacy to find a specific drug. Users search by medicine name or active ingredient, pick multiple items, and the platform instantly finds the **nearest pharmacy that stocks all of them** at the best combined price.

**Core user flow:**

```
Search medicine → Add to basket → System finds optimal pharmacy → Navigate via Maps
```

> Built for Nukus, Uzbekistan — seeded with real pharmacy locations and coordinates.

---

## 🏗 Architecture

Recept24 follows a **Decoupled Architecture**: a Django REST backend acts as the data and logic engine, while a Flutter client app handles all UI and user interaction. The two communicate exclusively through a JSON API.

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Client App                  │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │   Screens  │  │   Services   │  │  Maps (GMaps│  │
│  │  (Search,  │→ │ api_service  │  │  Flutter)   │  │
│  │  Pharmacy) │  │   .dart      │  │             │  │
│  └────────────┘  └──────┬───────┘  └─────────────┘  │
└─────────────────────────┼───────────────────────────┘
                     JSON / HTTP
┌─────────────────────────┼───────────────────────────┐
│            Django REST Backend                       │
│  ┌──────────────────────▼───────────────────────┐   │
│  │              search/views.py                  │   │
│  │  • api_search_medicines                       │   │
│  │  • api_search_pharmacies  (Smart Algorithm)   │   │
│  │  • api_medicine_detail                        │   │
│  └──────────────────────┬───────────────────────┘   │
│  ┌───────────────────────▼──────────────────────┐   │
│  │              search/models.py                 │   │
│  │  Medicine ←──── MedicineStock ────→ Pharmacy  │   │
│  └──────────────────────┬───────────────────────┘   │
│                     SQLite / PostgreSQL               │
└─────────────────────────────────────────────────────┘
```

---

## 🗄 Data Models

Three core models power the entire platform (`search/models.py`):

### `Medicine`
Stores the drug catalog with AI-generated descriptions.

| Field | Type | Description |
|---|---|---|
| `name` | CharField | Drug name |
| `active_ingredient` | CharField | Active compound |
| `description` | TextField | AI-generated description |
| `image` | ImageField | Drug photo |

### `Pharmacy`
Stores pharmacy locations with GPS coordinates.

| Field | Type | Description |
|---|---|---|
| `name` | CharField | Pharmacy name |
| `address` | CharField | Street address |
| `latitude` | FloatField | GPS latitude |
| `longitude` | FloatField | GPS longitude |
| `working_hours` | CharField | Opening hours |

### `MedicineStock`
The Many-to-Many bridge — which pharmacy has which drug and at what price.

| Field | Type | Description |
|---|---|---|
| `medicine` | ForeignKey → Medicine | Drug reference |
| `pharmacy` | ForeignKey → Pharmacy | Pharmacy reference |
| `price` | DecimalField | Current price |
| `in_stock` | BooleanField | Availability flag |

---

## 📡 API Reference

All endpoints are defined in `config/urls.py` → `search/urls.py`.

Base URL: `https://your-app.railway.app/api/`

| Method | Endpoint | View | Description |
|---|---|---|---|
| `GET` | `/medicines/search/?q=` | `api_search_medicines` | Search medicines by name |
| `GET` | `/medicines/<id>/` | `api_medicine_detail` | Single medicine detail |
| `POST` | `/pharmacies/search/` | `api_search_pharmacies` | **Smart search** — find optimal pharmacy for a basket of medicines |

### Smart Search Algorithm (`api_search_pharmacies`)

The core of the platform. When a user selects multiple medicines:

1. Receives a list of `medicine_id`s and the user's `latitude`/`longitude`
2. Queries `MedicineStock` to find pharmacies that stock **all** selected medicines
3. Ranks results by **distance** (Haversine formula) and **total price**
4. Returns ranked pharmacy list with combined price and distance

```json
// POST /api/pharmacies/search/
{
  "medicines": [1, 4, 7],
  "latitude": 42.4611,
  "longitude": 59.6168
}

// Response
{
  "results": [
    {
      "pharmacy": { "id": 3, "name": "Shifо Dorixona", "address": "...", "lat": ..., "lng": ... },
      "total_price": 45000,
      "distance_km": 0.8,
      "items": [...]
    }
  ]
}
```

---

## 🛠 Tech Stack

| Layer | Technology | Role |
|---|---|---|
| **Backend language** | Python 3.11+ | Core runtime |
| **Web framework** | Django 5.x | ORM, views, routing |
| **Database (dev)** | SQLite | Local development |
| **Database (prod)** | PostgreSQL | Production-ready |
| **App server** | Gunicorn | WSGI server |
| **Static files** | Whitenoise | Serves assets without Nginx |
| **Frontend** | Flutter 3.x + Dart | Cross-platform mobile & web |
| **Maps** | google_maps_flutter | Pharmacy markers & navigation |
| **Hosting** | Railway | Backend deployment |
| **CI/CD** | Procfile + railway.json | Auto-deploy on push |

---

## 🚀 Quick Start

### Prerequisites

- Python `3.11+`
- Flutter `3.x` → [Install Guide](https://docs.flutter.dev/get-started/install)
- Git

---

### Backend Setup (Django)

```bash
# 1. Clone
git clone https://github.com/yourusername/recept24.git
cd recept24

# 2. Virtual environment
python -m venv venv
source venv/bin/activate        # Linux / macOS
# venv\Scripts\activate         # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Environment variables
cp .env.example .env
# Fill in your values (see section below)

# 5. Migrate
python manage.py migrate

# 6. Seed database with Nukus pharmacies & medicines
python seed.py

# 7. Run
python manage.py runserver
# → http://127.0.0.1:8000/
```

---

### Frontend Setup (Flutter)

```bash
# 1. Enter Flutter project
cd recept24_app

# 2. Install packages
flutter pub get

# 3. Set API base URL in lib/services/api_service.dart
#    const String baseUrl = 'http://127.0.0.1:8000/api/';  ← dev
#    const String baseUrl = 'https://yourapp.railway.app/api/'; ← prod

# 4. Run
flutter run             # Android / iOS
flutter run -d chrome   # Web
```

---

## 🔑 Environment Variables

Create `.env` in the backend root:

```env
SECRET_KEY=your-django-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Switch to PostgreSQL for production:
DATABASE_URL=sqlite:///db.sqlite3

# Required for pharmacy map features:
GOOGLE_MAPS_API_KEY=your-google-maps-key
```

> `db.sqlite3`, `.env`, and `venv/` are all listed in `.gitignore` — never committed.

---

## ☁️ Deployment

Configured for **Railway** out of the box via `Procfile` and `railway.json`.

```bash
# Procfile
web: gunicorn config.wsgi:application --bind 0.0.0.0:$PORT
```

**Production checklist:**

- [ ] `DEBUG=False`
- [ ] `ALLOWED_HOSTS` set to Railway domain
- [ ] Strong unique `SECRET_KEY` in Railway environment variables
- [ ] `DATABASE_URL` pointing to Railway PostgreSQL
- [ ] HTTPS enabled (Railway handles this automatically)

---

## 📁 Project Structure

```
recept24/
│
├── config/                     # Django project config
│   ├── settings.py
│   ├── urls.py                 # Root URL routing
│   └── wsgi.py
│
├── search/                     # Core app
│   ├── models.py               # Medicine, Pharmacy, MedicineStock
│   ├── views.py                # Smart search logic + REST API
│   ├── urls.py                 # API endpoint routing
│   └── serializers.py
│
├── seed.py                     # Seeds Nukus pharmacies & medicines
├── requirements.txt
├── Procfile                    # Railway deployment
├── railway.json
│
└── recept24_app/               # Flutter app
    └── lib/
        ├── main.dart
        ├── screens/            # UI screens
        ├── widgets/            # Reusable components
        ├── services/
        │   └── api_service.dart  # All HTTP calls in one place
        └── models/             # Dart data models
```

---

## 📄 License

MIT © [Your Name](https://github.com/yourusername)

---

<div align="center">
Built for the Uzbekistan healthcare ecosystem · Nukus, Karakalpakstan
</div>