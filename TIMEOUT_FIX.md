# Fix Timeout Error 524 - Cloudflare Tunnel

Error 524 terjadi karena proses instalasi Chamilo memakan waktu lama (membuat banyak tabel database), melebihi timeout default Cloudflare Tunnel.

## ✅ Perubahan yang Sudah Dilakukan

### 1. PHP Settings (Dockerfile)
- `max_execution_time = 0` (unlimited)
- `max_input_time = 600` (10 menit)
- `default_socket_timeout = 600` (10 menit)
- `memory_limit = 512M`

### 2. Apache Settings (000-default.conf)
- `Timeout = 600` (10 menit)
- `ProxyTimeout = 600` (10 menit)

## 🔧 Konfigurasi Cloudflare Tunnel

Cloudflare Tunnel memiliki timeout default **100 detik**. Untuk instalasi Chamilo yang memakan waktu lama, perlu increase timeout.

### Option 1: Increase Timeout di Cloudflare Tunnel Config

Edit file konfigurasi Cloudflare Tunnel Anda (biasanya `~/.cloudflared/config.yml`):

```yaml
tunnel: <your-tunnel-id>
credentials-file: /path/to/credentials.json

ingress:
  - hostname: lms.septadenita.my.id
    service: http://localhost:1234
    originRequest:
      # Increase timeout untuk long-running requests
      timeout: 10m  # 10 menit (default: 1m40s)
      connectTimeout: 30s
      tcpKeepAlive: 30s
      noHappyEyeballs: false
      keepAliveConnections: 100
      keepAliveTimeout: 90s
      httpHostHeader: lms.septadenita.my.id
  - service: http_status:404
```

### Option 2: Set via Environment Variable

Jika menjalankan cloudflared via command line:

```bash
cloudflared tunnel --config ~/.cloudflared/config.yml run \
  --proxy-connect-timeout 30s \
  --proxy-tcp-keepalive 30s
```

### Option 3: Set via Cloudflare Dashboard

1. Login ke Cloudflare Dashboard
2. Go to **Zero Trust** > **Networks** > **Tunnels**
3. Pilih tunnel Anda
4. Edit configuration
5. Tambahkan di `originRequest`:
   ```json
   {
     "timeout": "10m",
     "connectTimeout": "30s"
   }
   ```

## 🚀 Langkah Setelah Update

### 1. Rebuild Docker Image

```bash
docker compose build --no-cache chamilo_app
```

### 2. Restart Containers

```bash
docker compose restart chamilo_app
```

### 3. Restart Cloudflare Tunnel

```bash
# Jika running sebagai service
sudo systemctl restart cloudflared

# Jika running manual
# Stop dan start lagi dengan config baru
```

### 4. Coba Instalasi Lagi

Akses installer dan coba setup database lagi. Proses instalasi sekarang bisa berjalan hingga 10 menit tanpa timeout.

## 📝 Verifikasi Timeout Settings

### Check PHP Settings

```bash
docker compose exec chamilo_app php -i | grep -E "max_execution_time|max_input_time|default_socket_timeout"
```

Expected output:
```
max_execution_time => 0 => 0
max_input_time => 600 => 600
default_socket_timeout => 600 => 600
```

### Check Apache Timeout

```bash
docker compose exec chamilo_app apache2ctl -M | grep timeout
docker compose exec chamilo_app grep -i timeout /etc/apache2/apache2.conf
```

### Check Cloudflare Tunnel Logs

```bash
# Jika running sebagai service
sudo journalctl -u cloudflared -f

# Atau check log file
tail -f /var/log/cloudflared.log
```

## ⚠️ Troubleshooting

### Masih Timeout?

1. **Check Cloudflare Tunnel timeout setting:**
   ```bash
   # Test dengan curl langsung ke localhost
   curl -m 600 http://localhost:1234/main/install/index.php
   ```

2. **Monitor proses instalasi:**
   ```bash
   # Di terminal lain, monitor database
   docker compose exec chamilo_db mysql -u chamilo -pchamilo chamilo -e "SHOW TABLES;" | wc -l
   ```

3. **Check apakah ada error di logs:**
   ```bash
   docker compose logs -f chamilo_app
   docker compose logs -f chamilo_db
   ```

### Alternative: Install via CLI (Jika Masih Timeout)

Jika masih timeout, bisa install Chamilo via command line:

```bash
# Masuk ke container
docker compose exec chamilo_app bash

# Run installer via CLI (jika tersedia)
# Atau setup database manual
```

## 📚 References

- [Cloudflare Tunnel Configuration](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/)
- [Chamilo Installation Guide](https://docs.chamilo.org/)

