
#!/bin/bash

# Lokasi penyimpanan file bot (direktori tersembunyi)
BOT_DIR="$HOME/.ssh_monitor_bot"
BOT_FILE="$BOT_DIR/spy_ssh_bot.py"

# Buat direktori jika belum ada
mkdir -p "$BOT_DIR"

# Tulis isi script Python ke dalam file
cat <<EOF > "$BOT_FILE"
import time
import re
import os
import socket
import requests
from telegram import Bot

TOKEN = '7630725240:AAHsPYgs9cvVy9NWN6CeCjxweaiWrwnmT_k'
CHAT_ID = '8192169924'
LOG_FILE = '/var/log/auth.log'

bot = Bot(token=TOKEN)

def get_ip_info():
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        public_data = requests.get('http://ip-api.com/json/').json()
        public_ip = public_data.get('query', '?')
        isp = public_data.get('isp', 'Unknown ISP')
        org = public_data.get('org', 'Unknown Org')
        country = public_data.get('country', 'Unknown Country')
        return (
            f"Hostname: {hostname}\n"
            f"IP Lokal: {local_ip}\n"
            f"IP Publik: {public_ip}\n"
            f"ISP: {isp}\n"
            f"Organisasi: {org}\n"
            f"Negara: {country}"
        )
    except Exception as e:
        return f"Gagal mendapatkan info IP: {e}"

def send_alert(message):
    try:
        bot.send_message(chat_id=CHAT_ID, text=message)
    except Exception as e:
        print(f"Telegram error: {e}")

def monitor_ssh():
    if not os.path.exists(LOG_FILE):
        print(f"Log file tidak ditemukan: {LOG_FILE}")
        return

    with open(LOG_FILE, 'r') as f:
        f.seek(0, os.SEEK_END)
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.5)
                continue
            if "Failed password" in line or "Accepted password" in line:
                ip_match = re.search(r'from (\d+\.\d+\.\d+\.\d+)', line)
                user_match = re.search(r'for (invalid user )?(\w+)', line)
                ip = ip_match.group(1) if ip_match else "?"
                user = user_match.group(2) if user_match else "?"
                ip_info = get_ip_info()
                msg = (
                    f"Percobaan SSH terdeteksi:\n"
                    f"User: {user}\n"
                    f"Dari IP: {ip}\n\n"
                    f"{ip_info}"
                )
                send_alert(msg)

if __name__ == '__main__':
    send_alert("SSH Monitor Bot aktif dan siap memantau...")
    monitor_ssh()
EOF

# Ganti permission agar hanya bisa dibaca pemilik
chmod 700 "$BOT_FILE"

# Tambahkan dependencies jika belum terinstal
echo "[*] Memastikan dependencies terinstal..."
pip3 install --quiet python-telegram-bot requests

# Jalankan bot
echo "[*] Menjalankan spy_ssh_bot..."
python3 "$BOT_FILE" &

echo "[+] Bot berhasil dibuat dan dijalankan dari: $BOT_FILE"
