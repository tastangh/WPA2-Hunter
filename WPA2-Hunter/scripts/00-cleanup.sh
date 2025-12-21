#!/bin/bash

# WPA2-Hunter - Hızlı Temizlik ve Reset Scripti
# Tüm işlemleri durdurur ve sistemi sıfırlar

echo "========================================"
echo "   WPA2-Hunter - Sistem Temizliği"
echo "========================================"
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo "[!] Bu script root yetkileri gerektirir!"
    echo "    Kullanım: sudo $0"
    exit 1
fi

echo "[*] Çalışan işlemler durduruluyor..."
pkill -9 airodump-ng 2>/dev/null || true
pkill -9 aireplay-ng 2>/dev/null || true
pkill -9 aircrack-ng 2>/dev/null || true

echo "[*] Monitor mode kapatılıyor..."
airmon-ng stop wlan0mon 2>/dev/null || true
airmon-ng stop wlan0 2>/dev/null || true

echo "[*] NetworkManager yeniden başlatılıyor..."
systemctl restart NetworkManager

echo "[*] Geçici dosyalar temizleniyor..."
rm -f /tmp/wpa2hunter_*.conf
rm -f /tmp/wpa2hunter_scan*.csv
rm -f /tmp/wpa2hunter_scan*.cap

echo ""
echo "✅ Temizlik tamamlandı!"
echo ""
echo "[*] Şimdi saldırıya başlayabilirsiniz:"
echo "    sudo ./01-setup-monitor-mode.sh"
echo ""
