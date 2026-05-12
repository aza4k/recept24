from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.db.models import Count, Q
from .models import Medicine, Pharmacy, MedicineStock

def index(request):
    medicine_ids = request.GET.getlist('m')
    pharmacies_data = []
    selected_medicines = []
    
    if medicine_ids:
        medicine_ids = [int(i) for i in medicine_ids if i.isdigit()]
        selected_medicines = Medicine.objects.filter(id__in=medicine_ids)
        
        if selected_medicines:
            pharmacies = Pharmacy.objects.annotate(
                match_count=Count('stocks', filter=Q(stocks__medicine__in=selected_medicines))
            ).filter(match_count=len(selected_medicines))
            
            for pharm in pharmacies:
                stocks = pharm.stocks.filter(medicine__in=selected_medicines)
                total_price = sum(stock.price for stock in stocks)
                pharmacies_data.append({
                    'pharmacy': pharm,
                    'stocks': stocks,
                    'total_price': total_price,
                    'lat': pharm.latitude,
                    'lng': pharm.longitude,
                })
            
            pharmacies_data.sort(key=lambda x: x['total_price'])

    return render(request, 'search/index.html', {
        'pharmacies_data': pharmacies_data,
        'selected_medicines': selected_medicines
    })

# ====== API ENDPOINTS FOR FLUTTER ======

def api_search_medicines(request):
    """Dori nomini qidirish (autocomplete)"""
    q = request.GET.get('q', '')
    if q:
        medicines = Medicine.objects.filter(name__icontains=q)[:10]
        data = [{
            'id': m.id,
            'name': m.name,
            'manufacturer': m.manufacturer,
            'image_url': m.image_url,
            'category': m.category,
        } for m in medicines]
        return JsonResponse(data, safe=False)
    return JsonResponse([], safe=False)

def api_search_pharmacies(request):
    """Tanlangan dorilar bo'yicha dorixonalar ro'yxatini qaytarish"""
    medicine_ids = request.GET.getlist('m')
    if not medicine_ids:
        return JsonResponse({'error': 'No medicines selected'}, status=400)
    
    medicine_ids = [int(i) for i in medicine_ids if i.isdigit()]
    selected_medicines = Medicine.objects.filter(id__in=medicine_ids)
    
    if not selected_medicines.exists():
        return JsonResponse({'pharmacies': [], 'medicines': []})
    
    pharmacies = Pharmacy.objects.annotate(
        match_count=Count('stocks', filter=Q(stocks__medicine__in=selected_medicines))
    ).filter(match_count=len(medicine_ids))
    
    result = []
    for pharm in pharmacies:
        stocks = pharm.stocks.filter(medicine__in=selected_medicines)
        total_price = sum(float(stock.price) for stock in stocks)
        stock_list = [{
            'medicine_name': s.medicine.name,
            'manufacturer': s.medicine.manufacturer,
            'price': float(s.price),
        } for s in stocks]
        
        result.append({
            'id': pharm.id,
            'name': pharm.name,
            'address': pharm.address,
            'phone': pharm.phone,
            'latitude': pharm.latitude,
            'longitude': pharm.longitude,
            'work_hours': pharm.work_hours,
            'total_price': total_price,
            'stocks': stock_list,
        })
    
    result.sort(key=lambda x: x['total_price'])
    medicines_data = [{'id': m.id, 'name': m.name} for m in selected_medicines]
    return JsonResponse({'pharmacies': result, 'medicines': medicines_data})

def api_all_pharmacies(request):
    """Barcha dorixonalar ro'yxati"""
    pharmacies = Pharmacy.objects.all()
    data = [{
        'id': p.id,
        'name': p.name,
        'address': p.address,
        'phone': p.phone,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'work_hours': p.work_hours,
    } for p in pharmacies]
    return JsonResponse(data, safe=False)

def api_all_medicines(request):
    """Barcha dorilar ro'yxati (alfavit bo'yicha)"""
    medicines = Medicine.objects.all().order_by('name')
    data = [{
        'id': m.id,
        'name': m.name,
        'manufacturer': m.manufacturer,
        'description': m.description,
        'image_url': m.image_url,
        'category': m.category,
        'min_price': float(m.min_price),
    } for m in medicines]
    return JsonResponse(data, safe=False)

def api_medicine_detail(request, medicine_id):
    """Bitta dori haqida to'liq ma'lumot (AI popup uchun)"""
    medicine = get_object_or_404(Medicine, pk=medicine_id)
    stocks = medicine.stocks.select_related('pharmacy').order_by('price')
    pharmacies_list = [{
        'pharmacy_name': s.pharmacy.name,
        'address': s.pharmacy.address,
        'price': float(s.price),
    } for s in stocks]
    
    return JsonResponse({
        'id': medicine.id,
        'name': medicine.name,
        'manufacturer': medicine.manufacturer,
        'description': medicine.description,
        'image_url': medicine.image_url,
        'category': medicine.category,
        'min_price': float(medicine.min_price),
        'pharmacies': pharmacies_list,
    })

# ====== WEB VIEWS ======

def detail(request, medicine_id):
    medicine = get_object_or_404(Medicine, pk=medicine_id)
    return render(request, 'search/detail.html', {'medicine': medicine})

def about(request):
    return render(request, 'search/about.html')

def contact(request):
    return render(request, 'search/contact.html')
