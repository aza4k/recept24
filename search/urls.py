from django.urls import path
from . import views
from . import views_desktop

urlpatterns = [
    # Public & Consumer Web / Mobile Endpoints
    path('', views.index, name='index'),
    path('api/search/', views.api_search_medicines, name='api_search'),
    path('api/search-pharmacies/', views.api_search_pharmacies, name='api_search_pharmacies'),
    path('api/pharmacies/', views.api_all_pharmacies, name='api_all_pharmacies'),
    path('api/medicines/', views.api_all_medicines, name='api_all_medicines'),
    path('api/medicine/<int:medicine_id>/', views.api_medicine_detail, name='api_medicine_detail'),
    path('api/init-db/', views.api_init_db, name='api_init_db'),
    path('about/', views.about, name='about'),
    path('contact/', views.contact, name='contact'),

    # 1C Universal Webhook Integration
    path('api/sync/1c/', views_desktop.sync_1c_webhook, name='sync_1c_webhook'),

    # Pharmacy Owner Desktop (.EXE) Endpoints
    path('api/desktop/login/', views_desktop.desktop_login, name='desktop_login'),
    path('api/desktop/profile/', views_desktop.desktop_profile, name='desktop_profile'),
    path('api/desktop/profile/update/', views_desktop.desktop_update_pharmacy, name='desktop_update_pharmacy'),
    path('api/desktop/profile/regenerate-api-key/', views_desktop.desktop_regenerate_api_key, name='desktop_regenerate_api_key'),
    
    # Desktop Stock Management & Bulk Excel Sync
    path('api/desktop/stocks/', views_desktop.desktop_get_stocks, name='desktop_get_stocks'),
    path('api/desktop/stock/update/', views_desktop.desktop_update_stock, name='desktop_update_stock'),
    path('api/desktop/stock/bulk-upload/', views_desktop.desktop_bulk_sync, name='desktop_bulk_sync'),
    path('api/desktop/sync-logs/', views_desktop.desktop_get_sync_logs, name='desktop_get_sync_logs'),

    # Superadmin Management (Desktop App)
    path('api/desktop/admin/users/', views_desktop.desktop_admin_get_users, name='desktop_admin_get_users'),
    path('api/desktop/admin/users/create/', views_desktop.desktop_admin_create_user, name='desktop_admin_create_user'),
]
