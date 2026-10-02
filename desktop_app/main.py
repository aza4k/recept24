"""
Recept24 Pharmacy Pro - Dorixona Boshqaruv Desktop Dasturi (.EXE)
Dizayn va xavfsizlik: Recept24 Mobile App uslubida (Blue & Slate Modern UI)
"""

import customtkinter as ctk
import requests
import json
import tkinter as tk
from tkinter import messagebox, ttk

# Mavzu va ranglar palitrasi (Mobile app bilan 100% bir xil)
ctk.set_appearance_mode("Light")
ctk.set_default_color_theme("blue")

PRIMARY_COLOR = "#2563EB"
PRIMARY_HOVER = "#1D4ED8"
DARK_NAVY = "#1E3A8A"
BG_LIGHT = "#F8FAFC"
CARD_BG = "#FFFFFF"
BORDER_COLOR = "#E2E8F0"
TEXT_MAIN = "#0F172A"
TEXT_MUTED = "#64748B"
SUCCESS_GREEN = "#059669"
DANGER_RED = "#DC2626"

DEFAULT_SERVER = "https://web-production-13565.up.railway.app"

class Recept24DesktopApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Recept24 Pharmacy Pro — Dorixona Boshqaruvi")
        self.geometry("1100x720")
        self.minsize(980, 640)
        self.configure(fg_color=BG_LIGHT)

        self.server_url = DEFAULT_SERVER
        self.auth_token = None
        self.current_user = None
        self.current_pharmacy = None

        # Asosiy container
        self.main_container = ctk.CTkFrame(self, fg_color="transparent")
        self.main_container.pack(fill="both", expand=True)

        self.show_login_screen()

    # ========================================================
    # 1. LOGIN EKRANI
    # ========================================================
    def show_login_screen(self):
        for widget in self.main_container.winfo_children():
            widget.destroy()

        login_card = ctk.CTkFrame(
            self.main_container,
            width=460,
            corner_radius=20,
            fg_color=CARD_BG,
            border_width=1,
            border_color=BORDER_COLOR
        )
        login_card.place(relx=0.5, rely=0.5, anchor="center")

        # Sarlavha & Logo
        header_frame = ctk.CTkFrame(login_card, fg_color=DARK_NAVY, corner_radius=18, height=110)
        header_frame.pack(fill="x", padx=16, pady=16)

        logo_lbl = ctk.CTkLabel(
            header_frame,
            text="⚕️ Recept24",
            font=ctk.CTkFont(size=26, weight="bold"),
            text_color="#FFFFFF"
        )
        logo_lbl.pack(pady=(16, 2))

        sub_lbl = ctk.CTkLabel(
            header_frame,
            text="Dorixona Boshqaruv va Kassa Integratsiyasi",
            font=ctk.CTkFont(size=12),
            text_color="#BFDBFE"
        )
        sub_lbl.pack(pady=(0, 14))

        body_frame = ctk.CTkFrame(login_card, fg_color="transparent")
        body_frame.pack(fill="both", expand=True, padx=32, pady=(10, 24))

        ctk.CTkLabel(body_frame, text="Tizimga Kirish", font=ctk.CTkFont(size=20, weight="bold"), text_color=TEXT_MAIN).pack(anchor="w", pady=(0, 4))
        ctk.CTkLabel(body_frame, text="Faqat vakolatli dorixona ma'murlari uchun", font=ctk.CTkFont(size=12), text_color=TEXT_MUTED).pack(anchor="w", pady=(0, 18))

        self.username_entry = ctk.CTkEntry(body_frame, placeholder_text="Login (Username)", height=44, font=ctk.CTkFont(size=13))
        self.username_entry.insert(0, "owner")
        self.username_entry.pack(fill="x", pady=(0, 12))

        self.password_entry = ctk.CTkEntry(body_frame, placeholder_text="Parol", show="•", height=44, font=ctk.CTkFont(size=13))
        self.password_entry.insert(0, "pharm123")
        self.password_entry.pack(fill="x", pady=(0, 20))

        self.login_btn = ctk.CTkButton(
            body_frame,
            text="Kirish",
            height=44,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color=PRIMARY_COLOR,
            hover_color=PRIMARY_HOVER,
            command=self.handle_login
        )
        self.login_btn.pack(fill="x", pady=(0, 16))

        # Sinov hisoblari paneli
        hint_frame = ctk.CTkFrame(body_frame, fg_color="#F1F5F9", corner_radius=10)
        hint_frame.pack(fill="x", pady=(0, 10))

        ctk.CTkLabel(hint_frame, text="Tezkor sinov akkauntlari:", font=ctk.CTkFont(size=11, weight="bold"), text_color=TEXT_MUTED).pack(anchor="w", padx=12, pady=(8, 4))
        
        btn_row = ctk.CTkFrame(hint_frame, fg_color="transparent")
        btn_row.pack(fill="x", padx=12, pady=(0, 8))

        ctk.CTkButton(
            btn_row, text="Dorixonachi (owner)", height=28, font=ctk.CTkFont(size=11),
            fg_color="#DBEAFE", text_color="#1E40AF", hover_color="#BFDBFE",
            command=lambda: self.set_credentials("owner", "pharm123")
        ).pack(side="left", padx=(0, 6))

        ctk.CTkButton(
            btn_row, text="Bosh Admin (admin)", height=28, font=ctk.CTkFont(size=11),
            fg_color="#FEE2E2", text_color="#991B1B", hover_color="#FECACA",
            command=lambda: self.set_credentials("admin", "admin123")
        ).pack(side="left")

        # Server manzilini o'zgartirish tugmasi
        ctk.CTkButton(
            body_frame, text=f"Server: {self.server_url}", height=24, font=ctk.CTkFont(size=10),
            fg_color="transparent", text_color=TEXT_MUTED, hover_color="#E2E8F0",
            command=self.show_server_dialog
        ).pack(pady=(4, 0))

    def set_credentials(self, u, p):
        self.username_entry.delete(0, 'end')
        self.username_entry.insert(0, u)
        self.password_entry.delete(0, 'end')
        self.password_entry.insert(0, p)

    def show_server_dialog(self):
        dialog = ctk.CTkInputDialog(text="Recept24 API server URL manzilini kiriting:", title="Server Sozlamalari")
        new_url = dialog.get_input()
        if new_url:
            self.server_url = new_url.strip().rstrip('/')
            self.show_login_screen()

    def handle_login(self):
        username = self.username_entry.get().strip()
        password = self.password_entry.get().strip()
        if not username or not password:
            messagebox.showwarning("Ogohlantirish", "Login va parolni kiriting!")
            return

        self.login_btn.configure(state="disabled", text="Tekshirilmoqda...")

        try:
            url = f"{self.server_url}/api/desktop/login/"
            res = requests.post(
                url,
                json={"username": username, "password": password},
                headers={"Content-Type": "application/json"},
                timeout=12
            )
            data = res.json()

            if res.status_code == 200 and data.get("status") == "ok":
                self.auth_token = data.get("token")
                self.current_user = data.get("user")
                self.current_pharmacy = data.get("pharmacy")
                self.show_dashboard_screen()
            else:
                messagebox.showerror("Kirish xatosi", data.get("error", "Login yoki parol noto'g'ri"))
                self.login_btn.configure(state="normal", text="Kirish")
        except Exception as e:
            messagebox.showerror("Ulanish xatosi", f"Serverga ulanib bo'lmadi:\n{str(e)}")
            self.login_btn.configure(state="normal", text="Kirish")

    # ========================================================
    # 2. DASHBOARD ASOSIY EKRANI
    # ========================================================
    def show_dashboard_screen(self):
        for widget in self.main_container.winfo_children():
            widget.destroy()

        # Yuqori Header
        header = ctk.CTkFrame(self.main_container, fg_color=DARK_NAVY, corner_radius=0, height=64)
        header.pack(fill="x", side="top")

        left_h = ctk.CTkFrame(header, fg_color="transparent")
        left_h.pack(side="left", padx=20, pady=12)

        ctk.CTkLabel(left_h, text="⚕️ Recept24 Pharmacy Pro", font=ctk.CTkFont(size=18, weight="bold"), text_color="#FFFFFF").pack(side="left")

        # Dorixona nomi badge
        pharm_name = self.current_pharmacy.get("name") if self.current_pharmacy else "Superadmin Rejimi"
        pharm_badge = ctk.CTkFrame(header, fg_color="#1E40AF", corner_radius=15)
        pharm_badge.pack(side="left", padx=16, pady=14)
        ctk.CTkLabel(pharm_badge, text=f"🟢 {pharm_name}", font=ctk.CTkFont(size=13, weight="bold"), text_color="#FFFFFF").pack(padx=14, pady=4)

        # O'ng qism: Foydalanuvchi & Chiqish
        right_h = ctk.CTkFrame(header, fg_color="transparent")
        right_h.pack(side="right", padx=20, pady=12)

        u_name = self.current_user.get("username", "")
        role = "Admin" if self.current_user.get("is_superuser") else "Dorixonachi"
        ctk.CTkLabel(right_h, text=f"👤 {u_name} ({role})", font=ctk.CTkFont(size=13), text_color="#E2E8F0").pack(side="left", padx=(0, 16))

        ctk.CTkButton(
            right_h, text="Chiqish", width=80, height=32,
            fg_color="#DC2626", hover_color="#B91C1C", font=ctk.CTkFont(size=12, weight="bold"),
            command=self.logout
        ).pack(side="left")

        # Asosiy tanasi: Chap Sidebar + O'ng Kontent
        content_row = ctk.CTkFrame(self.main_container, fg_color="transparent")
        content_row.pack(fill="both", expand=True)

        # Chap Sidebar
        self.sidebar = ctk.CTkFrame(content_row, width=230, corner_radius=0, fg_color="#FFFFFF", border_width=1, border_color=BORDER_COLOR)
        self.sidebar.pack(side="left", fill="y")
        self.sidebar.pack_propagate(False)

        # O'ng Kontent maydoni
        self.content_area = ctk.CTkFrame(content_row, fg_color="transparent")
        self.content_area.pack(side="right", fill="both", expand=True, padx=20, pady=20)

        # Menyu tugmalari
        self.menu_buttons = {}
        menus = [
            ("inventory", "📦  Ombor & Narxlar"),
            ("sync", "🔄  1C & Fayl Sinxronizatsiya"),
            ("settings", "🏥  Dorixona Sozlamalari"),
        ]
        if self.current_user.get("is_superuser"):
            menus.append(("users", "👥  Foydalanuvchilar (Admin)"))
        menus.append(("logs", "📊  Audit va Tarix"))

        ctk.CTkLabel(self.sidebar, text="BO'LIMLAR", font=ctk.CTkFont(size=11, weight="bold"), text_color=TEXT_MUTED).pack(anchor="w", padx=20, pady=(20, 8))

        for key, title in menus:
            btn = ctk.CTkButton(
                self.sidebar, text=title, anchor="w", height=42, corner_radius=10,
                font=ctk.CTkFont(size=13, weight="bold"),
                fg_color="transparent", text_color=TEXT_MAIN, hover_color="#EFF6FF",
                command=lambda k=key: self.switch_tab(k)
            )
            btn.pack(fill="x", padx=12, pady=3)
            self.menu_buttons[key] = btn

        self.switch_tab("inventory")

    def logout(self):
        self.auth_token = None
        self.current_user = None
        self.current_pharmacy = None
        self.show_login_screen()

    def switch_tab(self, tab_key):
        # Tugma rangini faollashtirish
        for k, b in self.menu_buttons.items():
            if k == tab_key:
                b.configure(fg_color="#EFF6FF", text_color=PRIMARY_COLOR)
            else:
                b.configure(fg_color="transparent", text_color=TEXT_MAIN)

        for w in self.content_area.winfo_children():
            w.destroy()

        if tab_key == "inventory":
            self.render_inventory_tab()
        elif tab_key == "sync":
            self.render_sync_tab()
        elif tab_key == "settings":
            self.render_settings_tab()
        elif tab_key == "users":
            self.render_users_tab()
        elif tab_key == "logs":
            self.render_logs_tab()

    def _auth_headers(self):
        return {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.auth_token}"
        }

    # ========================================================
    # TAB 1: OMBOR VA NARXLAR JADVALI
    # ========================================================
    def render_inventory_tab(self):
        # Qidiruv qatori
        top_bar = ctk.CTkFrame(self.content_area, fg_color=CARD_BG, corner_radius=12, border_width=1, border_color=BORDER_COLOR)
        top_bar.pack(fill="x", pady=(0, 14))

        self.search_entry = ctk.CTkEntry(top_bar, placeholder_text="Dori nomi yoki shtrix-kodi bo'yicha qidirish...", width=380, height=38)
        self.search_entry.pack(side="left", padx=14, pady=10)
        self.search_entry.bind("<Return>", lambda e: self.load_inventory_data())

        ctk.CTkButton(
            top_bar, text="Qidirish", width=90, height=38,
            fg_color=PRIMARY_COLOR, hover_color=PRIMARY_HOVER, font=ctk.CTkFont(size=13, weight="bold"),
            command=self.load_inventory_data
        ).pack(side="left", padx=(0, 8))

        ctk.CTkButton(
            top_bar, text="🔄 Yangilash", width=100, height=38,
            fg_color="#E2E8F0", text_color=TEXT_MAIN, hover_color="#CBD5E1",
            command=self.load_inventory_data
        ).pack(side="left")

        # Narx tahrirlash tugmasi
        ctk.CTkButton(
            top_bar, text="✏️ Narxni Tahrirlash", width=140, height=38,
            fg_color=SUCCESS_GREEN, hover_color="#047857", font=ctk.CTkFont(size=13, weight="bold"),
            command=self.edit_selected_stock
        ).pack(side="right", padx=14)

        # Jadval (Treeview)
        table_frame = ctk.CTkFrame(self.content_area, fg_color=CARD_BG, corner_radius=12, border_width=1, border_color=BORDER_COLOR)
        table_frame.pack(fill="both", expand=True)

        columns = ("id", "barcode", "name", "category", "manufacturer", "price", "qty", "status")
        self.stock_tree = ttk.Treeview(table_frame, columns=columns, show="headings", selectmode="browse")

        self.stock_tree.heading("id", text="ID")
        self.stock_tree.heading("barcode", text="Shtrix-kod")
        self.stock_tree.heading("name", text="Dori nomi")
        self.stock_tree.heading("category", text="Toifasi")
        self.stock_tree.heading("manufacturer", text="Ishlab chiqaruvchi")
        self.stock_tree.heading("price", text="Narxi (so'm)")
        self.stock_tree.heading("qty", text="Qoldiq")
        self.stock_tree.heading("status", text="Holati")

        self.stock_tree.column("id", width=50, anchor="center")
        self.stock_tree.column("barcode", width=130)
        self.stock_tree.column("name", width=220)
        self.stock_tree.column("category", width=110)
        self.stock_tree.column("manufacturer", width=140)
        self.stock_tree.column("price", width=110, anchor="e")
        self.stock_tree.column("qty", width=70, anchor="center")
        self.stock_tree.column("status", width=90, anchor="center")

        # Scrollbar
        scroll = ttk.Scrollbar(table_frame, orient="vertical", command=self.stock_tree.yview)
        self.stock_tree.configure(yscrollcommand=scroll.set)

        self.stock_tree.pack(side="left", fill="both", expand=True, padx=8, pady=8)
        scroll.pack(side="right", fill="y", pady=8)

        self.stock_items = []
        self.load_inventory_data()

    def load_inventory_data(self):
        query = self.search_entry.get().strip() if hasattr(self, 'search_entry') else ""
        for row in self.stock_tree.get_children():
            self.stock_tree.delete(row)

        try:
            url = f"{self.server_url}/api/desktop/stocks/?q={requests.utils.quote(query)}"
            res = requests.get(url, headers=self._auth_headers(), timeout=10)
            if res.status_code == 200:
                data = res.json()
                self.stock_items = data.get("stocks", [])
                for item in self.stock_items:
                    status = "Mavjud" if item.get("in_stock") else "Tugagan"
                    price_fmt = f"{int(item.get('price', 0)):,} so'm".replace(",", " ")
                    self.stock_tree.insert("", "end", values=(
                        item.get("stock_id"),
                        item.get("barcode") or "—",
                        item.get("name"),
                        item.get("category"),
                        item.get("manufacturer"),
                        price_fmt,
                        item.get("quantity"),
                        status
                    ))
        except Exception as e:
            messagebox.showerror("Xatolik", f"Ombor ma'lumotlarini olib bo'lmadi: {e}")

    def edit_selected_stock(self):
        selected = self.stock_tree.selection()
        if not selected:
            messagebox.showinfo("Tanlang", "Iltimos, avval ro'yxatdan birorta dorini tanlang!")
            return

        values = self.stock_tree.item(selected[0], "values")
        stock_id = values[0]
        med_name = values[2]
        current_price = values[5].replace(" so'm", "").replace(" ", "")

        dlg = ctk.CTkToplevel(self)
        dlg.title(f"Narxni Tahrirlash — {med_name}")
        dlg.geometry("400x260")
        dlg.grab_set()

        ctk.CTkLabel(dlg, text=med_name, font=ctk.CTkFont(size=15, weight="bold")).pack(pady=(18, 10))

        price_entry = ctk.CTkEntry(dlg, placeholder_text="Yangi narx (so'm)")
        price_entry.insert(0, current_price)
        price_entry.pack(pady=8, padx=30, fill="x")

        qty_entry = ctk.CTkEntry(dlg, placeholder_text="Qoldiq soni")
        qty_entry.insert(0, values[6])
        qty_entry.pack(pady=8, padx=30, fill="x")

        in_stock_var = ctk.BooleanVar(value=(values[7] == "Mavjud"))
        ctk.CTkCheckBox(dlg, text="Dorixonada mavjud", variable=in_stock_var).pack(pady=8)

        def save_edit():
            try:
                new_price = float(price_entry.get().strip())
                new_qty = int(qty_entry.get().strip())
                is_stk = in_stock_var.get()
                
                res = requests.post(
                    f"{self.server_url}/api/desktop/stock/update/",
                    json={"stock_id": stock_id, "price": new_price, "quantity": new_qty, "in_stock": is_stk},
                    headers=self._auth_headers(),
                    timeout=10
                )
                if res.status_code == 200:
                    dlg.destroy()
                    self.load_inventory_data()
                    messagebox.showinfo("Muvaffaqiyatli", "Narx va qoldiq yangilandi!")
                else:
                    messagebox.showerror("Xato", res.json().get("error", "Saqlab bo'lmadi"))
            except Exception as e:
                messagebox.showerror("Xato", str(e))

        ctk.CTkButton(dlg, text="Saqlash", fg_color=PRIMARY_COLOR, command=save_edit).pack(pady=12)

    # ========================================================
    # TAB 2: 1C VA FAYL SINXRONIZATSIYA
    # ========================================================
    def render_sync_tab(self):
        container = ctk.CTkScrollableFrame(self.content_area, fg_color="transparent")
        container.pack(fill="both", expand=True)

        # 1C Ko'rsatmalari
        card1 = ctk.CTkFrame(container, fg_color=CARD_BG, corner_radius=14, border_width=1, border_color=BORDER_COLOR)
        card1.pack(fill="x", pady=(0, 16), padx=4)

        ctk.CTkLabel(card1, text="🔄 1C:Предприятие Автоматик Интеграция", font=ctk.CTkFont(size=17, weight="bold"), text_color=DARK_NAVY).pack(anchor="w", padx=20, pady=(16, 6))
        ctk.CTkLabel(
            card1,
            text="Ushbu ma'lumotlarni dorixonangiz 1C mutaxassisiga bering. 1C avtomatik har 15 daqiqada narxlarni yangilab turadi.",
            font=ctk.CTkFont(size=12), text_color=TEXT_MUTED
        ).pack(anchor="w", padx=20, pady=(0, 14))

        api_key = self.current_pharmacy.get("api_key", "rec_none") if self.current_pharmacy else "rec_none"
        webhook_url = f"{self.server_url}/api/sync/1c/"

        # Webhook URL Box
        url_box = ctk.CTkFrame(card1, fg_color="#F1F5F9", corner_radius=8)
        url_box.pack(fill="x", padx=20, pady=6)
        ctk.CTkLabel(url_box, text=f"Webhook URL:  {webhook_url}", font=ctk.CTkFont(family="Consolas", size=12), text_color=TEXT_MAIN).pack(side="left", padx=12, pady=10)
        ctk.CTkButton(url_box, text="Nusxa olish", width=90, height=28, fg_color=PRIMARY_COLOR, command=lambda: self.copy_clip(webhook_url)).pack(side="right", padx=10)

        # API Key Box
        key_box = ctk.CTkFrame(card1, fg_color="#F1F5F9", corner_radius=8)
        key_box.pack(fill="x", padx=20, pady=(6, 20))
        ctk.CTkLabel(key_box, text=f"Maxfiy API Key:  {api_key}", font=ctk.CTkFont(family="Consolas", size=12, weight="bold"), text_color=DARK_NAVY).pack(side="left", padx=12, pady=10)
        ctk.CTkButton(key_box, text="Nusxa olish", width=90, height=28, fg_color=PRIMARY_COLOR, command=lambda: self.copy_clip(api_key)).pack(side="right", padx=10)

        # Excel / CSV Preyskurant yuklash
        card2 = ctk.CTkFrame(container, fg_color=CARD_BG, corner_radius=14, border_width=1, border_color=BORDER_COLOR)
        card2.pack(fill="x", padx=4)

        ctk.CTkLabel(card2, text="📋 Excel / CSV Preyskurantni Tezkor Yuklash", font=ctk.CTkFont(size=17, weight="bold"), text_color=SUCCESS_GREEN).pack(anchor="w", padx=20, pady=(16, 6))
        ctk.CTkLabel(
            card2,
            text="Excel jadvalingizdagi dorilarni nusxalang (Ctrl+C) va quyidagi maydonga tashlang (Ctrl+V).\nFormat: Shtrix-kod [Tab] Dori nomi [Tab] Narxi [Tab] Qoldiq",
            font=ctk.CTkFont(size=12), text_color=TEXT_MUTED
        ).pack(anchor="w", padx=20, pady=(0, 12))

        self.bulk_textbox = ctk.CTkTextbox(card2, height=160, font=ctk.CTkFont(family="Consolas", size=12))
        self.bulk_textbox.pack(fill="x", padx=20, pady=(0, 14))
        self.bulk_textbox.insert("1.0", "4780012340001\tParatsetamol 500mg\t2800\t120\n4780012340002\tAnalgin 500mg\t1600\t60")

        ctk.CTkButton(
            card2, text="🚀 Bazasini Yangilash (Serverga yuklash)", height=42,
            fg_color=SUCCESS_GREEN, hover_color="#047857", font=ctk.CTkFont(size=14, weight="bold"),
            command=self.handle_bulk_upload
        ).pack(anchor="w", padx=20, pady=(0, 20))

    def copy_clip(self, text):
        self.clipboard_clear()
        self.clipboard_append(text)
        messagebox.showinfo("Nusxalandi", "Xotiraga nusxalandi!")

    def handle_bulk_upload(self):
        raw = self.bulk_textbox.get("1.0", "end").strip()
        if not raw:
            return

        lines = raw.split("\n")
        items = []
        for line in lines:
            parts = line.split("\t")
            if len(parts) < 2:
                parts = line.split(",")
            if len(parts) >= 2:
                barcode = parts[0].strip() if len(parts) >= 3 else ""
                name = parts[1].strip() if len(parts) >= 3 else parts[0].strip()
                price = float(parts[2].strip() if len(parts) >= 3 else parts[1].strip())
                qty = int(parts[3].strip()) if len(parts) >= 4 else 10
                items.append({"barcode": barcode, "name": name, "price": price, "quantity": qty, "in_stock": True})

        if not items:
            messagebox.showwarning("Xato", "Hech qanday ma'lumot topilmadi!")
            return

        try:
            res = requests.post(
                f"{self.server_url}/api/desktop/stock/bulk-upload/",
                json={"items": items},
                headers=self._auth_headers(),
                timeout=20
            )
            if res.status_code == 200:
                data = res.json()
                messagebox.showinfo("Tayyor!", f"Muvaffaqiyatli yangilandi: {data.get('updated_count')} ta dori!")
                self.bulk_textbox.delete("1.0", "end")
            else:
                messagebox.showerror("Xato", res.json().get("error", "Yuklab bo'lmadi"))
        except Exception as e:
            messagebox.showerror("Xato", str(e))

    # ========================================================
    # TAB 3: DORIXONA PROFILI SOZLAMALARI
    # ========================================================
    def render_settings_tab(self):
        card = ctk.CTkFrame(self.content_area, fg_color=CARD_BG, corner_radius=14, border_width=1, border_color=BORDER_COLOR)
        card.pack(fill="both", expand=True)

        ctk.CTkLabel(card, text="🏥 Dorixona Profil Ma'lumotlari", font=ctk.CTkFont(size=18, weight="bold"), text_color=TEXT_MAIN).pack(anchor="w", padx=24, pady=(20, 4))
        ctk.CTkLabel(card, text="Ushbu ma'lumotlar Recept24 mobil ilovasida mijozlarga ko'rinadi", font=ctk.CTkFont(size=12), text_color=TEXT_MUTED).pack(anchor="w", padx=24, pady=(0, 20))

        p = self.current_pharmacy or {}

        form = ctk.CTkFrame(card, fg_color="transparent")
        form.pack(fill="x", padx=24)

        ctk.CTkLabel(form, text="Dorixona Nomi:", font=ctk.CTkFont(weight="bold")).grid(row=0, column=0, sticky="w", pady=8)
        self.p_name = ctk.CTkEntry(form, width=400)
        self.p_name.insert(0, p.get("name", ""))
        self.p_name.grid(row=0, column=1, sticky="w", pady=8)

        ctk.CTkLabel(form, text="Manzili (Mo'ljal):", font=ctk.CTkFont(weight="bold")).grid(row=1, column=0, sticky="w", pady=8)
        self.p_addr = ctk.CTkEntry(form, width=400)
        self.p_addr.insert(0, p.get("address", ""))
        self.p_addr.grid(row=1, column=1, sticky="w", pady=8)

        ctk.CTkLabel(form, text="Telefon raqami:", font=ctk.CTkFont(weight="bold")).grid(row=2, column=0, sticky="w", pady=8)
        self.p_phone = ctk.CTkEntry(form, width=400)
        self.p_phone.insert(0, p.get("phone", ""))
        self.p_phone.grid(row=2, column=1, sticky="w", pady=8)

        ctk.CTkLabel(form, text="Ish vaqti:", font=ctk.CTkFont(weight="bold")).grid(row=3, column=0, sticky="w", pady=8)
        self.p_hours = ctk.CTkEntry(form, width=400)
        self.p_hours.insert(0, p.get("work_hours", "24 саат"))
        self.p_hours.grid(row=3, column=1, sticky="w", pady=8)

        ctk.CTkButton(
            card, text="💾 O'zgarishlarni Saqlash", height=42, width=200,
            fg_color=PRIMARY_COLOR, hover_color=PRIMARY_HOVER, font=ctk.CTkFont(size=14, weight="bold"),
            command=self.save_pharmacy_settings
        ).pack(anchor="w", padx=24, pady=24)

    def save_pharmacy_settings(self):
        payload = {
            "name": self.p_name.get().strip(),
            "address": self.p_addr.get().strip(),
            "phone": self.p_phone.get().strip(),
            "work_hours": self.p_hours.get().strip(),
        }
        try:
            res = requests.post(f"{self.server_url}/api/desktop/profile/update/", json=payload, headers=self._auth_headers(), timeout=10)
            if res.status_code == 200:
                self.current_pharmacy = res.json().get("pharmacy")
                messagebox.showinfo("Saqlandi", "Dorixona ma'lumotlari muvaffaqiyatli yangilandi!")
            else:
                messagebox.showerror("Xato", res.json().get("error", "Saqlab bo'lmadi"))
        except Exception as e:
            messagebox.showerror("Xato", str(e))

    # ========================================================
    # TAB 4: ADMIN FOYDALANUVCHILAR BOSHQARUVI
    # ========================================================
    def render_users_tab(self):
        top_f = ctk.CTkFrame(self.content_area, fg_color="transparent")
        top_f.pack(fill="x", pady=(0, 14))

        ctk.CTkLabel(top_f, text="👥 Dorixona Egalari va Foydalanuvchilar Akkauntlari", font=ctk.CTkFont(size=18, weight="bold"), text_color=TEXT_MAIN).pack(side="left")

        ctk.CTkButton(
            top_f, text="+ Yangi Akkaunt Yaratish", height=38,
            fg_color=PRIMARY_COLOR, hover_color=PRIMARY_HOVER, font=ctk.CTkFont(size=13, weight="bold"),
            command=self.show_create_user_dialog
        ).pack(side="right")

        table_frame = ctk.CTkFrame(self.content_area, fg_color=CARD_BG, corner_radius=12, border_width=1, border_color=BORDER_COLOR)
        table_frame.pack(fill="both", expand=True)

        columns = ("id", "username", "fullname", "role", "pharmacy")
        self.users_tree = ttk.Treeview(table_frame, columns=columns, show="headings", selectmode="browse")
        self.users_tree.heading("id", text="ID")
        self.users_tree.heading("username", text="Login")
        self.users_tree.heading("fullname", text="Ism-sharif")
        self.users_tree.heading("role", text="Roli")
        self.users_tree.heading("pharmacy", text="Biriktirilgan Dorixona")

        self.users_tree.column("id", width=60, anchor="center")
        self.users_tree.column("username", width=140)
        self.users_tree.column("fullname", width=180)
        self.users_tree.column("role", width=120)
        self.users_tree.column("pharmacy", width=240)

        self.users_tree.pack(fill="both", expand=True, padx=8, pady=8)
        self.load_admin_users()

    def load_admin_users(self):
        for r in self.users_tree.get_children():
            self.users_tree.delete(r)
        try:
            res = requests.get(f"{self.server_url}/api/desktop/admin/users/", headers=self._auth_headers(), timeout=10)
            if res.status_code == 200:
                data = res.json()
                for u in data.get("users", []):
                    role = "Bosh Admin" if u.get("is_superuser") else "Dorixona Egasi"
                    self.users_tree.insert("", "end", values=(
                        u.get("id"),
                        u.get("username"),
                        u.get("full_name") or "—",
                        role,
                        u.get("pharmacy_name")
                    ))
        except Exception as e:
            messagebox.showerror("Xato", str(e))

    def show_create_user_dialog(self):
        # Dorixonalar ro'yxatini olish
        pharmacies = []
        try:
            r = requests.get(f"{self.server_url}/api/desktop/admin/users/", headers=self._auth_headers(), timeout=8)
            pharmacies = r.json().get("pharmacies", [])
        except Exception:
            pass

        dlg = ctk.CTkToplevel(self)
        dlg.title("Yangi Dorixona Egasi Yaratish")
        dlg.geometry("440x360")
        dlg.grab_set()

        ctk.CTkLabel(dlg, text="Yangi Akkaunt Qo'shish", font=ctk.CTkFont(size=16, weight="bold")).pack(pady=(16, 12))

        u_entry = ctk.CTkEntry(dlg, placeholder_text="Login (Username)")
        u_entry.pack(pady=6, padx=30, fill="x")

        p_entry = ctk.CTkEntry(dlg, placeholder_text="Parol", show="•")
        p_entry.pack(pady=6, padx=30, fill="x")

        f_entry = ctk.CTkEntry(dlg, placeholder_text="Ism-sharif")
        f_entry.pack(pady=6, padx=30, fill="x")

        pharm_names = [f"{p['id']}: {p['name']}" for p in pharmacies]
        combo = ctk.CTkComboBox(dlg, values=pharm_names if pharm_names else ["Biriktirilmasin"])
        combo.pack(pady=6, padx=30, fill="x")

        def submit():
            u = u_entry.get().strip()
            p = p_entry.get().strip()
            f = f_entry.get().strip()
            sel = combo.get()
            pharm_id = int(sel.split(":")[0]) if ":" in sel else None

            if not u or not p:
                messagebox.showwarning("Xato", "Login va parol kiritilishi shart!")
                return

            try:
                res = requests.post(
                    f"{self.server_url}/api/desktop/admin/users/create/",
                    json={"username": u, "password": p, "full_name": f, "pharmacy_id": pharm_id},
                    headers=self._auth_headers(),
                    timeout=10
                )
                if res.status_code == 200:
                    dlg.destroy()
                    self.load_admin_users()
                    messagebox.showinfo("Muvaffaqiyatli", f"Foydalanuvchi {u} yaratildi!")
                else:
                    messagebox.showerror("Xato", res.json().get("error", "Yaratib bo'lmadi"))
            except Exception as e:
                messagebox.showerror("Xato", str(e))

        ctk.CTkButton(dlg, text="Akkauntni Yaratish", fg_color=PRIMARY_COLOR, command=submit).pack(pady=16)

    # ========================================================
    # TAB 5: AUDIT VA SINXRONIZATSIYA TARIXI
    # ========================================================
    def render_logs_tab(self):
        top_f = ctk.CTkFrame(self.content_area, fg_color="transparent")
        top_f.pack(fill="x", pady=(0, 14))
        ctk.CTkLabel(top_f, text="📊 Sinxronizatsiya Tarixi va Jurnali (Audit)", font=ctk.CTkFont(size=18, weight="bold"), text_color=TEXT_MAIN).pack(side="left")

        table_frame = ctk.CTkFrame(self.content_area, fg_color=CARD_BG, corner_radius=12, border_width=1, border_color=BORDER_COLOR)
        table_frame.pack(fill="both", expand=True)

        columns = ("time", "pharmacy", "type", "received", "updated", "status", "details")
        self.logs_tree = ttk.Treeview(table_frame, columns=columns, show="headings", selectmode="browse")
        self.logs_tree.heading("time", text="Vaqti")
        self.logs_tree.heading("pharmacy", text="Dorixona")
        self.logs_tree.heading("type", text="Turi")
        self.logs_tree.heading("received", text="Qabul qilingan")
        self.logs_tree.heading("updated", text="Yangilangan")
        self.logs_tree.heading("status", text="Holati")
        self.logs_tree.heading("details", text="Tafsilotlar")

        self.logs_tree.column("time", width=140)
        self.logs_tree.column("pharmacy", width=180)
        self.logs_tree.column("type", width=80, anchor="center")
        self.logs_tree.column("received", width=90, anchor="center")
        self.logs_tree.column("updated", width=90, anchor="center")
        self.logs_tree.column("status", width=90, anchor="center")
        self.logs_tree.column("details", width=220)

        self.logs_tree.pack(fill="both", expand=True, padx=8, pady=8)

        try:
            res = requests.get(f"{self.server_url}/api/desktop/sync-logs/", headers=self._auth_headers(), timeout=10)
            if res.status_code == 200:
                for log in res.json().get("logs", []):
                    self.logs_tree.insert("", "end", values=(
                        log.get("created_at"),
                        log.get("pharmacy_name"),
                        log.get("sync_type"),
                        f"{log.get('items_received')} ta",
                        f"{log.get('items_updated')} ta",
                        log.get("status"),
                        log.get("details")
                    ))
        except Exception:
            pass

if __name__ == "__main__":
    app = Recept24DesktopApp()
    app.mainloop()
