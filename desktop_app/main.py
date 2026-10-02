"""
Recept24 Pharmacy Pro - Desktop (.EXE) Launcher
Liquid Glass Interface (No Gradients) powered by PyWebView & Edge WebView2
"""

import os
import sys
import webview
import requests
import json

SERVER_URL = "https://web-production-13565.up.railway.app"

class ApiBridge:
    def __init__(self):
        self.auth_token = None
        self.current_user = None
        self.current_pharmacy = None
        self.server_url = SERVER_URL

    def _headers(self):
        h = {"Content-Type": "application/json"}
        if self.auth_token:
            h["Authorization"] = f"Bearer {self.auth_token}"
        return h

    def login(self, username, password):
        try:
            res = requests.post(
                f"{self.server_url}/api/desktop/login/",
                json={"username": username, "password": password},
                headers={"Content-Type": "application/json"},
                timeout=12
            )
            data = res.json()
            if res.status_code == 200 and data.get("status") == "ok":
                self.auth_token = data.get("token")
                self.current_user = data.get("user")
                self.current_pharmacy = data.get("pharmacy")
                return data
            return {"status": "error", "error": data.get("error", "Login xatosi")}
        except Exception as e:
            return {"status": "error", "error": f"Serverga ulanib bo'lmadi: {str(e)}"}

    def get_stocks(self, query=""):
        try:
            url = f"{self.server_url}/api/desktop/stocks/?q={requests.utils.quote(query)}"
            res = requests.get(url, headers=self._headers(), timeout=12)
            if res.status_code == 200:
                return res.json()
            return {"stocks": []}
        except Exception as e:
            return {"stocks": [], "error": str(e)}

    def update_stock(self, stock_id, price, in_stock, quantity):
        try:
            res = requests.post(
                f"{self.server_url}/api/desktop/stock/update/",
                json={
                    "stock_id": int(stock_id),
                    "price": float(price),
                    "in_stock": bool(in_stock),
                    "quantity": int(quantity)
                },
                headers=self._headers(),
                timeout=10
            )
            return res.json()
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def bulk_upload(self, items):
        try:
            res = requests.post(
                f"{self.server_url}/api/desktop/stock/bulk-upload/",
                json={"items": items},
                headers=self._headers(),
                timeout=25
            )
            return res.json()
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def update_pharmacy(self, payload):
        try:
            res = requests.post(
                f"{self.server_url}/api/desktop/profile/update/",
                json=payload,
                headers=self._headers(),
                timeout=10
            )
            return res.json()
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def get_admin_users(self):
        try:
            res = requests.get(f"{self.server_url}/api/desktop/admin/users/", headers=self._headers(), timeout=10)
            return res.json()
        except Exception as e:
            return {"users": [], "pharmacies": [], "error": str(e)}

    def create_user(self, username, password, full_name, pharmacy_id):
        try:
            res = requests.post(
                f"{self.server_url}/api/desktop/admin/users/create/",
                json={
                    "username": username,
                    "password": password,
                    "full_name": full_name,
                    "pharmacy_id": pharmacy_id
                },
                headers=self._headers(),
                timeout=10
            )
            return res.json()
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def get_sync_logs(self):
        try:
            res = requests.get(f"{self.server_url}/api/desktop/sync-logs/", headers=self._headers(), timeout=10)
            return res.json()
        except Exception as e:
            return {"logs": [], "error": str(e)}


def get_html_path():
    if getattr(sys, 'frozen', False):
        base_dir = getattr(sys, '_MEIPASS', os.path.dirname(sys.executable))
        for candidate in [
            os.path.join(base_dir, "ui", "index.html"),
            os.path.join(base_dir, "_internal", "ui", "index.html"),
            os.path.join(os.path.dirname(sys.executable), "_internal", "ui", "index.html"),
            os.path.join(base_dir, "index.html")
        ]:
            if os.path.exists(candidate):
                return candidate
    base_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base_dir, "ui", "index.html")


def main():
    api = ApiBridge()
    html_file = get_html_path()

    window = webview.create_window(
        title="Recept24",
        url=html_file,
        js_api=api,
        width=1180,
        height=760,
        min_size=(960, 640),
        background_color='#F1F5F9'
    )

    webview.start(debug=False)

if __name__ == '__main__':
    main()
