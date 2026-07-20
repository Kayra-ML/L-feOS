<div align="center">

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,50:6366f1,100:8b5cf6&height=200&section=header&text=LifeOS&fontSize=65&fontColor=ffffff&fontAlignY=38&desc=Notion%20Entegreli%20Kişisel%20Yaşam%20İşletim%20Sistemi&descAlignY=58&descAlign=50&animation=fadeIn" />

</div>

> **"Hayatını bir işletim sistemi gibi yönet."**  
> LifeOS, Notion'u bir veritabanı olarak kullanıp kendi arayüzünü oluşturan, tam yığın kişisel üretkenlik sistemidir. Web, mobil ve API — tek ekosistem.

---

## 💡 Fikir ve Motivasyon

Notion'u seviyordum ama sürekli sekmelere geçmek, mobilde yavaş açılması ve özelleştirilmiş görünüm istememden dolayı hayal kırıklığı yaşıyordum. Şunu düşündüm: **Notion'u veritabanı olarak kullansam, ama kendi arayüzümü yazsam?**

Bu fikirden LifeOS doğdu. Notion API üzerine tamamen özel bir frontend + backend + mobil uygulama katmanı kurdum. Böylece Notion'un güçlü veri altyapısından yararlanırken, kendi tasarladığım deneyimi kullanabiliyorum.

---

## 🏗️ Mimari

```
┌─────────────────────────────────────────────────┐
│                  LifeOS Ekosistemi               │
│                                                  │
│  ┌──────────┐   ┌──────────────┐   ┌──────────┐  │
│  │  Flutter │   │  HTML/CSS/JS │   │ FastAPI  │  │
│  │  Mobile  │   │   Frontend   │   │ Backend  │  │
│  │  (iOS/   │   │  (PWA / SPA) │   │  (api.py)│  │
│  │ Android) │   │              │   │          │  │
│  └────┬─────┘   └──────┬───────┘   └────┬─────┘  │
│       │                │                │         │
│       └────────────────┼────────────────┘         │
│                        │ HTTP/REST                │
│                 ┌──────▼───────┐                  │
│                 │  NotionClient │                  │
│                 │  (Python)    │                  │
│                 └──────┬───────┘                  │
│                        │ Notion API v1            │
│                 ┌──────▼───────┐                  │
│                 │  Notion.so   │                  │
│                 │  (Databases) │                  │
│                 └─────────────┘                  │
└─────────────────────────────────────────────────┘
```

---

## ⚙️ Özellikler

### 📋 Proje & Görev Yönetimi
- Notion'daki projeleri çek ve listele
- Yeni görev oluştur (başlık, tür, öncelik, tarih)
- Görevleri güncelle ve tamamlandı olarak işaretle
- Tip desteği: `Rutin`, `Görev`, `Dinlenme`

### 📓 Günlük (Journal)
- Notion'a günlük not ekle
- Kategorilere göre filtrele (Yazılım, Beslenme vb.)
- Tarih & saat damgalı kayıt

### 🧠 Second Brain
- Düşünceleri, notları Notion'a kaydet
- Tag sistemi ile organize et

### 🤖 AI Komutları
- Doğal dil ile görev oluştur
- `"Yarın sabah 9'da gym"` → otomatik task

### 📱 PWA + Mobil
- Web: Progressive Web App (offline-ready, yüklenebilir)
- Mobil: Flutter ile native iOS/Android

---

## 🛠️ Tech Stack

| Katman | Teknoloji |
|--------|-----------|
| Backend API | Python, FastAPI, Uvicorn |
| Notion İstemci | `requests`, Notion REST API v1 |
| Frontend | HTML, CSS, Vanilla JS (PWA + Service Worker) |
| Mobil | Flutter (Dart) |
| Veri Doğrulama | Pydantic v2 |
| Ortam Yönetimi | python-dotenv |
| API Dokümantasyonu | Swagger UI (`/docs`) |

---

## 📁 Proje Yapısı

```
LifeOS/
├── backend/
│   ├── api.py           # FastAPI uygulaması — tüm endpoint'ler
│   └── notion_client.py # Notion API istemcisi — tüm veri işlemleri
├── frontend/
│   ├── index.html       # Tek sayfalı uygulama (PWA)
│   ├── manifest.json    # PWA manifesti
│   └── sw.js            # Service Worker (offline destek)
├── mobile/
│   ├── lib/             # Flutter kaynak kodları
│   └── pubspec.yaml     # Dart bağımlılıkları
├── .env.example         # Gerekli ortam değişkenleri
└── requirements.txt     # Python bağımlılıkları
```

---

## 🚀 Kurulum

### Gereksinimler
- Python 3.10+
- Notion hesabı ve Integration Token

### 1. Ortam Değişkenlerini Ayarla
```bash
cp .env.example .env
```
`.env` dosyasını düzenle:
```env
NOTION_TOKEN=secret_xxxxx
PROJECTS_DB_ID=xxxxx
ROUTINES_DB_ID=xxxxx
JOURNALS_DB_ID=xxxxx
```

### 2. Backend'i Başlat
```bash
pip install -r requirements.txt
python backend/api.py
# → http://localhost:8000
# → http://localhost:8000/docs (Swagger UI)
```

### 3. Frontend'i Aç
`frontend/index.html` dosyasını tarayıcıda aç veya bir local server ile sun.

---

## 🔗 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/health` | API sağlık kontrolü |
| `GET` | `/projects` | Projeleri listele |
| `GET` | `/tasks` | Görevleri listele |
| `POST` | `/tasks` | Yeni görev oluştur |
| `PATCH` | `/tasks/{id}` | Görevi güncelle |
| `POST` | `/tasks/{id}/complete` | Görevi tamamla |
| `GET` | `/journal` | Günlük girişleri |
| `POST` | `/journal` | Yeni günlük girişi |
| `POST` | `/ai/parse` | Doğal dil → görev |

---

## 🤝 Katkı

Bu kişisel bir projedir. Fikirleriniz için Issues açabilirsiniz.

---

<div align="center">
<img src="https://img.shields.io/badge/Python-FastAPI-009688?style=flat-square&logo=fastapi" />
<img src="https://img.shields.io/badge/Flutter-Dart-02569B?style=flat-square&logo=flutter" />
<img src="https://img.shields.io/badge/Notion-API-000000?style=flat-square&logo=notion" />
<img src="https://img.shields.io/badge/PWA-Ready-5A0FC8?style=flat-square&logo=pwa" />

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:8b5cf6,50:6366f1,100:0d1117&height=100&section=footer" />
</div>
