from django.contrib import admin
from .models import Medicine, Pharmacy, MedicineStock

class MedicineStockInline(admin.TabularInline):
    model = MedicineStock
    extra = 1

@admin.register(Medicine)
class MedicineAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'manufacturer', 'min_price')
    search_fields = ('name', 'manufacturer', 'description')
    list_filter = ('category',)
    inlines = [MedicineStockInline]

@admin.register(Pharmacy)
class PharmacyAdmin(admin.ModelAdmin):
    list_display = ('name', 'address', 'work_hours', 'phone')
    search_fields = ('name', 'address')
    inlines = [MedicineStockInline]

@admin.register(MedicineStock)
class MedicineStockAdmin(admin.ModelAdmin):
    list_display = ('medicine', 'pharmacy', 'price', 'in_stock')
    list_filter = ('pharmacy', 'in_stock')
    search_fields = ('medicine__name', 'pharmacy__name')
