# Recept24 - Dorixonalardan dori qidirish tizimi

Recept24 - bu foydalanuvchilarga dorixonalardan kerakli dorilarni qidirish, ularning narxlarini solishtirish va eng yaqin dorixonani topishga yordam beruvchi loyiha. Loyiha Django backend va Flutter frontend qismlaridan iborat.

## Loyiha tarkibi

- **Backend:** Django Framework (Python) yordamida yaratilgan API va veb-interfeys.
- **Frontend:** Flutter yordamida yaratilgan mobil ilova (Android, iOS va Web).

## Texnologiyalar

- **Backend:** Python, Django, SQLite, Whitenoise, Gunicorn.
- **Frontend:** Flutter, Dart, Google Maps API.
- **Deployment:** Railway (backend uchun tayyorlangan).

## O'rnatish va ishga tushirish

### Backend (Django)

1. Virtual muhitni yarating va faollashtiring:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   venv\Scripts\activate     # Windows
   ```

2. Zaruriy kutubxonalarni o'rnating:
   ```bash
   pip install -r requirements.txt
   ```

3. Ma'lumotlar bazasini migratsiya qiling:
   ```bash
   python manage.py migrate
   ```

4. Boshlang'ich ma'lumotlarni yuklang (ixtiyoriy):
   ```bash
   python seed.py
   ```

5. Serverni ishga tushiring:
   ```bash
   python manage.py runserver
   ```

### Frontend (Flutter)

1. `recept24_app` papkasiga o'ting:
   ```bash
   cd recept24_app
   ```

2. Paketlarni yuklab oling:
   ```bash
   flutter pub get
   ```

3. Ilovani ishga tushiring:
   ```bash
   flutter run
   ```

## Xavfsizlik bo'yicha eslatma

GitHub'ga yuklashdan oldin:
- `SECRET_KEY` ni environment variable orqali boshqarish tavsiya etiladi.
- `DEBUG` rejimini production'da `False` qilib belgilang.
- `db.sqlite3` fayli `.gitignore` ga kiritilgan, uni o'zingizning ma'lumotlaringiz bilan to'ldirishingiz mumkin.

## Muallif
[Sizning Ismingiz/GitHub Usernamengiz]
