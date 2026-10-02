from django.db import models
from django.contrib.auth.models import User
import secrets

class Pharmacy(models.Model):
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    phone = models.CharField(max_length=50, blank=True, null=True)
    latitude = models.FloatField(default=0)
    longitude = models.FloatField(default=0)
    work_hours = models.CharField(max_length=50, blank=True, default='24 саат')
    
    # Xavfsizlik va integratsiya
    owner = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='pharmacies')
    api_key = models.CharField(max_length=64, unique=True, blank=True, null=True, db_index=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True)

    def generate_api_key(self):
        self.api_key = f"rec_{secrets.token_hex(24)}"
        return self.api_key

    def save(self, *args, **kwargs):
        if not self.api_key:
            self.generate_api_key()
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class Medicine(models.Model):
    name = models.CharField(max_length=255)
    barcode = models.CharField(max_length=64, blank=True, null=True, db_index=True)
    mxik_code = models.CharField(max_length=64, blank=True, null=True, db_index=True)
    description = models.TextField()
    manufacturer = models.CharField(max_length=255)
    image_url = models.URLField(max_length=500, blank=True, default='')
    category = models.CharField(max_length=50, default='Tabletkalar')

    @property
    def min_price(self):
        stock = self.stocks.filter(in_stock=True, quantity__gt=0).order_by('price').first()
        return stock.price if stock else 0
        
    @property
    def cheapest_pharmacy_name(self):
        stock = self.stocks.filter(in_stock=True, quantity__gt=0).order_by('price').first()
        return stock.pharmacy.name if stock else "Noma'lum"

    def __str__(self):
        return f"{self.name} ({self.barcode or 'shtrixkodsiz'})"

class MedicineStock(models.Model):
    pharmacy = models.ForeignKey(Pharmacy, on_delete=models.CASCADE, related_name='stocks')
    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE, related_name='stocks')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.IntegerField(default=10)
    in_stock = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['price']
        unique_together = ('pharmacy', 'medicine')

    def save(self, *args, **kwargs):
        if self.quantity <= 0:
            self.quantity = 0
            self.in_stock = False
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.medicine.name} - {self.pharmacy.name} - {self.price} UZS"

class PharmacySyncLog(models.Model):
    pharmacy = models.ForeignKey(Pharmacy, on_delete=models.CASCADE, related_name='sync_logs')
    sync_type = models.CharField(max_length=50, default='1C')  # 1C, EXCEL, MANUAL, API
    items_received = models.IntegerField(default=0)
    items_updated = models.IntegerField(default=0)
    items_created = models.IntegerField(default=0)
    status = models.CharField(max_length=20, default='SUCCESS')  # SUCCESS, WARNING, ERROR
    details = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.pharmacy.name} - {self.sync_type} ({self.created_at.strftime('%Y-%m-%d %H:%M')})"

class AuthToken(models.Model):
    key = models.CharField(max_length=64, primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='desktop_tokens')
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.key:
            self.key = secrets.token_hex(32)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Token for {self.user.username}"
