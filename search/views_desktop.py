import json
import secrets
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db import transaction
from django.utils import timezone
from .models import Pharmacy, Medicine, MedicineStock, PharmacySyncLog, AuthToken

def _get_auth_user(request):
    """Token orqali foydalanuvchini aniqlash (Bearer <token>)"""
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        token_key = auth_header.split(' ')[1].strip()
        try:
            token = AuthToken.objects.select_related('user').get(key=token_key)
            return token.user
        except AuthToken.DoesNotExist:
            return None
    return None

def _get_pharmacy_from_key(request):
    """1C Webhook uchun API Key tekshirish (X-Pharmacy-Key header yoki Authorization)"""
    key = request.headers.get('X-Pharmacy-Key', '')
    if not key and request.headers.get('Authorization', '').startswith('ApiKey '):
        key = request.headers.get('Authorization').split(' ')[1].strip()
    if not key:
        key = request.GET.get('api_key', '')
    if key:
        try:
            return Pharmacy.objects.get(api_key=key, is_active=True)
        except Pharmacy.DoesNotExist:
            return None
    return None

# ========================================================
# 1. DESKTOP EXE LOGIN VA PROFIL
# ========================================================

@csrf_exempt
def desktop_login(request):
    """Desktop dastur orqali xavfsiz login qilish"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Faqat POST so\'rov qabul qilinadi'}, status=405)
    
    try:
        data = json.loads(request.body.decode('utf-8'))
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
    except Exception:
        return JsonResponse({'error': 'Noto\'g\'ri JSON format'}, status=400)

    if not username or not password:
        return JsonResponse({'error': 'Login va parol kiritilishi shart'}, status=400)

    user = authenticate(username=username, password=password)
    if not user or not user.is_active:
        return JsonResponse({'error': 'Login yoki parol noto\'g\'ri'}, status=401)

    # Token yaratish yoki eskisini yangilash
    token, _ = AuthToken.objects.get_or_create(user=user)

    # Foydalanuvchiga tegishli dorixona
    pharmacy = user.pharmacies.filter(is_active=True).first()
    pharmacy_data = None
    if pharmacy:
        pharmacy_data = {
            'id': pharmacy.id,
            'name': pharmacy.name,
            'address': pharmacy.address,
            'phone': pharmacy.phone or '',
            'work_hours': pharmacy.work_hours,
            'api_key': pharmacy.api_key,
            'latitude': pharmacy.latitude,
            'longitude': pharmacy.longitude,
        }

    return JsonResponse({
        'status': 'ok',
        'token': token.key,
        'user': {
            'id': user.id,
            'username': user.username,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'is_superuser': user.is_superuser,
        },
        'pharmacy': pharmacy_data,
    })

@csrf_exempt
def desktop_profile(request):
    """Joriy kirgan foydalanuvchi va dorixona ma'lumotlarini olish"""
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    pharmacy = user.pharmacies.filter(is_active=True).first()
    pharmacy_data = None
    if pharmacy:
        pharmacy_data = {
            'id': pharmacy.id,
            'name': pharmacy.name,
            'address': pharmacy.address,
            'phone': pharmacy.phone or '',
            'work_hours': pharmacy.work_hours,
            'api_key': pharmacy.api_key,
            'latitude': pharmacy.latitude,
            'longitude': pharmacy.longitude,
        }

    return JsonResponse({
        'user': {
            'id': user.id,
            'username': user.username,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'is_superuser': user.is_superuser,
        },
        'pharmacy': pharmacy_data,
    })

@csrf_exempt
def desktop_update_pharmacy(request):
    """Dorixona ma'lumotlarini (nomi, ish vaqti, telefon) Desktop orqali sozlash"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    try:
        data = json.loads(request.body.decode('utf-8'))
    except Exception:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    pharmacy = user.pharmacies.filter(is_active=True).first()
    if not pharmacy and not user.is_superuser:
        return JsonResponse({'error': 'Sizga biriktirilgan dorixona topilmadi'}, status=404)

    # Superadmin bo'lsa pharmacy_id bo'yicha tahrirlashi mumkin
    if user.is_superuser and data.get('pharmacy_id'):
        pharmacy = Pharmacy.objects.filter(id=data['pharmacy_id']).first()

    if not pharmacy:
        return JsonResponse({'error': 'Dorixona topilmadi'}, status=404)

    if 'name' in data: pharmacy.name = data['name'].strip()
    if 'address' in data: pharmacy.address = data['address'].strip()
    if 'phone' in data: pharmacy.phone = data['phone'].strip()
    if 'work_hours' in data: pharmacy.work_hours = data['work_hours'].strip()
    if 'latitude' in data: pharmacy.latitude = float(data['latitude'])
    if 'longitude' in data: pharmacy.longitude = float(data['longitude'])
    pharmacy.save()

    return JsonResponse({
        'status': 'ok',
        'message': 'Dorixona ma\'lumotlari muvaffaqiyatli saqlandi',
        'pharmacy': {
            'id': pharmacy.id,
            'name': pharmacy.name,
            'address': pharmacy.address,
            'phone': pharmacy.phone,
            'work_hours': pharmacy.work_hours,
            'api_key': pharmacy.api_key,
        }
    })

@csrf_exempt
def desktop_regenerate_api_key(request):
    """1C ulanishi uchun yangi API Key yaratish"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    pharmacy = user.pharmacies.filter(is_active=True).first()
    if not pharmacy and not user.is_superuser:
        return JsonResponse({'error': 'Dorixona topilmadi'}, status=404)

    pharmacy.generate_api_key()
    pharmacy.save()

    return JsonResponse({'status': 'ok', 'new_api_key': pharmacy.api_key})

# ========================================================
# 2. OMBOR VA NARXLARNI BOSHQARISH (DESKTOP)
# ========================================================

def desktop_get_stocks(request):
    """Dorixonadagi barcha dorilar qoldig'i va narxlarini olish"""
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    pharmacy = user.pharmacies.filter(is_active=True).first()
    if not pharmacy:
        if user.is_superuser:
            # Superadmin bo'lsa tanlangan dorixonani olishi mumkin
            pharm_id = request.GET.get('pharmacy_id')
            if pharm_id:
                pharmacy = Pharmacy.objects.filter(id=pharm_id).first()
            else:
                pharmacy = Pharmacy.objects.first()
        if not pharmacy:
            return JsonResponse({'stocks': []})

    q = request.GET.get('q', '').strip()
    stocks_qs = MedicineStock.objects.filter(pharmacy=pharmacy).select_related('medicine')

    if q:
        stocks_qs = stocks_qs.filter(medicine__name__icontains=q) | stocks_qs.filter(medicine__barcode__icontains=q)

    result = []
    for s in stocks_qs:
        result.append({
            'stock_id': s.id,
            'medicine_id': s.medicine.id,
            'name': s.medicine.name,
            'barcode': s.medicine.barcode or '',
            'category': s.medicine.category,
            'manufacturer': s.medicine.manufacturer,
            'price': float(s.price),
            'quantity': s.quantity,
            'in_stock': s.in_stock,
            'updated_at': s.updated_at.strftime('%Y-%m-%d %H:%M') if s.updated_at else '',
        })

    return JsonResponse({
        'pharmacy_id': pharmacy.id,
        'pharmacy_name': pharmacy.name,
        'total_count': len(result),
        'stocks': result,
    })

@csrf_exempt
def desktop_update_stock(request):
    """Bitta dori narxi yoki mavjudligini tezkor o'zgartirish"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    try:
        data = json.loads(request.body.decode('utf-8'))
        stock_id = data.get('stock_id')
        price = data.get('price')
        in_stock = data.get('in_stock')
        quantity = data.get('quantity')
    except Exception:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    stock = MedicineStock.objects.select_related('pharmacy').filter(id=stock_id).first()
    if not stock:
        return JsonResponse({'error': 'Qoldiq topilmadi'}, status=404)

    # Ruxsat tekshiruvi
    if not user.is_superuser and stock.pharmacy.owner != user:
        return JsonResponse({'error': 'Bu amalga ruxsatingiz yo\'q'}, status=403)

    if price is not None: stock.price = float(price)
    if in_stock is not None: stock.in_stock = bool(in_stock)
    if quantity is not None: stock.quantity = int(quantity)
    stock.save()

    return JsonResponse({
        'status': 'ok',
        'message': 'Muvaffaqiyatli yangilandi',
        'stock': {
            'stock_id': stock.id,
            'price': float(stock.price),
            'in_stock': stock.in_stock,
            'quantity': stock.quantity,
        }
    })

# ========================================================
# 3. 1C UNIVERSAL WEBHOOK & EXCEL SYNC
# ========================================================

@csrf_exempt
def sync_1c_webhook(request):
    """
    1C: Korxona yoki boshqa kassa tizimidan avtomatik qoldiqlarni qabul qilish.
    Header: X-Pharmacy-Key: <api_key>
    Format:
    {
        "items": [
            {"barcode": "4780012340001", "name": "Paratsetamol", "price": 2500, "quantity": 50, "in_stock": true}
        ]
    }
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Faqat POST so\'rov qabul qilinadi'}, status=405)

    pharmacy = _get_pharmacy_from_key(request)
    if not pharmacy:
        return JsonResponse({'error': 'Noto\'g\'ri yoki faol bo\'lmagan API Key'}, status=401)

    try:
        body = json.loads(request.body.decode('utf-8'))
        items = body.get('items', [])
    except Exception as e:
        return JsonResponse({'error': f'JSON xatoligi: {str(e)}'}, status=400)

    if not isinstance(items, list):
        return JsonResponse({'error': 'items ro\'yxat (array) bo\'lishi shart'}, status=400)

    updated_count = 0
    created_count = 0
    errors = []

    with transaction.atomic():
        for idx, item in enumerate(items):
            try:
                name = str(item.get('name', '')).strip()
                barcode = str(item.get('barcode', '')).strip() if item.get('barcode') else ''
                price = float(item.get('price', 0))
                quantity = int(item.get('quantity', 1))
                in_stock = bool(item.get('in_stock', quantity > 0))

                if not name and not barcode:
                    errors.append(f"Qator #{idx+1}: nom yoki shtrix-kod ko'rsatilmagan")
                    continue

                # 1. Shtrix-kod bo'yicha qidirish
                medicine = None
                if barcode:
                    medicine = Medicine.objects.filter(barcode=barcode).first()

                # 2. Nom bo'yicha qidirish (agar shtrix-kod bilan topilmasa)
                if not medicine and name:
                    medicine = Medicine.objects.filter(name__iexact=name).first()

                # 3. Agar mavjud bo'lmasa, Master Katalogga yangi dori sifatida qo'shish
                if not medicine:
                    medicine = Medicine.objects.create(
                        name=name,
                        barcode=barcode or None,
                        description=f"{name} - {pharmacy.name} orqali 1C dan qo'shildi",
                        manufacturer="1C orqali yuklangan",
                        category="Boshqa"
                    )
                    created_count += 1
                elif barcode and not medicine.barcode:
                    medicine.barcode = barcode
                    medicine.save(update_fields=['barcode'])

                # 4. Dorixona qoldig'ini yangilash
                stock, s_created = MedicineStock.objects.update_or_create(
                    pharmacy=pharmacy,
                    medicine=medicine,
                    defaults={
                        'price': price,
                        'quantity': quantity,
                        'in_stock': in_stock,
                    }
                )
                updated_count += 1

            except Exception as item_err:
                errors.append(f"Qator #{idx+1} ({item.get('name', '')}): {str(item_err)}")

        # Log yozish
        PharmacySyncLog.objects.create(
            pharmacy=pharmacy,
            sync_type='1C',
            items_received=len(items),
            items_updated=updated_count,
            items_created=created_count,
            status='WARNING' if errors else 'SUCCESS',
            details=f"Xatolar: {'; '.join(errors[:5])}" if errors else "Muvaffaqiyatli sinxronizatsiya qilindi"
        )

    return JsonResponse({
        'status': 'success',
        'pharmacy': pharmacy.name,
        'items_received': len(items),
        'items_updated': updated_count,
        'new_medicines_added': created_count,
        'errors_count': len(errors),
        'errors_sample': errors[:5],
        'synced_at': timezone.now().isoformat(),
    })

@csrf_exempt
def desktop_bulk_sync(request):
    """Desktop ilova orqali Excel / CSV massiv qoldiqlarini yuklash"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    pharmacy = user.pharmacies.filter(is_active=True).first()
    if not pharmacy:
        return JsonResponse({'error': 'Dorixona biriktirilmagan'}, status=404)

    try:
        body = json.loads(request.body.decode('utf-8'))
        items = body.get('items', [])
    except Exception:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    updated_count = 0
    created_count = 0
    with transaction.atomic():
        for item in items:
            name = str(item.get('name', '')).strip()
            barcode = str(item.get('barcode', '')).strip() if item.get('barcode') else ''
            price = float(item.get('price', 0))
            quantity = int(item.get('quantity', 10))
            in_stock = bool(item.get('in_stock', True))

            medicine = None
            if barcode: medicine = Medicine.objects.filter(barcode=barcode).first()
            if not medicine and name: medicine = Medicine.objects.filter(name__iexact=name).first()

            if not medicine:
                medicine = Medicine.objects.create(
                    name=name, barcode=barcode or None,
                    description=f"{name}", manufacturer="Excel import", category="Boshqa"
                )
                created_count += 1

            MedicineStock.objects.update_or_create(
                pharmacy=pharmacy,
                medicine=medicine,
                defaults={'price': price, 'quantity': quantity, 'in_stock': in_stock}
            )
            updated_count += 1

        PharmacySyncLog.objects.create(
            pharmacy=pharmacy,
            sync_type='EXCEL_DESKTOP',
            items_received=len(items),
            items_updated=updated_count,
            items_created=created_count,
            status='SUCCESS',
            details='Desktop ilovasi orqali fayl import qilindi'
        )

    return JsonResponse({
        'status': 'ok',
        'updated_count': updated_count,
        'created_count': created_count,
    })

# ========================================================
# 4. ADMIN USERLARNI BOSHQARISH (DESKTOP ADMIN UCHUN)
# ========================================================

def desktop_admin_get_users(request):
    """Superadmin uchun barcha dorixona egalari va ularning akkauntlari"""
    user = _get_auth_user(request)
    if not user or not user.is_superuser:
        return JsonResponse({'error': 'Faqat bosh administratorlar uchun'}, status=403)

    users = User.objects.all().order_by('-date_joined')
    pharmacies = Pharmacy.objects.all()

    users_data = []
    for u in users:
        p = u.pharmacies.first()
        users_data.append({
            'id': u.id,
            'username': u.username,
            'full_name': f"{u.first_name} {u.last_name}".strip(),
            'is_superuser': u.is_superuser,
            'is_active': u.is_active,
            'pharmacy_id': p.id if p else None,
            'pharmacy_name': p.name if p else 'Biriktirilmagan',
        })

    pharmacies_data = [{'id': p.id, 'name': p.name} for p in pharmacies]

    return JsonResponse({
        'users': users_data,
        'pharmacies': pharmacies_data,
    })

@csrf_exempt
def desktop_admin_create_user(request):
    """Yangi dorixona egasi akkauntini yaratish va dorixonani biriktirish"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    user = _get_auth_user(request)
    if not user or not user.is_superuser:
        return JsonResponse({'error': 'Ruxsat berilmagan'}, status=403)

    try:
        data = json.loads(request.body.decode('utf-8'))
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        full_name = data.get('full_name', '').strip()
        pharmacy_id = data.get('pharmacy_id')
    except Exception:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    if not username or not password:
        return JsonResponse({'error': 'Login va parol to\'ldirilishi shart'}, status=400)

    if User.objects.filter(username=username).exists():
        return JsonResponse({'error': f'"{username}" logini allaqachon mavjud'}, status=400)

    new_user = User.objects.create_user(
        username=username,
        password=password,
        first_name=full_name
    )

    if pharmacy_id:
        pharmacy = Pharmacy.objects.filter(id=pharmacy_id).first()
        if pharmacy:
            pharmacy.owner = new_user
            pharmacy.save()

    return JsonResponse({
        'status': 'ok',
        'message': f'Foydalanuvchi {username} muvaffaqiyatli yaratildi',
        'user_id': new_user.id
    })

def desktop_get_sync_logs(request):
    """Sinxronizatsiya jurnali audit loglari"""
    user = _get_auth_user(request)
    if not user:
        return JsonResponse({'error': 'Avtorizatsiya talab qilinadi'}, status=401)

    pharmacy = user.pharmacies.first()
    logs_qs = PharmacySyncLog.objects.select_related('pharmacy').all()
    if not user.is_superuser and pharmacy:
        logs_qs = logs_qs.filter(pharmacy=pharmacy)

    result = []
    for log in logs_qs[:50]:
        result.append({
            'id': log.id,
            'pharmacy_name': log.pharmacy.name,
            'sync_type': log.sync_type,
            'items_received': log.items_received,
            'items_updated': log.items_updated,
            'items_created': log.items_created,
            'status': log.status,
            'details': log.details,
            'created_at': log.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        })

    return JsonResponse({'logs': result})
