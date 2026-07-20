"""
=============================================================
  LifeOS — FastAPI Backend (api.py)
=============================================================
  Çalıştırma:
    python backend/api.py
  veya:
    uvicorn backend.api:app --reload --port 8000

  API Dokümantasyonu (otomatik):
    http://localhost:8000/docs
=============================================================
"""

import os
import sys
import logging
from datetime import date
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv

# notion_client.py'nin bulunduğu dizini path'e ekle
sys.path.insert(0, os.path.dirname(__file__))
from notion_client import NotionClient, NotionAPIError, NotionConfigError

# .env dosyasını yükle
load_dotenv()

# ─────────────────────────────────────────────
#  Loglama
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger("LifeOS.API")

# ─────────────────────────────────────────────
#  FastAPI Uygulaması
# ─────────────────────────────────────────────
app = FastAPI(
    title="LifeOS API",
    description="Notion tabanlı kişisel yaşam sistemi için RESTful API",
    version="1.0.0",
    docs_url="/docs",       # Swagger UI → http://localhost:8000/docs
    redoc_url="/redoc",     # ReDoc     → http://localhost:8000/redoc
)

# CORS Ayarları — Frontend'in (HTML dosyası) API'ye erişebilmesi için
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Üretimde bunu kısıtlayın! (ör: ["http://localhost:3000"])
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────
#  Notion Client — Singleton
# ─────────────────────────────────────────────
try:
    notion = NotionClient()
    logger.info("Notion bağlantısı kuruldu.")
except NotionConfigError as e:
    logger.critical("Notion yapılandırma hatası: %s", e)
    notion = None


def get_notion() -> NotionClient:
    """Notion client'ı döndürür, yoksa 503 hatası fırlatır."""
    if notion is None:
        raise HTTPException(
            status_code=503,
            detail="Notion bağlantısı kurulamadı. .env dosyasını kontrol edin."
        )
    return notion


# ─────────────────────────────────────────────
#  Pydantic Modelleri (Request/Response şemaları)
# ─────────────────────────────────────────────

class TaskCreate(BaseModel):
    """Yeni görev oluşturma isteği şeması."""
    title: str = Field(..., min_length=1, max_length=200, description="Görev başlığı")
    type: Optional[str] = Field(
        default="Görev",
        description="Görev türü: 'Rutin', 'Görev' veya 'Dinlenme'"
    )
    priority: Optional[str] = Field(
        default="Orta",
        description="Öncelik: 'Yüksek', 'Orta', 'Düşük'"
    )
    date: Optional[str] = Field(
        default=None,
        description="Tarih (YYYY-MM-DD formatında). Boş bırakılırsa bugün."
    )

    class Config:
        json_schema_extra = {
            "example": {
                "title": "Sabah meditasyonu",
                "type": "Rutin",
                "priority": "Yüksek",
                "date": "2026-07-20"
            }
        }


class TaskUpdate(BaseModel):
    """Görev güncelleme isteği şeması."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    priority: Optional[str] = Field(None)
    date: Optional[str] = Field(None)
    done: Optional[bool] = Field(None)


class JournalCreate(BaseModel):
    """Yeni günlük girişi oluşturma şeması."""
    content: str = Field(..., min_length=1, description="Günlük notu")
    category: Optional[str] = Field(None, description="Kategori (ör: Yazılım, Beslenme)")
    date: Optional[str] = Field(None, description="Tarih (YYYY-MM-DD)")
    time: Optional[str] = Field(None, description="Saat (HH:MM)")


class APIResponse(BaseModel):
    """Standart API yanıt şeması."""
    success: bool
    message: str
    data: Optional[dict] = None


class AIParseRequest(BaseModel):
    prompt: str = Field(..., description="Doğal dildeki kullanıcı komutu")

class SecondBrainCreate(BaseModel):
    title: str = Field(..., min_length=1)
    content: Optional[str] = Field(None)
    tags: Optional[list] = Field(default_factory=list)
    date: Optional[str] = Field(None)

class ChatRequest(BaseModel):
    message: str = Field(...)


# ─────────────────────────────────────────────
#  YARDIMCI FONKSİYON: Hata Dönüştürücü
# ─────────────────────────────────────────────

def handle_notion_error(e: NotionAPIError) -> HTTPException:
    """NotionAPIError'ı uygun HTTP hata koduna dönüştürür."""
    status_map = {
        400: 400,
        401: 401,
        403: 403,
        404: 404,
        408: 504,  # Notion timeout → Gateway Timeout
        429: 429,
        500: 502,  # Notion server error → Bad Gateway
        503: 503,
    }
    http_code = status_map.get(e.status_code, 500)
    return HTTPException(status_code=http_code, detail=e.message)


# ═════════════════════════════════════════════
#  ENDPOINT'LER
# ═════════════════════════════════════════════

# ─── GENEL ───────────────────────────────────

@app.get("/", tags=["Genel"])
async def root():
    """API sağlık kontrolü."""
    return {
        "status": "online",
        "app": "LifeOS API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health", tags=["Genel"])
async def health_check():
    """Notion bağlantısını da test eden kapsamlı sağlık kontrolü."""
    client = get_notion()
    return {
        "status": "healthy",
        "notion_connected": client is not None,
        "timestamp": date.today().isoformat()
    }


# ─── PROJELER ────────────────────────────────

@app.get("/api/projects", tags=["Projeler"])
async def get_projects(
    status: Optional[str] = Query(
        default=None,
        description="Durum filtresi: 'Aktif', 'Tamamlandı', 'Beklemede'"
    )
):
    """
    Notion'dan proje listesini getirir.

    - **status**: Opsiyonel durum filtresi. Belirtilmezse tüm projeler gelir.
    """
    client = get_notion()
    try:
        projects = client.get_projects(status_filter=status)
        return {
            "success": True,
            "count": len(projects),
            "data": projects
        }
    except NotionAPIError as e:
        raise handle_notion_error(e)


# ─── GÖREVLER / RUTİNLER ─────────────────────

@app.get("/api/tasks", tags=["Görevler"])
async def get_tasks(
    date: Optional[str] = Query(
        default=None,
        description="Tarih filtresi (YYYY-MM-DD). Boş bırakılırsa bugün."
    ),
    show_completed: bool = Query(
        default=False,
        description="True: tamamlananları da göster. False: sadece aktifler."
    )
):
    """
    Notion'dan görev ve rutin listesini getirir.

    - **date**: Hangi günün görevleri? Boş = bugün.
    - **show_completed**: Tamamlananlar dahil edilsin mi?
    """
    client = get_notion()
    try:
        tasks = client.get_routines_and_tasks(
            show_completed=show_completed,
            date_filter=date
        )
        return {
            "success": True,
            "count": len(tasks),
            "date": date or str(__import__('datetime').date.today()),
            "data": tasks
        }
    except NotionAPIError as e:
        raise handle_notion_error(e)


@app.post("/api/tasks", status_code=201, tags=["Görevler"])
async def create_task(task: TaskCreate):
    """
    Notion'a yeni görev/rutin ekler.

    **Zorunlu:** title  
    **Opsiyonel:** type ('Rutin'/'Görev'/'Dinlenme'), priority, date
    """
    client = get_notion()

    # Tarih belirtilmemişse bugünü kullan
    task_data = task.model_dump()
    if not task_data.get("date"):
        task_data["date"] = date.today().isoformat()

    try:
        created = client.create_task(task_data)
        return {
            "success": True,
            "message": f"'{task.title}' başarıyla eklendi.",
            "data": created
        }
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except NotionAPIError as e:
        raise handle_notion_error(e)


@app.patch("/api/tasks/{task_id}/toggle", tags=["Görevler"])
async def toggle_task(task_id: str):
    """
    Görevin tamamlandı/tamamlanmadı durumunu tersine çevirir.

    - **task_id**: Notion sayfa ID'si
    """
    client = get_notion()
    try:
        updated = client.toggle_task_done(task_id)
        status_text = "tamamlandı ✅" if updated["is_done"] else "tekrar açıldı"
        return {
            "success": True,
            "message": f"Görev {status_text}.",
            "data": updated
        }
    except NotionAPIError as e:
        raise handle_notion_error(e)


@app.patch("/api/tasks/{task_id}", tags=["Görevler"])
async def update_task(task_id: str, updates: TaskUpdate):
    """
    Görevin belirtilen alanlarını günceller.

    - **task_id**: Notion sayfa ID'si
    """
    client = get_notion()

    # None olan alanları çıkar
    update_data = {k: v for k, v in updates.model_dump().items() if v is not None}

    if not update_data:
        raise HTTPException(
            status_code=422,
            detail="Güncellenecek en az bir alan belirtilmelidir."
        )

    try:
        updated = client.update_task(task_id, update_data)
        return {
            "success": True,
            "message": "Görev güncellendi.",
            "data": updated
        }
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except NotionAPIError as e:
        raise handle_notion_error(e)


# ─── GÜNLÜKLER (JOURNALS) ────────────────────

@app.get("/api/journals", tags=["Günlükler"])
async def get_journals():
    """Notion'dan günlük listesini getirir."""
    client = get_notion()
    try:
        journals = client.get_journals()
        return {
            "success": True,
            "count": len(journals),
            "data": journals
        }
    except NotionAPIError as e:
        raise handle_notion_error(e)

@app.post("/api/journals", status_code=201, tags=["Günlükler"])
async def create_journal(journal: JournalCreate):
    """Notion'a yeni günlük/not ekler."""
    client = get_notion()
    journal_data = journal.model_dump()
    if not journal_data.get("date"):
        journal_data["date"] = date.today().isoformat()
    try:
        created = client.create_journal(journal_data)
        return {
            "success": True,
            "message": "Günlük başarıyla eklendi.",
            "data": created
        }
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except NotionAPIError as e:
        raise handle_notion_error(e)

@app.delete("/api/journals/{journal_id}", tags=["Günlükler"])
async def delete_journal(journal_id: str):
    """Günlük girişini siler (arşivler)."""
    client = get_notion()
    try:
        client.delete_journal(journal_id)
        return {
            "success": True,
            "message": "Günlük silindi."
        }
    except NotionAPIError as e:
        raise handle_notion_error(e)


# ─── İKİNCİ BEYİN (SECOND BRAIN) ─────────────

@app.get("/api/second-brain", tags=["İkinci Beyin"])
async def get_second_brain():
    client = get_notion()
    try:
        notes = client.get_second_brain_notes()
        return {"success": True, "data": notes}
    except NotionAPIError as e:
        raise handle_notion_error(e)

@app.post("/api/second-brain", status_code=201, tags=["İkinci Beyin"])
async def create_second_brain(note: SecondBrainCreate):
    client = get_notion()
    note_data = note.model_dump()
    if not note_data.get("date"):
        note_data["date"] = date.today().isoformat()
    try:
        created = client.create_second_brain_note(note_data)
        return {"success": True, "data": created}
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except NotionAPIError as e:
        raise handle_notion_error(e)


# ─────────────────────────────────────────────
#  AI Asistan (Groq)
# ─────────────────────────────────────────────
@app.post("/api/ai-parse")
def ai_parse(req: AIParseRequest):
    import requests
    import json
    import datetime
    
    groq_api_key = os.getenv("GROQ_API_KEY")
    if not groq_api_key:
        raise HTTPException(status_code=500, detail="GROQ_API_KEY bulunamadı.")
        
    client = get_notion()
    try:
        # Son/Gelecek 30 kaydı çekip bağlam olarak veriyoruz ki ID'leri görebilsin
        journals = client.get_journals()[:30]
    except Exception:
        journals = []
        
    journals_context = json.dumps(journals, ensure_ascii=False)
    
    current_date = datetime.date.today().strftime("%Y-%m-%d")
    system_prompt = f"""You are a scheduling AI for LifeOS.
The user will give you a natural language command in Turkish to ADD, UPDATE, or DELETE events.
You have access to the user's existing events in the context below.

EXISTING EVENTS (CONTEXT):
{journals_context}

CRITICAL: Return ONLY a JSON array. No extra text, no markdown block wrapping if possible.
Each object in the array must have:
- "action": "add", "update", or "delete"
- "id": The string ID of the event (ONLY required if action is "update" or "delete", find it from EXISTING EVENTS based on context)
- "category" (string): exact category (e.g., Beslenme, Spotify, Yazılım, Gelişim, Spor, Netflix, vb.)
- "date" (string): YYYY-MM-DD. Today is {current_date}. 
- "time" (string): HH:MM.
- "content" (string): The task description.

If updating, provide the "id" and the new values for category, date, time, and content.
If deleting, provide only "action" and "id".
If adding, provide action, category, date, time, and content.

Example input: "30 temmuz 14:00 spor ekle"
Output:
[
  {{"action": "add", "category": "Spor", "date": "2026-07-30", "time": "14:00", "content": "Spor"}}
]

Example input: "Bugünkü 12:00 sporu sil" (Assuming ID 'abc' exists for today 12:00 spor)
Output:
[
  {{"action": "delete", "id": "abc"}}
]

Example input: "Yarınki sporu müziğe çevir ve 15:00 yap" (Assuming ID 'xyz' is tomorrow's spor)
Output:
[
  {{"action": "update", "id": "xyz", "category": "Müzik", "time": "15:00", "content": "Müzik dinletisi"}}
]
"""
    
    headers = {
        "Authorization": f"Bearer {groq_api_key}",
        "Content-Type": "application/json"
    }
    data = {
        "model": "llama-3.1-8b-instant",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": req.prompt}
        ],
        "temperature": 0.2
    }
    
    try:
        response = requests.post("https://api.groq.com/openai/v1/chat/completions", headers=headers, json=data)
        response.raise_for_status()
        resp_json = response.json()
        content = resp_json["choices"][0]["message"]["content"]
        
        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        
        actions = json.loads(content.strip())
        
        # İşlemleri Backend'de yürüt
        results = {"added": 0, "updated": 0, "deleted": 0}
        for action_obj in actions:
            action = action_obj.get("action")
            if action == "add":
                payload = {
                    "content": action_obj.get("content", "Yeni Etkinlik"),
                    "category": action_obj.get("category", "Gelişim"),
                    "date": action_obj.get("date", current_date),
                    "time": action_obj.get("time", "12:00")
                }
                client.create_journal(payload)
                results["added"] += 1
            elif action == "update":
                eid = action_obj.get("id")
                if eid:
                    updates = {}
                    if "content" in action_obj: updates["content"] = action_obj["content"]
                    if "category" in action_obj: updates["category"] = action_obj["category"]
                    if "date" in action_obj: updates["date"] = action_obj["date"]
                    if "time" in action_obj: updates["time"] = action_obj["time"]
                    client.update_journal(eid, updates)
                    results["updated"] += 1
            elif action == "delete":
                eid = action_obj.get("id")
                if eid:
                    client.delete_journal(eid)
                    results["deleted"] += 1
                    
        return {"success": True, "results": results}
    except Exception as e:
        logger.error(f"AI Parse Hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/chat")
def chat_with_assistant(req: ChatRequest):
    import requests
    import json
    import datetime
    
    groq_api_key = os.getenv("GROQ_API_KEY")
    if not groq_api_key:
        raise HTTPException(status_code=500, detail="GROQ_API_KEY bulunamadı.")
        
    client = get_notion()
    
    # Verileri topla (Context limitini aşmamak için en fazla son 20 kayıt vb. alabiliriz, şimdilik tümünü alıyoruz)
    try:
        tasks = client.get_routines_and_tasks(show_completed=False)[:20]
        journals = client.get_journals()[:20]
        sb_notes = client.get_second_brain_notes()[:20]
    except Exception:
        tasks = []
        journals = []
        sb_notes = []

    context_str = f"BUGÜNÜN TARİHİ: {datetime.date.today().strftime('%Y-%m-%d')}\n\n"
    context_str += "KULLANICININ GÜNCEL GÖREVLERİ:\n" + json.dumps(tasks, ensure_ascii=False) + "\n\n"
    context_str += "KULLANICININ SON GÜNLÜK KAYITLARI:\n" + json.dumps(journals, ensure_ascii=False) + "\n\n"
    context_str += "KULLANICININ İKİNCİ BEYİN NOTLARI:\n" + json.dumps(sb_notes, ensure_ascii=False) + "\n"

    system_prompt = f"""Sen LifeOS'in zeki kişisel asistanı "Z-Asistan"sın. 
Kullanıcının Notion sistemindeki güncel verilerine erişimin var. 
Senin görevin kullanıcının sorularını bu verilere dayanarak kısa, net, samimi ve motive edici bir dille cevaplamaktır.

KULLANICININ VERİLERİ (Context):
{context_str}

Lütfen sadece sana sorulan soruya odaklan. Soru verilerle ilgiliyse verileri analiz et. Eğer soru genel bir sohbetse doğal cevap ver. Markdown kullanabilirsin."""

    headers = {
        "Authorization": f"Bearer {groq_api_key}",
        "Content-Type": "application/json"
    }
    data = {
        "model": "llama-3.1-8b-instant",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": req.message}
        ],
        "temperature": 0.5
    }
    
    try:
        response = requests.post("https://api.groq.com/openai/v1/chat/completions", headers=headers, json=data)
        response.raise_for_status()
        resp_json = response.json()
        answer = resp_json["choices"][0]["message"]["content"]
        return {"success": True, "answer": answer}
    except Exception as e:
        logger.error(f"AI Parse Hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  Sunucuyu Başlat
# ─────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    debug = os.getenv("DEBUG", "True").lower() == "true"

    logger.info("LifeOS API başlatılıyor → http://%s:%d", host, port)
    logger.info("Swagger UI → http://localhost:%d/docs", port)

    uvicorn.run(
        "api:app",
        host=host,
        port=port,
        reload=debug,   # Debug modda dosya değişince otomatik yeniden başlar
        log_level="info"
    )
