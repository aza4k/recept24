"""
Recept24 - 1C Sinxronizatsiya Simulyatori
Ushbu skript 1C dasturi dorixona qoldiqlarini qanday yuborishini sinab ko'rish uchun mo'ljallangan.
"""

import urllib.request
import json
import sys

# Server manzili va dorixona kaliti
SERVER_URL = "https://web-production-13565.up.railway.app"  # yoki http://127.0.0.1:8000
API_KEY = "rec_test_key"  # Dorixonaning shaxsiy kaliti

def simulate_1c_sync(api_key, server_url=SERVER_URL):
    payload = {
        "items": [
            {
                "barcode": "4780012340001",
                "name": "Paratsetamol 500mg tab №10 (1C Test)",
                "price": 2700,
                "quantity": 120,
                "in_stock": True
            },
            {
                "barcode": "4780012340002",
                "name": "Analgin 500mg tab №10 (1C Test)",
                "price": 1600,
                "quantity": 45,
                "in_stock": True
            },
            {
                "barcode": "4780999990001",
                "name": "Yangi dori (Katalogda yo'q, 1C dan qo'shiladi)",
                "price": 22000,
                "quantity": 15,
                "in_stock": True
            }
        ]
    }

    req = urllib.request.Request(
        f"{server_url}/api/sync/1c/",
        data=json.dumps(payload).encode('utf-8'),
        headers={
            "Content-Type": "application/json; charset=utf-8",
            "X-Pharmacy-Key": api_key
        }
    )

    try:
        print(f"📡 {server_url}/api/sync/1c/ ga ma'lumot yuborilmoqda...")
        with urllib.request.urlopen(req, timeout=15) as res:
            response_data = json.loads(res.read().decode('utf-8'))
            print("✅ 1C Sinxronizatsiya muvaffaqiyatli!")
            print(json.dumps(response_data, indent=2, ensure_ascii=False))
    except urllib.error.HTTPError as e:
        print(f"❌ Xatolik ({e.code}): {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"❌ Ulanish xatoligi: {e}")

if __name__ == '__main__':
    key = sys.argv[1] if len(sys.argv) > 1 else API_KEY
    simulate_1c_sync(key)
