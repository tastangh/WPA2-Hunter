#!/bin/bash

# WPA2-Hunter - Monitor Mode Kurulum Scripti
# Bu script WiFi adaptörünü monitor moduna alır

set -e  # Hata durumunda dur

echo "========================================"
echo "   WPA2-Hunter - Monitor Mode Kurulum"
echo "========================================"
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo "[!] Bu script root yetkileri gerektirir!"
    echo "    Kullanım: sudo $0"
    exit 1
fi

# WiFi interface tespit
echo "[*] WiFi interface'leri tespit ediliyor..."
echo ""
iwconfig 2>/dev/null | grep -v "no wireless" | grep "IEEE 802.11"

echo ""
read -p "[?] WiFi interface adını girin (örn: wlan0): " INTERFACE

# Interface kontrolü
if ! iwconfig "$INTERFACE" &>/dev/null; then
    echo "[!] Hata: $INTERFACE bulunamadı!"
    echo "[*] Mevcut interface'ler:"
    iwconfig 2>&1 | grep "IEEE"
    exit 1
fi

echo ""
echo "[*] Interface: $INTERFACE"
echo ""

# Uyarı
echo "⚠️  UYARI: Bu işlem mevcut WiFi bağlantınızı kesecektir!"
read -p "[?] Devam etmek istiyor musunuz? (e/h): " CONFIRM

if [ "$CONFIRM" != "e" ] && [ "$CONFIRM" != "E" ]; then
    echo "[!] İşlem iptal edildi."
    exit 0
fi

echo ""
echo "[*] Engelleyici servisler durduruluyor..."
airmon-ng check kill

echo ""
echo "[*] Monitor mode etkinleştiriliyor..."
airmon-ng start "$INTERFACE"

# Monitor interface adını tespit et
if iwconfig 2>/dev/null | grep -q "${INTERFACE}mon"; then
    MON_INTERFACE="${INTERFACE}mon"
else
    MON_INTERFACE="$INTERFACE"
fi

echo ""
echo "[*] Monitor mode doğrulanıyor..."
MODE=$(iwconfig "$MON_INTERFACE" 2>/dev/null | grep "Mode:" | awk '{print $4}' | cut -d':' -f2)

if [ "$MODE" = "Monitor" ]; then
    echo ""
    echo "✅ Başarılı! Monitor mode aktif"
    echo ""
    echo "Monitor Interface: $MON_INTERFACE"
    echo ""
    iwconfig "$MON_INTERFACE" 2>/dev/null | head -3
    echo ""
    echo "[*] Artık ağ taramasına geçebilirsiniz:"
    echo "    sudo ./02-scan-networks.sh"
    echo ""
else
    echo ""
    echo "❌ Hata: Monitor mode etkinleştirilemedi"
    echo "[*] Sorun giderme için troubleshooting.md dosyasını inceleyin"
    exit 1
fi

# Config dosyasına kaydet
echo "$MON_INTERFACE" > /tmp/wpa2hunter_interface.conf
echo "[*] Interface bilgisi kaydedildi: /tmp/wpa2hunter_interface.conf"
