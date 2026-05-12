import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from search.models import Medicine, Pharmacy, MedicineStock

# Clear existing
Medicine.objects.all().delete()
Pharmacy.objects.all().delete()
MedicineStock.objects.all().delete()

# Нөкис қаласындағы реал дәриханалар (apteks.txt тан)
pharmacies_data = [
    {"name": "Шаңарақ дәриханасы", "address": "Нөкис қаласы", "phone": "", "latitude": 42.4722124, "longitude": 59.6029685, "work_hours": "24 саат"},
    {"name": "Рашида Фарм дәриханасы", "address": "Жуманазаров көшеси №34, Нөкис", "phone": "", "latitude": 42.4746044, "longitude": 59.6192142, "work_hours": "24 саат"},
    {"name": "Мир дәриханасы", "address": "Нөкис қаласы", "phone": "", "latitude": 42.4571608, "longitude": 59.6199787, "work_hours": "09:00-19:00"},
    {"name": "Ажинияз дәриханасы", "address": "Нөкис қаласы", "phone": "", "latitude": 42.4644758, "longitude": 59.602376, "work_hours": "09:00-20:00"},
    {"name": "Айболит дәриханасы", "address": "Нөкис қаласы", "phone": "", "latitude": 42.4436685, "longitude": 59.6346175, "work_hours": "24 саат"},
    {"name": "Ақмаңғыт дәриханасы", "address": "Ақмаңғыт посёлкасы", "phone": "", "latitude": 42.598498, "longitude": 59.5389729, "work_hours": "24 саат"},
    {"name": "Бес қала мед", "address": "Нөкис қаласы", "phone": "", "latitude": 42.4722161, "longitude": 59.6030338, "work_hours": "07:00-23:00"},
]

pharmacies = []
for p_data in pharmacies_data:
    p = Pharmacy.objects.create(**p_data)
    pharmacies.append(p)

# Create Medicines with images, categories and detailed AI descriptions
medicines_data = [
    {
        "name": "Paratsetamol",
        "description": "Paratsetamol — og'riqni qoldiruvchi va isitmani tushiruvchi eng keng tarqalgan dorilardan biri. U bosh og'rig'i, tish og'rig'i, muskul og'rig'i, bo'g'im og'rig'i, shuningdek, shamollash va gripp bilan bog'liq isitmani tushirishda qo'llaniladi.\n\n📋 Tarkibi: Paracetamol 500mg\n💊 Qo'llash: Kattalar — 1-2 tabletka kuniga 3-4 marta (ovqatdan keyin)\n⚠️ Ehtiyotkorlik: Jigar kasalligi bo'lganlar ehtiyot bo'lishi kerak\n🔬 Farmakologik guruhi: Analgezik-antipiretik",
        "manufacturer": "Uzpharmsanoat",
        "image_url": "https://osonapteka.uz/upload/iblock/a6e/43u2bqehywdgcwz2q7c3fjjgbpz0rvhm.webp",
        "category": "Tabletkalar",
        "base_price": 2000
    },
    {
        "name": "Analgin",
        "description": "Analgin (Metamizol natriy) — kuchli og'riqni qoldiruvchi va yallig'lanishga qarshi dori vositasi. Bosh og'rig'i, tish og'rig'i, nevralgia, muskul va bo'g'im og'rig'larida keng qo'llaniladi.\n\n📋 Tarkibi: Metamizol natriy 500mg\n💊 Qo'llash: 1 tabletka kuniga 2-3 marta\n⚠️ Ehtiyotkorlik: Uzok muddatli qo'llanilmasligi kerak\n🔬 Farmakologik guruhi: Nosteroidal yallig'lanishga qarshi vosita",
        "manufacturer": "Dori Darmon",
        "image_url": "https://osonapteka.uz/upload/iblock/b22/8xk1oowkr6e0rbfuhjw3yznnwtfhqhfg.webp",
        "category": "Tabletkalar",
        "base_price": 1500
    },
    {
        "name": "Nimesil",
        "description": "Nimesil — kukun ko'rinishidagi kuchli yallig'lanishga qarshi va og'riqni qoldiruvchi dori. Bosh og'rig'i, tish og'rig'i, bo'g'imlar yallig'lanishi, menstruatsiya og'rig'lari va jarohatdan keyingi og'rig'larda samarali.\n\n📋 Tarkibi: Nimesulid 100mg\n💊 Qo'llash: 1 paket iliq suvda eritib, kuniga 2 marta ovqatdan keyin\n⚠️ Ehtiyotkorlik: Oshqozon yarasi bo'lganda taqiqlangan\n🔬 Farmakologik guruhi: NSAID (selektiv COX-2 inhibitor)",
        "manufacturer": "Berlin-Chemie",
        "image_url": "https://osonapteka.uz/upload/iblock/3ce/fnzfwb5d5u8txqv1k3yt7yzrdpxdglql.webp",
        "category": "Kukunlar",
        "base_price": 45000
    },
    {
        "name": "Amoksitsillin",
        "description": "Amoksitsillin — keng ko'lamli antibakterial ta'sirga ega penitsillin guruhidagi antibiotik. Nafas yo'llari, quloq, burun, tomoq, siydik yo'llari va teri infeksiyalarida qo'llaniladi.\n\n📋 Tarkibi: Amoxicillin 500mg\n💊 Qo'llash: 1 kapsula kuniga 3 marta, 5-7 kun davomida\n⚠️ Ehtiyotkorlik: Penitsillin allergiyasi bo'lganlar ISHLATMASIN\n🔬 Farmakologik guruhi: Beta-laktam antibiotik",
        "manufacturer": "Hemofarm",
        "image_url": "https://osonapteka.uz/upload/iblock/d9d/xo8r2ubsqktbf93ynlxv1bz57qg3bxa5.webp",
        "category": "Kapsulalar",
        "base_price": 12000
    },
    {
        "name": "Trimol",
        "description": "Trimol — kompleks tarkibli og'riq qoldiruvchi va isitma tushiruvchi dori. Bosh og'rig'i, tish og'rig'i, isitma va shamollashda qo'llaniladi.\n\n📋 Tarkibi: Paracetamol + Kofein + Askorbin kislota\n💊 Qo'llash: 1-2 tabletka kuniga 3 marta\n⚠️ Ehtiyotkorlik: Yuqori qon bosimi bo'lganlarda ehtiyot bo'lish\n🔬 Farmakologik guruhi: Kombinatsion analgezik",
        "manufacturer": "Uzpharmsanoat",
        "image_url": "https://osonapteka.uz/upload/iblock/06c/ug9fkr0q21rlbw9qadaiqfxtnrrcz6s1.webp",
        "category": "Tabletkalar",
        "base_price": 3000
    },
    {
        "name": "Pantagam sirop",
        "description": "Pantagam — nootrop ta'sirga ega dori vositasi. Bolalarda nutqni rivojlantirish, diqqatni jamlash va xotirani yaxshilash, epilepsiya, tiklar va enurezdа qo'llaniladi.\n\n📋 Tarkibi: Gopantenom kislota 100mg/ml\n💊 Qo'llash: Bolalarga 2.5-5ml kuniga 2-3 marta (vrach tayinlashi bilan)\n⚠️ Ehtiyotkorlik: Faqat vrach ko'rsatmasi bilan\n🔬 Farmakologik guruhi: Nootrop preparat",
        "manufacturer": "PIK-PHARMA",
        "image_url": "https://osonapteka.uz/upload/iblock/00b/2m91z9zy2v34l70q6h1fmrpuufqy1t2l.webp",
        "category": "Siroplar",
        "base_price": 65000
    },
    {
        "name": "Metrogil gel",
        "description": "Metrogil gel — teriga surtib ishlatiladigan yallig'lanishga qarshi va mikrobga qarshi dori. Ugri (akne), rosacea va boshqa teri kasalliklarida qo'llaniladi.\n\n📋 Tarkibi: Metronidazol 1%\n💊 Qo'llash: Zararlangan teriga yupqa qavat bilan kuniga 2 marta surting\n⚠️ Ehtiyotkorlik: Ko'zga tegishini oldini oling\n🔬 Farmakologik guruhi: Antiprotozoal va antibakterial vosita",
        "manufacturer": "Unique Pharmaceutical",
        "image_url": "https://osonapteka.uz/upload/iblock/72d/fuwsgb0yqsgfqmcbsjfxk8b3kcgp1t1m.webp",
        "category": "Malhamlar",
        "base_price": 25000
    },
    {
        "name": "Vitamin C (Askorbin kislotasi)",
        "description": "Vitamin C — immunitetni mustahkamlovchi, antioksidant ta'sirga ega vitamin. Shamollash oldini olish, immunitetni kuchaytirish va tez tuzalishda yordam beradi.\n\n📋 Tarkibi: Askorbin kislota 500mg\n💊 Qo'llash: 1 tabletka kuniga 1-2 marta ovqatdan keyin\n⚠️ Ehtiyotkorlik: Oshqozon kasalligi bo'lganda ehtiyot bo'lish\n🔬 Farmakologik guruhi: Vitaminlar",
        "manufacturer": "Vitamin Zavod",
        "image_url": "https://osonapteka.uz/upload/iblock/06f/a7iokbcwz2m7lqb3v1xdttg5yfhahpx5.webp",
        "category": "Tabletkalar",
        "base_price": 5000
    },
    {
        "name": "Sitramon P",
        "description": "Sitramon — bosh og'rig'iga qarshi eng mashhur va arzon dorilardan biri. Tarkibida paratsetamol, aspirin va kofein bo'lib, ularning birgalikdagi ta'siri og'riqni tez qoldiradi.\n\n📋 Tarkibi: Paracetamol 180mg + ASK 240mg + Kofein 30mg\n💊 Qo'llash: 1-2 tabletka og'riq paytida\n⚠️ Ehtiyotkorlik: 15 yoshgacha bolalarga berilmasin\n🔬 Farmakologik guruhi: Kombinatsion analgezik-antipiretik",
        "manufacturer": "Tatximfarmpreparati",
        "image_url": "https://osonapteka.uz/upload/iblock/20b/09o50m5jn1u2h1k17yf48qmm3piqk3l1.webp",
        "category": "Tabletkalar",
        "base_price": 2500
    },
    {
        "name": "Mukaltin",
        "description": "Mukaltin — o'simlik asosida tayyorlangan yo'tal dorilaridan biri. U quruq yo'talni namlaydi va balg'amni suyultirib chiqarishga yordam beradi.\n\n📋 Tarkibi: Althaea officinalis ekstrakti 50mg\n💊 Qo'llash: 1-2 tabletka kuniga 3-4 marta (suvda eritib ichish mumkin)\n⚠️ Ehtiyotkorlik: Oshqozon yarasi bo'lganda ishlatmaslik\n🔬 Farmakologik guruhi: Ekspektorant (balg'am ko'chiruvchi)",
        "manufacturer": "Dori Darmon",
        "image_url": "https://osonapteka.uz/upload/iblock/0dd/8v3tvfvp6vfobmm95rjcjkuohbz6u43d.webp",
        "category": "Tabletkalar",
        "base_price": 1800
    },
    {
        "name": "Mezim forte",
        "description": "Mezim forte — ovqat hazm qilishni yaxshilaydigan ferment preparati. Oshqozon og'irligi, ko'p ovqat yeganda, pankreatitda va oshqozon-ichak kasalliklarida qo'llaniladi.\n\n📋 Tarkibi: Pankreatin (lipaza, amilaza, proteaza)\n💊 Qo'llash: 1-2 tabletka ovqat paytida\n⚠️ Ehtiyotkorlik: O'tkir pankreatitda taqiqlangan\n🔬 Farmakologik guruhi: Fermentativ preparat",
        "manufacturer": "Berlin-Chemie",
        "image_url": "https://osonapteka.uz/upload/iblock/5ca/rvh7kfj9j59b4qv7qolmdyjcqq5m17v1.webp",
        "category": "Tabletkalar",
        "base_price": 35000
    },
    {
        "name": "Loratadin",
        "description": "Loratadin — allergiyaga qarshi antigiistamin dori. Burun bitishi, ko'z yoshi oqishi, teri qichishi va boshqa allergik reaktsiyalarda samarali.\n\n📋 Tarkibi: Loratadin 10mg\n💊 Qo'llash: 1 tabletka kuniga 1 marta\n⚠️ Ehtiyotkorlik: Uxlash kelishi mumkin, haydovchilarga ehtiyot\n🔬 Farmakologik guruhi: H1-gistamin retseptorlari blokatori",
        "manufacturer": "Borisovskiy ZMP",
        "image_url": "https://osonapteka.uz/upload/iblock/ef9/rp1t5zllryyp23v2o8n35o2nlbp6vu74.webp",
        "category": "Tabletkalar",
        "base_price": 8000
    },
    {
        "name": "Azitromitsin",
        "description": "Azitromitsin — keng spektrli makrolid antibiotik. Angina, bronxit, pnevmoniya, sinuzit va boshqa bakterial infeksiyalarda qo'llaniladi. 3 kunlik kurs bilan davolash mumkin.\n\n📋 Tarkibi: Azitromitsin 500mg\n💊 Qo'llash: 1 kapsula kuniga 1 marta, 3 kun davomida\n⚠️ Ehtiyotkorlik: Jigar kasalligi bo'lganda ehtiyot\n🔬 Farmakologik guruhi: Makrolid antibiotik",
        "manufacturer": "Egis",
        "image_url": "https://osonapteka.uz/upload/iblock/c54/sfbcjxz2d6m99kwnw3eoh5dkqlx4f0uo.webp",
        "category": "Kapsulalar",
        "base_price": 18000
    },
    {
        "name": "Sinekod sirop",
        "description": "Sinekod — quruq yo'talni to'xtatuvchi samarali dori. Yo'tal markaziga ta'sir qilib, intratorakal yo'talni bostiradi. Bolalar va kattalar uchun sirop shakli mavjud.\n\n📋 Tarkibi: Butamirat sitrat 1.5mg/ml\n💊 Qo'llash: Bolalarga 5ml, kattalarga 15ml kuniga 3-4 marta\n⚠️ Ehtiyotkorlik: 2 yoshgacha bolalarga taqiqlangan\n🔬 Farmakologik guruhi: Antitussiv (yo'tal bosuvchi) vosita",
        "manufacturer": "Novartis",
        "image_url": "https://osonapteka.uz/upload/iblock/09f/0lszhp7nrpjmtlvdlxbbhqzqxd2f1e4j.webp",
        "category": "Siroplar",
        "base_price": 55000
    },
    {
        "name": "Deksa (Deksametazon)",
        "description": "Deksametazon — kuchli glyukokortikoid gormon preparati. Og'ir allergik reaktsiyalar, astma xurujlari, autoimmun kasalliklar va yallig'lanish holatlarida qo'llaniladi.\n\n📋 Tarkibi: Deksametazon 0.5mg\n💊 Qo'llash: Vrach ko'rsatmasiga ko'ra, odatda 0.5-9mg/kun\n⚠️ Ehtiyotkorlik: Faqat vrach nazoratida! O'z-o'zidan ishlatmang\n🔬 Farmakologik guruhi: Glyukokortikosteroid",
        "manufacturer": "Krka",
        "image_url": "https://osonapteka.uz/upload/iblock/dd5/3h9v4rmqo1kkpx2ywbhv8m4d43gvjx2h.webp",
        "category": "Tabletkalar",
        "base_price": 22000
    },
]

for m_data in medicines_data:
    base_price = m_data.pop('base_price')
    medicine = Medicine.objects.create(**m_data)
    
    # Give this medicine to a random number of pharmacies (from 4 to all 9 pharmacies)
    num_pharms = random.randint(4, len(pharmacies))
    selected_pharms = random.sample(pharmacies, num_pharms)
    
    for pharm in selected_pharms:
        # random variation in price (-10% to +15%)
        variation = random.uniform(0.9, 1.15)
        price = round(base_price * variation, -2) # round to nearest 100
        
        MedicineStock.objects.create(
            medicine=medicine,
            pharmacy=pharm,
            price=price,
            in_stock=True
        )

print(f"Successfully added {len(medicines_data)} medicines and {len(pharmacies_data)} pharmacies!")
