<div align="center">

# 💊 Recept24

### Find Medicines. Compare Prices. Locate Pharmacies.

A full-stack medicine search platform built for Uzbekistan — search drugs across pharmacies in real time, compare prices, and navigate to the nearest available stock.

<br/>

[![Build](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square&logo=githubactions&logoColor=white)](https://github.com/aza4k/recept24)
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

---

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

**Recept24** solves a daily frustration: going from pharmacy to pharmacy to find a specific drug. Users search by medicine name, pick multiple items, and the platform instantly finds the **pharmacies that stock all of them** at the best combined price.

**Core user flow:**

```
Search medicine → Add to basket → System finds optimal pharmacy → Navigate via Maps
```

> Built for Nukus, Uzbekistan — seeded with real pharmacy locations and coordinates.

---

## 🏗 Architecture

Recept24 follows a **Decoupled Architecture**: a Django backend acts as the data and logic engine, while a Flutter client app handles all UI and user interaction. The two communicate via JSON API.

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
Stores the drug catalog with detailed descriptions.

| Field | Type | Description |
|---|---|---|
| `name` | CharField | Drug name |
| `description` | TextField | Detailed description |
| `manufacturer` | CharField | Producing company |
| `image_url` | URLField | Link to drug photo |
| `category` | CharField | Medicine category (e.g. Tablets) |

### `Pharmacy`
Stores pharmacy locations with GPS coordinates.

| Field | Type | Description |
|---|---|---|
| `name` | CharField | Pharmacy name |
| `address` | CharField | Street address |
| `phone` | CharField | Contact number |
| `latitude` | FloatField | GPS latitude |
| `longitude` | FloatField | GPS longitude |
| `work_hours` | CharField | Opening hours |

### `MedicineStock`
The Many-to-Many bridge — linking pharmacies to medicine availability.

| Field | Type | Description |
|---|---|---|
| `medicine` | ForeignKey → Medicine | Drug reference |
| `pharmacy` | ForeignKey → Pharmacy | Pharmacy reference |
| `price` | DecimalField | Current price |
| `in_stock` | BooleanField | Availability flag |

---

## 📡 API Reference

All endpoints are reachable under the root URL.

Base URL: `https://your-app.railway.app/api/`

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/search/?q=` | Search medicines (autocomplete) |
| `GET` | `/api/search-pharmacies/?m=1&m=2` | **Smart search** — find pharmacies with selected medicines |
| `GET` | `/api/medicines/` | List all medications |
| `GET` | `/api/pharmacies/` | List all pharmacies |
| `GET` | `/api/medicine/<id>/` | Detailed medicine profile |

### Smart Search Logic (`api_search_pharmacies`)

The core engine:
1. Receives multiple `m` (medicine ID) parameters.
2. Filters pharmacies that stock **all** selected items using Django's `Count` and `Q` expressions.
3. Calculates `total_price` for each valid pharmacy.
4. Returns results sorted by **lowest total price**.

---

## 🛠 Tech Stack

| Layer | Technology | Role |
|---|---|---|
| **Backend language** | Python 3.11+ | Core runtime |
| **Web framework** | Django 5.x | ORM, logic, routing |
| **Database** | SQLite (dev) / PostgreSQL (prod) | Data storage |
| **App server** | Gunicorn | WSGI server |
| **Static files** | Whitenoise | Asset management |
| **Frontend** | Flutter 3.x + Dart | Cross-platform mobile UI |
| **Maps** | google_maps_flutter | Geo-location & visualization |
| **Hosting** | Railway | Cloud deployment |

---

## 🚀 Quick Start

### Backend Setup

```bash
# 1. Clone & Enter
git clone https://github.com/aza4k/recept24.git
cd recept24

# 2. Virtual environment
python -m venv venv
source venv/bin/activate # Windows: venv\Scripts\activate

# 3. Install
pip install -r requirements.txt

# 4. Initialize Database
python manage.py migrate
python seed.py

# 5. Run
python manage.py runserver
```

### Frontend Setup

```bash
cd recept24_app
flutter pub get

# Configure API URL in lib/services/api_service.dart
# static const String baseUrl = 'http://127.0.0.1:8000';

flutter run
```

---

## ☁️ Deployment

Pre-configured for **Railway** via `Procfile` and `railway.json`. The system automatically handles migrations and data seeding on each deploy.

---

## 📄 License

MIT © [aza4k](https://github.com/aza4k)

---

<div align="center">
  Developed by <b>fundev.uz</b> Team <br/>
  Built for the Uzbekistan healthcare ecosystem · Nukus, Karakalpakstan
</div>
