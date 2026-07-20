"""
=============================================================
  LifeOS — Notion API İstemcisi (notion_client.py)
=============================================================
  Bu modül, Notion API ile tüm iletişimi yönetir.

  KURULUM:
  1. Proje kökünde bir .env dosyası oluşturun.
  2. Aşağıdaki değişkenleri .env dosyasına ekleyin:

     NOTION_TOKEN=secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     PROJECTS_DB_ID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     ROUTINES_DB_ID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     JOURNALS_DB_ID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  NOTION TOKEN NASIL ALINIR?
  → https://www.notion.so/my-integrations adresine gidin,
    yeni bir "Internal Integration" oluşturun ve token'ı kopyalayın.

  DATABASE ID NASIL ALINIR?
  → Notion'da ilgili database sayfasını açın.
  → URL şu formatta görünür:
    https://www.notion.so/{workspace}/{DATABASE_ID}?v=...
  → DATABASE_ID kısmını (32 karakterlik hex string) kopyalayın.
  → Ayrıca ilgili sayfaya sağ tıklayıp "Connect to" > Integration adınızı seçin!
=============================================================
"""

import os
import logging
from datetime import date
from typing import Optional
import requests
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

# Loglama yapılandırması
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("LifeOS.NotionClient")


# ─────────────────────────────────────────────
#  Özel Hata Sınıfları
# ─────────────────────────────────────────────

class NotionAPIError(Exception):
    """Notion API'den dönen HTTP hataları için."""
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message
        super().__init__(f"[HTTP {status_code}] {message}")


class NotionConfigError(Exception):
    """Eksik veya hatalı yapılandırma için."""
    pass


# ─────────────────────────────────────────────
#  Ana İstemci Sınıfı
# ─────────────────────────────────────────────

class NotionClient:
    """
    Notion API ile tüm iletişimi yöneten istemci sınıfı.

    Desteklenen operasyonlar:
    - Proje listesini getir (GET)
    - Rutin/görev listesini getir (GET)
    - Yeni görev ekle (POST)
    - Görevi güncelle (PATCH)
    - Görevi tamamlandı olarak işaretle (PATCH)
    """

    # Notion API sabitleri
    BASE_URL = "https://api.notion.com/v1"
    API_VERSION = "2022-06-28"  # Notion API versiyonu

    def __init__(
        self,
        token: Optional[str] = None,
        projects_db_id: Optional[str] = None,
        routines_db_id: Optional[str] = None,
        journals_db_id: Optional[str] = None,
    ):
        """
        NotionClient'ı başlatır.

        Parametreler önce doğrudan verilen argümanlardan,
        yoksa .env / ortam değişkenlerinden okunur.

        Args:
            token:          Notion Integration Secret Token
                            (ör: "secret_abc123...")
            projects_db_id: Projeler veritabanının ID'si
                            (ör: "a1b2c3d4e5f6...")
            routines_db_id: Rutinler veritabanının ID'si
                            (ör: "f6e5d4c3b2a1...")
        """
        # Token ve DB ID'leri argümandan veya .env'den al
        self.token = token or os.getenv("NOTION_TOKEN")
        self.projects_db_id = projects_db_id or os.getenv("PROJECTS_DB_ID")
        self.routines_db_id = routines_db_id or os.getenv("ROUTINES_DB_ID")
        self.journals_db_id = journals_db_id or os.getenv("JOURNALS_DB_ID")
        self.second_brain_db_id = os.getenv("SECOND_BRAIN_DB_ID")

        # Zorunlu yapılandırma kontrolü
        self._validate_config()

        # Tüm istekler için ortak HTTP başlıkları
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Notion-Version": self.API_VERSION,
            "Content-Type": "application/json",
        }

        # requests.Session kullanmak bağlantıyı yeniden kullanır (performans)
        self.session = requests.Session()
        self.session.headers.update(self.headers)

        logger.info("NotionClient başarıyla başlatıldı.")

    def _validate_config(self):
        """Zorunlu yapılandırma değerlerinin varlığını kontrol eder."""
        missing = []
        if not self.token:
            missing.append("NOTION_TOKEN")
        if not self.projects_db_id:
            missing.append("PROJECTS_DB_ID")
        if not self.routines_db_id:
            missing.append("ROUTINES_DB_ID")
        if not self.journals_db_id:
            missing.append("JOURNALS_DB_ID")
        if not self.second_brain_db_id:
            missing.append("SECOND_BRAIN_DB_ID")

        if missing:
            raise NotionConfigError(
                f"Eksik yapılandırma değerleri: {', '.join(missing)}\n"
                "Lütfen .env dosyanızı kontrol edin."
            )

    def _handle_response(self, response: requests.Response) -> dict:
        """
        API yanıtını işler ve hata kontrolü yapar.

        Args:
            response: requests kütüphanesinden gelen yanıt nesnesi

        Returns:
            JSON formatında ayrıştırılmış yanıt verisi

        Raises:
            NotionAPIError: API hata döndürdüğünde
        """
        try:
            data = response.json()
        except ValueError:
            raise NotionAPIError(
                response.status_code,
                f"Geçersiz JSON yanıtı: {response.text[:200]}"
            )

        if response.status_code == 200:
            return data

        # Notion'ın hata mesajını al
        error_msg = data.get("message", "Bilinmeyen hata")
        error_code = data.get("code", "unknown")

        # HTTP durum koduna göre anlamlı hata mesajları
        status_messages = {
            400: f"Geçersiz istek gövdesi — {error_msg}",
            401: "Kimlik doğrulama hatası. Token'ınızı kontrol edin.",
            403: "Erişim reddedildi. Integration'ın veritabanına bağlı olduğundan emin olun.",
            404: "Kaynak bulunamadı. Database ID'yi kontrol edin.",
            409: f"Çakışma hatası — {error_msg}",
            429: "İstek sınırı aşıldı (Rate limit). Lütfen bekleyin.",
            500: "Notion sunucu hatası. Daha sonra tekrar deneyin.",
        }

        friendly_msg = status_messages.get(
            response.status_code,
            f"[{error_code}] {error_msg}"
        )

        logger.error("Notion API Hatası [%d]: %s", response.status_code, friendly_msg)
        raise NotionAPIError(response.status_code, friendly_msg)

    def _query_database(
        self,
        db_id: str,
        filter_payload: Optional[dict] = None,
        sorts: Optional[list] = None,
    ) -> list:
        """
        Belirtilen Notion veritabanını sorgular.
        Sayfalandırmayı (pagination) otomatik yönetir.

        Args:
            db_id:           Sorgulanacak veritabanının ID'si
            filter_payload:  Notion filter nesnesi (isteğe bağlı)
            sorts:           Sıralama kuralları listesi (isteğe bağlı)

        Returns:
            Sayfa (kayıt) nesnelerinin listesi
        """
        url = f"{self.BASE_URL}/databases/{db_id}/query"
        payload = {}
        if filter_payload:
            payload["filter"] = filter_payload
        if sorts:
            payload["sorts"] = sorts

        all_results = []
        has_more = True
        next_cursor = None

        # Notion sayfalandırmasını (pagination) yönet
        while has_more:
            if next_cursor:
                payload["start_cursor"] = next_cursor

            try:
                response = self.session.post(url, json=payload, timeout=15)
            except requests.exceptions.Timeout:
                logger.error("İstek zaman aşımına uğradı: %s", url)
                raise NotionAPIError(408, "İstek zaman aşımına uğradı.")
            except requests.exceptions.ConnectionError:
                logger.error("Bağlantı hatası: %s", url)
                raise NotionAPIError(503, "Notion'a bağlanılamadı. İnterneti kontrol edin.")

            data = self._handle_response(response)
            all_results.extend(data.get("results", []))
            has_more = data.get("has_more", False)
            next_cursor = data.get("next_cursor")

        logger.info("Veritabanı sorgusu tamamlandı. Toplam kayıt: %d", len(all_results))
        return all_results

    # ─── PUBLIC METODLAR ───────────────────────────────────────

    def get_projects(self, status_filter: Optional[str] = None) -> list:
        """
        Projeler veritabanından projeleri getirir ve işlenmiş formata dönüştürür.

        Args:
            status_filter: Opsiyonel durum filtresi.
                           Örn: "Aktif", "Tamamlandı", "Beklemede"
                           None ise tüm projeler getirilir.

        Returns:
            Her proje için işlenmiş sözlük listesi.
        """
        filter_payload = None
        if status_filter:
            filter_payload = {
                "property": "Select",  # ← Notion'daki durum sütununun ADI (Aktif/Beklemede/Tamamlandı)
                "select": {"equals": status_filter},
            }

        raw_pages = self._query_database(self.projects_db_id, filter_payload, sorts=None)
        return [self._parse_project(page) for page in raw_pages]

    def get_routines_and_tasks(
        self,
        show_completed: bool = False,
        date_filter: Optional[str] = None,
    ) -> list:
        """
        Rutinler/Görevler veritabanından kayıtları getirir.

        Args:
            show_completed: True ise tamamlananlar da dahil edilir.
                            False (varsayılan) ise yalnızca aktif görevler.
            date_filter:    "YYYY-MM-DD" formatında tarih filtresi.
                            None ise TÜM tarihler getirilir (takvim için gerekli).

        Returns:
            Her görev için işlenmiş sözlük listesi.
        """
        filter_conditions = []

        # Tarih filtresi (yalnızca açıkça istenirse uygulanır;
        # aksi halde tüm görevler döner — aylık takvim bunu gerektirir)
        if date_filter:
            filter_conditions.append({
                "property": "Date",  # ← Notion'daki tarih sütununun ADI
                "date": {"equals": date_filter},
            })

        # Tamamlanmamışları filtrele (isteğe bağlı)
        if not show_completed:
            filter_conditions.append({
                "property": "done",  # ← Notion'daki checkbox sütununun ADI
                "checkbox": {"equals": False},
            })

        # Birden fazla filtre varsa AND ile birleştir
        if len(filter_conditions) > 1:
            filter_payload = {"and": filter_conditions}
        elif len(filter_conditions) == 1:
            filter_payload = filter_conditions[0]
        else:
            filter_payload = None

        sorts = [
            {"property": "Priority", "direction": "descending"},
            {"property": "Date", "direction": "ascending"},
        ]

        raw_pages = self._query_database(self.routines_db_id, filter_payload, sorts)
        return [self._parse_task(page) for page in raw_pages]

    def create_task(self, task_data: dict) -> dict:
        """
        Rutinler/Görevler veritabanına yeni bir görev ekler.

        Args:
            task_data: Görev bilgilerini içeren sözlük:
                {
                    "title":    str (zorunlu) — Görev adı,
                    "type":     str           — "Rutin" veya "Görev",
                    "priority": str           — "Yüksek", "Orta", "Düşük",
                    "date":     str           — "YYYY-MM-DD" formatında tarih,
                }

        Returns:
            Oluşturulan görevin işlenmiş verisi

        Raises:
            ValueError: Zorunlu alanlar eksikse
            NotionAPIError: API hatası oluşursa
        """
        if not task_data.get("title"):
            raise ValueError("Görev başlığı (title) zorunludur.")

        url = f"{self.BASE_URL}/pages"

        # Notion sayfa oluşturma payload'u
        payload = {
            "parent": {"database_id": self.routines_db_id},
            "properties": {
                # ↓ "Name" yerine Notion'daki başlık sütununun ADI
                "content": {
                    "title": [{"text": {"content": task_data["title"]}}]
                },
                # ↓ "Done" yerine Notion'daki checkbox sütununun ADI
                "done": {
                    "checkbox": False
                },
            },
        }

        # Opsiyonel alanları ekle
        if task_data.get("type"):
            # ↓ "Type" yerine Notion'daki tip sütununun ADI
            payload["properties"]["Type"] = {
                "select": {"name": task_data["type"]}
            }

        if task_data.get("priority"):
            # ↓ "Priority" yerine Notion'daki öncelik sütununun ADI
            payload["properties"]["Priority"] = {
                "select": {"name": task_data["priority"]}
            }

        if task_data.get("date"):
            # ↓ "Date" yerine Notion'daki tarih sütununun ADI
            payload["properties"]["Date"] = {
                "date": {"start": task_data["date"]}
            }

        try:
            response = self.session.post(url, json=payload, timeout=15)
        except requests.exceptions.Timeout:
            raise NotionAPIError(408, "Görev oluşturma isteği zaman aşımına uğradı.")
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        created_page = self._handle_response(response)
        logger.info("Yeni görev oluşturuldu. ID: %s", created_page.get("id"))
        return self._parse_task(created_page)

    def toggle_task_done(self, task_id: str) -> dict:
        """
        Bir görevin 'Done' (tamamlandı) durumunu tersine çevirir.

        Args:
            task_id: Notion sayfa ID'si (görevin)

        Returns:
            Güncellenmiş görevin işlenmiş verisi
        """
        # Önce mevcut durumu oku
        get_url = f"{self.BASE_URL}/pages/{task_id}"
        try:
            get_response = self.session.get(get_url, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        page_data = self._handle_response(get_response)
        current_done = (
            page_data.get("properties", {})
            .get("done", {})  # ← Notion'daki checkbox sütununun ADI
            .get("checkbox", False)
        )

        # Durumu tersine çevir
        patch_url = f"{self.BASE_URL}/pages/{task_id}"
        payload = {
            "properties": {
                "done": {"checkbox": not current_done}  # ← Sütun adı
            }
        }

        try:
            response = self.session.patch(patch_url, json=payload, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        updated_page = self._handle_response(response)
        logger.info(
            "Görev durumu güncellendi. ID: %s | Done: %s → %s",
            task_id, current_done, not current_done
        )
        return self._parse_task(updated_page)

    def update_task(self, task_id: str, updates: dict) -> dict:
        """
        Bir görevin belirtilen alanlarını günceller.

        Args:
            task_id: Güncellenecek Notion sayfasının ID'si
            updates: Güncellenecek alan/değer çiftleri

        Returns:
            Güncellenmiş görevin işlenmiş verisi
        """
        url = f"{self.BASE_URL}/pages/{task_id}"
        properties = {}

        if "title" in updates:
            properties["content"] = {  # ← Başlık sütunu adı
                "title": [{"text": {"content": updates["title"]}}]
            }
        if "done" in updates:
            properties["done"] = {"checkbox": updates["done"]}  # ← Checkbox sütunu adı
        if "priority" in updates:
            properties["Priority"] = {"select": {"name": updates["priority"]}}  # ← Öncelik sütunu
        if "date" in updates:
            properties["Date"] = {"date": {"start": updates["date"]}}  # ← Tarih sütunu

        if not properties:
            raise ValueError("Güncellenecek en az bir alan belirtilmelidir.")

        try:
            response = self.session.patch(url, json={"properties": properties}, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        updated_page = self._handle_response(response)
        logger.info("Görev güncellendi. ID: %s", task_id)
        return self._parse_task(updated_page)

    def get_second_brain_notes(self) -> list:
        """İkinci Beyin veritabanındaki notları getirir."""
        sorts = [
            {"property": "Date", "direction": "descending"}
        ]
        raw_pages = self._query_database(self.second_brain_db_id, None, sorts)
        return [self._parse_second_brain_note(page) for page in raw_pages]

    # ─── JOURNAL (GÜNLÜK) METODLARI ─────────────────────────────

    def get_journals(self) -> list:
        """
        Journals veritabanından günlükleri getirir.
        """
        sorts = [
            {"property": "Date", "direction": "descending"},
            {"property": "Text", "direction": "descending"}
        ]
        raw_pages = self._query_database(self.journals_db_id, None, sorts)
        return [self._parse_journal(page) for page in raw_pages]

    def create_journal(self, journal_data: dict) -> dict:
        """
        Journals veritabanına yeni bir giriş ekler.
        """
        if not journal_data.get("content"):
            raise ValueError("İçerik zorunludur.")

        url = f"{self.BASE_URL}/pages"
        payload = {
            "parent": {"database_id": self.journals_db_id},
            "properties": {
                "content": {
                    "title": [{"text": {"content": journal_data["content"]}}]
                }
            },
        }

        if journal_data.get("category"):
            payload["properties"]["Select"] = {
                "select": {"name": journal_data["category"]}
            }
        
        if journal_data.get("date"):
            payload["properties"]["Date"] = {
                "date": {"start": journal_data["date"]}
            }
            
        if journal_data.get("time"):
            payload["properties"]["Text"] = {
                "rich_text": [{"text": {"content": journal_data["time"]}}]
            }

        try:
            response = self.session.post(url, json=payload, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        created_page = self._handle_response(response)
        return self._parse_journal(created_page)

    def update_journal(self, journal_id: str, updates: dict) -> dict:
        """Var olan bir journal (günlük/plan) kaydını günceller."""
        url = f"{self.BASE_URL}/pages/{journal_id}"
        payload = {"properties": {}}

        if "content" in updates and updates["content"] is not None:
            payload["properties"]["content"] = {
                "title": [{"text": {"content": updates["content"]}}]
            }
        
        if "category" in updates and updates["category"] is not None:
            payload["properties"]["Select"] = {
                "select": {"name": updates["category"]}
            }
            
        if "date" in updates and updates["date"] is not None:
            payload["properties"]["Date"] = {
                "date": {"start": updates["date"]}
            }
            
        if "time" in updates and updates["time"] is not None:
            payload["properties"]["Text"] = {
                "rich_text": [{"text": {"content": updates["time"]}}]
            }

        try:
            response = self.session.patch(url, json=payload, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        updated_page = self._handle_response(response)
        return self._parse_journal(updated_page)

    def create_second_brain_note(self, note_data: dict) -> dict:
        """İkinci Beyin veritabanına yeni not ekler."""
        if not note_data.get("title"):
            raise ValueError("Başlık (title) zorunludur.")

        url = f"{self.BASE_URL}/pages"
        payload = {
            "parent": {"database_id": self.second_brain_db_id},
            "properties": {
                "Name": {
                    "title": [{"text": {"content": note_data["title"]}}]
                }
            },
        }

        if note_data.get("content"):
            payload["properties"]["Text"] = {
                "rich_text": [{"text": {"content": note_data["content"]}}]
            }
            
        if note_data.get("tags"):
            payload["properties"]["tags"] = {
                "multi_select": [{"name": tag} for tag in note_data["tags"]]
            }
        
        if note_data.get("date"):
            payload["properties"]["Date"] = {
                "date": {"start": note_data["date"]}
            }

        try:
            response = self.session.post(url, json=payload, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")

        created_page = self._handle_response(response)
        return self._parse_second_brain_note(created_page)

    def delete_journal(self, page_id: str) -> dict:
        """
        Bir günlük girişini arşivleyerek (silerek) kaldırır.
        """
        url = f"{self.BASE_URL}/pages/{page_id}"
        payload = {"archived": True}
        try:
            response = self.session.patch(url, json=payload, timeout=15)
        except requests.exceptions.ConnectionError:
            raise NotionAPIError(503, "Notion'a bağlanılamadı.")
            
        return self._handle_response(response)

    # ─── YARDIMCI PARSE METODLARI ───────────────────────────────

    def _parse_project(self, page: dict) -> dict:
        """
        Ham Notion sayfa nesnesini temiz bir proje sözlüğüne dönüştürür.

        NOT: Aşağıdaki 'property' anahtarları (.get("Status") gibi)
        Notion'daki sütun adlarınızla EŞLEŞMELİDİR.
        Notion veritabanınızdaki sütun adları farklıysa burayı güncelleyin!
        """
        props = page.get("properties", {})

        return {
            "id": page.get("id", ""),
            "title": self._get_title(props),
            "status": self._get_select(props, "Select"),              # ← Durum sütunu adı
            "priority": self._get_select(props, "Priority"),          # ← Öncelik sütunu adı
            "due_date": self._get_date(props, "Due Date"),            # ← Bitiş tarihi sütunu adı
            "description": self._get_rich_text(props, "Description"), # ← Açıklama sütunu adı
            "url": page.get("url", ""),
            "created_time": page.get("created_time", ""),
            "last_edited": page.get("last_edited_time", ""),
        }

    def _parse_task(self, page: dict) -> dict:
        """
        Ham Notion sayfa nesnesini temiz bir görev sözlüğüne dönüştürür.

        NOT: Aşağıdaki sütun adları Notion veritabanınızdaki gerçek
        sütun isimleriyle EŞLEŞMELİDİR.
        """
        props = page.get("properties", {})

        return {
            "id": page.get("id", ""),
            "title": self._get_title(props),
            "is_done": self._get_checkbox(props, "done"),    # ← Checkbox sütunu adı
            "type": self._get_select(props, "Type"),         # ← Tür sütunu adı
            "priority": self._get_select(props, "Priority"), # ← Öncelik sütunu adı
            "date": self._get_date(props, "Date"),           # ← Tarih sütunu adı
            "url": page.get("url", ""),
            "created_time": page.get("created_time", ""),
        }

    def _parse_journal(self, page: dict) -> dict:
        props = page.get("properties", {})
        return {
            "id": page.get("id", ""),
            "content": self._get_title(props),  # Gets title from any title property
            "category": self._get_select(props, "Select"),
            "date": self._get_date(props, "Date"),
            "time": self._get_rich_text(props, "Text"),
            "createdAt": page.get("created_time", ""),
        }

    def _parse_second_brain_note(self, page: dict) -> dict:
        props = page.get("properties", {})
        
        # Tags array extraction
        tags_data = props.get("tags", {}).get("multi_select", [])
        tags = [t.get("name") for t in tags_data]

        return {
            "id": page.get("id", ""),
            "title": self._get_title(props),
            "content": self._get_rich_text(props, "Text"),
            "tags": tags,
            "date": self._get_date(props, "Date"),
            "createdAt": page.get("created_time", ""),
        }

    # ─── ALT SEVİYE YARDIMCI METODLAR ──────────────────────────

    @staticmethod
    def _get_title(props: dict) -> str:
        """Title tipi property'den metin değerini çeker."""
        for key in ("Name", "Title", "name", "title", "content"):  # Yaygın başlık sütunu adları
            if key in props:
                title_list = props[key].get("title", [])
                if title_list:
                    return title_list[0].get("plain_text", "")
        return "(Başlıksız)"

    @staticmethod
    def _get_select(props: dict, key: str) -> str:
        """Select veya multi-select property'den değer çeker."""
        prop = props.get(key, {})
        # Tekli seçim (select)
        if "select" in prop and prop["select"]:
            return prop["select"].get("name", "")
        # Çoklu seçim (multi_select) — ilk değeri döndür
        if "multi_select" in prop and prop["multi_select"]:
            return prop["multi_select"][0].get("name", "")
        return ""

    @staticmethod
    def _get_checkbox(props: dict, key: str) -> bool:
        """Checkbox property'den boolean değer çeker."""
        return props.get(key, {}).get("checkbox", False)

    @staticmethod
    def _get_date(props: dict, key: str) -> str:
        """Date property'den başlangıç tarihini çeker."""
        date_prop = props.get(key, {}).get("date")
        if date_prop:
            return date_prop.get("start", "")
        return ""

    @staticmethod
    def _get_rich_text(props: dict, key: str) -> str:
        """Rich text property'den düz metin değerini çeker."""
        rich_text_list = props.get(key, {}).get("rich_text", [])
        if rich_text_list:
            return "".join(rt.get("plain_text", "") for rt in rich_text_list)
        return ""
