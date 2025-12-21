# 🔐 WPA2-Hunter

**Kriptografi Dönem Ödevi - WPA2 Kimlik Doğrulama Saldırısı Eğitim Projesi**

## ⚠️ YASAL UYARI

> [!CAUTION]
> Bu proje **yalnızca eğitim amaçlıdır** ve kendi kontrollü ortamınızda, **açık izniniz olan** cihazlar üzerinde kullanılmalıdır. Başkalarının ağlarına izinsiz erişim girişimi **yasa dışıdır** ve ciddi yasal sonuçlar doğurabilir. Bu araçları kullanarak tüm yasal ve etik sorumlulukları kabul etmiş olursunuz.

## 📋 Proje Hakkında

Bu proje, WPA2-PSK kimlik doğrulama protokolündeki güvenlik açıklarını anlamak ve 4-Way Handshake sürecini incelemek için hazırlanmış kapsamlı bir eğitim kaynağıdır. Proje şunları içerir:

- **Teorik Altyapı**: PMK, PTK, MIC ve PBKDF2 gibi kriptografik kavramların detaylı açıklamaları
- **Pratik Uygulama**: Adım adım saldırı metodolojisi ve otomatik scriptler
- **Savunma Yöntemleri**: WPA3, güçlü parolalar ve modern güvenlik önlemleri

## 🎯 Proje Hedefleri

1. WPA2-PSK kimlik doğrulama sürecini derinlemesine anlamak
2. 4-Way Handshake protokolünün çalışma prensibini öğrenmek
3. Offline parola kırma saldırılarının nasıl çalıştığını kavramak
4. Bu tür saldırılara karşı etkili savunma yöntemlerini öğrenmek

## 🛠️ Gereksinimler

### Donanım
- **WiFi Adaptörü**: Monitor mode ve paket injection destekleyen
  - Önerilen: Alfa AWUS036 serisi
  - Uyumlu chipsetler: Atheros AR9271, Ralink RT3070, Realtek RTL8187
- **Hedef Cihazlar**: 
  - WPA2-PSK ile şifrelenmiş modem (kendi test modemiz)
  - İstemci cihaz (laptop/telefon)

### Yazılım (Kali Linux'ta Yüklü)
- `aircrack-ng` suite (airmon-ng, airodump-ng, aireplay-ng, aircrack-ng)
- `crunch` (parola listesi oluşturma - opsiyonel)
- `hashcat` (GPU hızlandırmalı kırma - opsiyonel)

## 📁 Proje Yapısı

```
WPA2-Hunter/
├── README.md                          # Bu dosya
├── docs/                              # Dokümantasyon
│   ├── theoretical-background.md      # Teorik altyapı (PMK, PTK, MIC)
│   ├── attack-methodology.md          # Adım adım saldırı rehberi
│   ├── prevention-methods.md          # Savunma ve önleme yöntemleri
│   └── troubleshooting.md             # Sorun giderme
├── scripts/                           # Otomasyon scriptleri
│   ├── 01-setup-monitor-mode.sh       # Monitor modu kurulum
│   ├── 02-scan-networks.sh            # Ağ tarama
│   ├── 03-capture-handshake.sh        # Handshake yakalama
│   ├── 04-deauth-attack.sh            # Deauth saldırısı
│   └── 05-crack-password.sh           # Parola kırma
├── wordlists/                         # Parola listeleri dizini
└── captures/                          # Yakalanan handshake'ler
```

## 🚀 Hızlı Başlangıç

### 1. Hazırlık
```bash
# WiFi adaptörünüzü takın ve tespit edildiğinden emin olun
iwconfig

# Gerekli araçların yüklü olduğunu kontrol edin
which airmon-ng airodump-ng aireplay-ng aircrack-ng
```

### 2. Monitor Modu Kurulumu
```bash
cd scripts
sudo ./01-setup-monitor-mode.sh
```

### 3. Ağ Tarama ve Hedef Belirleme
```bash
sudo ./02-scan-networks.sh
```

### 4. Handshake Yakalama
```bash
sudo ./03-capture-handshake.sh
```

### 5. Deauth Saldırısı (Gerekirse)
```bash
# Başka bir terminalde
sudo ./04-deauth-attack.sh
```

### 6. Parola Kırma
```bash
sudo ./05-crack-password.sh
```

## 📚 Dokümantasyon

Detaylı bilgi için `docs/` klasöründeki dokümantasyonu inceleyin:

- **[Teorik Altyapı](docs/theoretical-background.md)**: WPA2 kriptografisi, PBKDF2, PMK/PTK türetimi, MIC
- **[Saldırı Metodolojisi](docs/attack-methodology.md)**: Her adımın detaylı açıklaması
- **[Önleme Yöntemleri](docs/prevention-methods.md)**: WPA3, güçlü parolalar, güvenlik önlemleri
- **[Sorun Giderme](docs/troubleshooting.md)**: Sık karşılaşılan problemler ve çözümleri

## 🔬 Proje Adımları Özeti

1. **Keşif ve İzleme**: WiFi kartını monitor moduna alma
2. **Ağ Tespiti**: Çevredeki WPA2 ağlarını listeleme
3. **Handshake Yakalama**: 4-Way Handshake paketlerini .cap dosyasına kaydetme
4. **Deauth Saldırısı**: İstemciyi bağlantıyı koparmaya zorlayarak handshake tetikleme
5. **Doğrulama**: Handshake'in başarıyla yakalandığını kontrol etme
6. **Parola Kırma**: Dictionary attack veya brute force ile MIC karşılaştırması

## 🛡️ Savunma ve Önleme

Projenin bir parçası olarak şu savunma yöntemleri incelenmiştir:

- **WPA3 ve SAE**: Offline saldırılara karşı koruma
- **Güçlü Parolalar**: Minimum 16+ karakter, karmaşık, rastgele
- **PBKDF2 İterasyonları**: 4096 iterasyon sayesinde kırma süresinin artması
- **Ağ İzleme**: Anormal deauth paket tespiti

## 📖 Kaynaklar

- [IEEE 802.11i Standardı](https://standards.ieee.org/standard/802_11i-2004.html)
- [PBKDF2 RFC 2898](https://tools.ietf.org/html/rfc2898)
- [WPA3 Specification](https://www.wi-fi.org/discover-wi-fi/wi-fi-certified-wpa3)
- Aircrack-ng Resmi Dokümantasyonu

## 📝 Lisans

Bu proje eğitim amaçlı hazırlanmıştır. Kullanırken yerel yasalara ve etik kurallara uyunuz.

---

**Hazırlayan**: Kriptografi Dönem Ödevi  
**Tarih**: Aralık 2025  
**Platform**: Kali Linux
