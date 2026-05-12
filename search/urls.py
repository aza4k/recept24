from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/search/', views.api_search_medicines, name='api_search'),
    path('api/search-pharmacies/', views.api_search_pharmacies, name='api_search_pharmacies'),
    path('api/pharmacies/', views.api_all_pharmacies, name='api_all_pharmacies'),
    path('api/medicines/', views.api_all_medicines, name='api_all_medicines'),
    path('api/medicine/<int:medicine_id>/', views.api_medicine_detail, name='api_medicine_detail'),
    path('medicine/<int:medicine_id>/', views.detail, name='detail'),
    path('about/', views.about, name='about'),
    path('contact/', views.contact, name='contact'),
]
