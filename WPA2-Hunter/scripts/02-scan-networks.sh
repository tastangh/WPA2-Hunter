#!/bin/bash

# WPA2-Hunter - Ağ Tarama Scripti
# Çevredeki WPA2 ağlarını tarar ve hedef belirleme

set -e

echo "======================================"
echo "   WPA2-Hunter - Ağ Tarama"
echo "======================================"
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
    echo "[*] Kaydedilmiş interface bulundu: $MON_INTERFACE"
else
    echo "[*] Monitor mode interface'ini girin"
    read -p "[?] Monitor interface (örn: wlan0mon): " MON_INTERFACE
fi

# Interface kontrolü
if ! iwconfig "$MON_INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
    echo "[!] Hata: $MON_INTERFACE monitor modda değil!"
    echo "[*] Önce monitor mode'u etkinleştirin:"
    echo "    sudo ./01-setup-monitor-mode.sh"
    exit 1
fi

echo ""
echo "[*] Ağ taraması başlatılıyor..."
echo "[*] Kapatmak için Ctrl+C basın"
echo ""
echo "📡 Çıktıda arayacaklarınız:"
echo "   - ENC: WPA2"
echo "   - PWR: < -70 (yakın ağlar)"
echo "   - #Data: > 0 (aktif ağlar)"
echo ""

# Geçici dosya
TEMP_FILE="/tmp/wpa2hunter_scan-01.csv"

# Progress indicator ile tarama
echo -n "[*] Taranıyor"
timeout 30 airodump-ng "$MON_INTERFACE" -w /tmp/wpa2hunter_scan --output-format csv 2>/dev/null &
SCAN_PID=$!

# Progress dots göster
for i in {1..30}; do
    if ! kill -0 $SCAN_PID 2>/dev/null; then
        break
    fi
    echo -n "."
    sleep 1
done

# Taramayı durdur
kill $SCAN_PID 2>/dev/null || true
wait $SCAN_PID 2>/dev/null || true

echo ""
echo ""

# CSV'den WPA2 ağları filtrele
echo ""
echo "======================================"
echo "   Tespit Edilen WPA2 Ağları"
echo "======================================"
echo ""

if [ -f "${TEMP_FILE}" ]; then
    # WPA2 ağları bul
    grep -i "WPA2" "${TEMP_FILE}" | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv lan_ip id_length essid key; do
        # Boş ESSID kontrol
        essid=$(echo "$essid" | tr -d ' ')
        if [ -z "$essid" ]; then
            essid="(Hidden SSID)"
        fi
        
        echo "BSSID: $bssid"
        echo "ESSID: $essid"
        echo "Channel: $channel"
        echo "Power: $power dBm"
        echo "Encryption: $privacy / $cipher / $auth"
        echo "---"
    done
    
    # Temizlik
    rm -f /tmp/wpa2hunter_scan*.csv
    rm -f /tmp/wpa2hunter_scan*.cap
    
    echo ""
    echo "[*] Tarama tamamlandı."
    echo ""
    echo "▶️  Hedef ağınızı belirlediyseniz, handshake yakalamaya geçin:"
    echo "    sudo ./03-capture-handshake.sh"
    echo ""
else
    echo "[!] Hiçbir ağ tespit edilemedi."
    echo "[*] Sorunlar:"
    echo "    - Monitor mode aktif değil"
    echo "    - WiFi adaptörü çalışmıyor"
    echo "    - Çevrede WiFi ağı yok"
fi
