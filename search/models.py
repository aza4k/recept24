from django.db import models

class Pharmacy(models.Model):
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    phone = models.CharField(max_length=50, blank=True, null=True)
    latitude = models.FloatField(default=0)
    longitude = models.FloatField(default=0)
    work_hours = models.CharField(max_length=50, blank=True, default='24 саат')
    
    def __str__(self):
        return self.name

class Medicine(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField()
    manufacturer = models.CharField(max_length=255)
    image_url = models.URLField(max_length=500, blank=True, default='')
    category = models.CharField(max_length=50, default='Tabletkalar')

    @property
    def min_price(self):
        stock = self.stocks.order_by('price').first()
        return stock.price if stock else 0
        
    @property
    def cheapest_pharmacy_name(self):
        stock = self.stocks.order_by('price').first()
        return stock.pharmacy.name if stock else "Noma'lum"

    def __str__(self):
        return self.name

class MedicineStock(models.Model):
    pharmacy = models.ForeignKey(Pharmacy, on_delete=models.CASCADE, related_name='stocks')
    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE, related_name='stocks')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    in_stock = models.BooleanField(default=True)

    class Meta:
        ordering = ['price']

    def __str__(self):
        return f"{self.medicine.name} - {self.pharmacy.name} - {self.price} UZS"

