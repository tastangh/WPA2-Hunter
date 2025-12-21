# Captures Klasörü

Bu klasör, `airodump-ng` ile yakalanan WPA2 handshake paketlerini içerir.

## 📁 Dosya Türleri

Handshake yakalama sırasında birden fazla dosya oluşturulur:

### .cap Dosyası (Ana Dosya)
```
capture-01.cap
```
- **İçerik**: Yakalanan tüm 802.11 paketleri
- **Kullanım**: Parola kırma için bu dosya kullanılır
- **Araçlar**: Aircrack-ng, Hashcat, Wireshark

### .csv Dosyası
```
capture-01.csv
```
- **İçerik**: Tespit edilen ağlar ve istasyonların listesi
- **Format**: Excel/Google Sheets ile açılabilir

### .kismet.csv / .kismet.netxml
```
capture-01.kismet.csv
capture-01.kismet.netxml
```
- **İçerik**: Kismet IDS formatında meta veriler
- **Kullanım**: Opsiyonel, genellikle gerekmez

---

## ✅ Handshake Doğrulama

### Yöntem 1: Aircrack-ng ile

```bash
# Handshake kontrolü
aircrack-ng capture-01.cap
```

**Başarılı çıktı:**
```
Opening capture-01.cap
Reading packets, please wait...

   #  BSSID              ESSID                     Encryption
   1  AA:BB:CC:DD:EE:FF  MyHomeWiFi                WPA (1 handshake)

Index number of target network ? 
```

✅ "**1 handshake**" görüyorsanız başarılı!

---

### Yöntem 2: Wireshark ile

```bash
# Wireshark ile aç
wireshark capture-01.cap
```

**EAPOL filtresi uygula:**
```
eapol
```

**4-Way Handshake mesajlarını kontrol edin:**
1. Message 1 of 4
2. Message 2 of 4
3. Message 3 of 4
4. Message 4 of 4

Tüm 4 mesajı görüyorsanız ✅ handshake eksiksiz!

---

## 📋 Dosya Adlandırma

**Önerilen format:**
```
<hedef-ssid>-<tarih>-<numara>.cap
```

**Örnekler:**
```
MyHomeWiFi-2024-12-20-01.cap
OfficeNetwork-handshake-01.cap
test-capture-weak-password.cap
```

**Fayda:**
- Kolay tanımlama
- Çoklu yakalamalar arasında karışıklık önlenir

---

## 🔍 Handshake Kalitesini Değerlendirme

### İyi Kaliteli Handshake

✅ Tüm 4 mesaj mevcut  
✅ Sinyal gücü iyi (PWR > -70 dBm)  
✅ EAPOL paketleri eksiksiz  
✅ MIC değeri mevcut  

### Kötü Kaliteli Handshake

❌ Sadece 2-3 mesaj yakalanmış  
❌ Paketler hasarlı (corruption)  
❌ Yanlış BSSID  

**Çözüm:** Handshake'i yeniden yakalayın.

---

## 🚀 Handshake'i Kullanma

### Aircrack-ng ile Kırma

```bash
aircrack-ng -w /usr/share/wordlists/rockyou.txt -b AA:BB:CC:DD:EE:FF capture-01.cap
```

### Hashcat için Dönüştürme

```bash
# hcxtools ile dönüştür
hcxpcapngtool -o handshake.hc22000 capture-01.cap

# Hashcat ile kır
hashcat -m 22000 handshake.hc22000 wordlist.txt
```

---

## 🗂️ Arşivleme

Başarılı handshake'leri arşivleyin:

```bash
# Sıkıştırma
tar -czvf captures-archive-2024-12.tar.gz *.cap

# Başka bir konuma yedekleme
cp *.cap ~/Backups/WPA2-Captures/
```

---

## 🧹 Temizlik

Eski/gereksiz dosyaları temizleme:

```bash
# Sadece .cap dosyalarını sakla
rm -f *.csv *.kismet.csv *.kismet.netxml

# Geçersiz handshake'leri sil
# (Manuel olarak doğruladıktan sonra)
```

---

## 📊 Örnek Klasör İçeriği

Başarılı yakalama sonrası:

```
captures/
├── README.md
├── MyHomeWiFi-2024-12-20-01.cap       # ✅ Geçerli handshake
├── MyHomeWiFi-2024-12-20-01.csv
├── TestNetwork-failed-01.cap          # ❌ Geçersiz (silinecek)
└── OfficeWiFi-handshake-01.cap        # ✅ Geçerli handshake
```

---

## ⚠️ Güvenlik Notları

> [!CAUTION]
> **.cap dosyaları hassas veri içerir:**
> - Ağ MAC adresleri
> - SSID bilgileri
> - Handshake paketleri (şifre kırma için kullanılabilir)

**Güvenlik önerileri:**
- Dosyaları güvenli bir yerde saklayın
- Paylaşmayın (GitHub vb.)
- Proje bittiğinde şifreleyin veya silin
- `.gitignore`'a ekleyin:
  ```
  captures/*.cap
  captures/*.csv
  ```

---

**İlgili Scriptler:**
- `../scripts/03-capture-handshake.sh` - Handshake yakalama scripti
- `../scripts/05-crack-password.sh` - Yakalanan handshake'i kırma scripti

**İlgili Dokümantasyon:**
- `../docs/attack-methodology.md` - Handshake yakalama metodolojisi
- `../docs/troubleshooting.md` - Handshake yakalama sorunları
