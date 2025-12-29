# Deployment Guide - lms.septadenita.my.id

Panduan lengkap untuk deploy Chamilo LMS ke production dengan domain `https://lms.septadenita.my.id/`

## 📋 Prerequisites

### 1. Server Requirements
- Ubuntu 20.04 LTS atau lebih baru (recommended)
- Docker & Docker Compose terinstall
- Nginx terinstall (untuk reverse proxy dan SSL)
- Domain DNS sudah pointing ke server IP

### 2. DNS Configuration

Pastikan DNS A record sudah dikonfigurasi:
```
Type: A
Name: lms
Domain: septadenita.my.id
Value: <IP_ADDRESS_SERVER>
TTL: 3600
```

Verifikasi DNS:
```bash
dig lms.septadenita.my.id
# atau
nslookup lms.septadenita.my.id
```

## 🚀 Step-by-Step Deployment

### Step 1: Clone Repository

```bash
cd /var/www  # atau direktori lain yang diinginkan
git clone <your-repo-url> chamilo-docker
cd chamilo-docker
```

### Step 2: Install Dependencies

```bash
# Install Docker (jika belum ada)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Nginx (jika belum ada)
sudo apt-get update
sudo apt-get install -y nginx wget unzip certbot python3-certbot-nginx

# Logout dan login lagi setelah install Docker
```

### Step 3: Download Chamilo dan Start Docker

```bash
chmod +x start.sh setup-chamilo.sh
./start.sh
```

Tunggu hingga download selesai dan container running.

### Step 4: Setup Nginx Reverse Proxy

```bash
# Copy Nginx configuration
sudo cp nginx-reverse-proxy.conf /etc/nginx/sites-available/lms.septadenita.my.id

# Enable site
sudo ln -s /etc/nginx/sites-available/lms.septadenita.my.id /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# If test passes, reload Nginx
sudo systemctl reload nginx
```

### Step 5: Setup SSL Certificate

```bash
# Make script executable
chmod +x setup-ssl.sh

# Run SSL setup (akan install Certbot dan setup certificate)
sudo ./setup-ssl.sh
```

Script akan:
- Install Certbot (Let's Encrypt)
- Obtain SSL certificate
- Configure Nginx untuk HTTPS
- Setup auto-renewal

**Note**: Jika script meminta email, masukkan email Anda untuk notifikasi renewal.

### Step 6: Verify Deployment

```bash
# Check Docker containers
docker compose ps

# Check Nginx status
sudo systemctl status nginx

# Check SSL certificate
sudo certbot certificates

# Test website
curl -I https://lms.septadenita.my.id
```

### Step 7: Access Chamilo Installation

Buka browser dan akses:
```
https://lms.septadenita.my.id
```

Atau untuk installation wizard:
```
https://lms.septadenita.my.id/main/install/index.php
```

## 🔧 Configuration

### Database Credentials (saat instalasi)

Gunakan credentials berikut saat instalasi via web:

- **Database Host**: `chamilo_db` (bukan localhost!)
- **Database Name**: `chamilo`
- **Database User**: `chamilo`
- **Database Password**: `chamilo`
- **Database Port**: `3306`

### Update Domain di Chamilo Configuration

Setelah instalasi, jika perlu update domain di configuration file:

```bash
docker compose exec chamilo_app nano /var/www/html/app/config/configuration.php
```

Atau edit melalui web interface: Administration > Configuration

## 🔒 Security Checklist

- [x] SSL certificate terinstall dan auto-renewal aktif
- [x] Nginx configured dengan security headers
- [x] HTTP redirect ke HTTPS
- [x] Docker containers running dengan user non-root
- [ ] Firewall configured (UFW atau iptables)
- [ ] Regular backups database dan files
- [ ] Monitoring setup (opsional)

### Setup Firewall (UFW)

```bash
# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

## 🔄 Update & Maintenance

### Update Chamilo

```bash
cd /var/www/chamilo-docker

# Stop containers
docker compose down

# Backup database (important!)
docker compose exec chamilo_db mysqldump -u chamilo -pchamilo chamilo > backup-$(date +%Y%m%d).sql

# Download new version
./setup-chamilo.sh <NEW_VERSION>

# Rebuild and start
docker compose build
docker compose up -d
```

### Renew SSL Certificate (Manual)

SSL certificate akan auto-renew, tapi untuk test manual:

```bash
sudo certbot renew --dry-run
```

Untuk renew manual:
```bash
sudo certbot renew
sudo systemctl reload nginx
```

### View Logs

```bash
# Docker logs
docker compose logs -f chamilo_app
docker compose logs -f chamilo_db

# Nginx logs
sudo tail -f /var/log/nginx/lms.septadenita.my.id.access.log
sudo tail -f /var/log/nginx/lms.septadenita.my.id.error.log

# Apache logs (inside container)
docker compose exec chamilo_app tail -f /var/log/apache2/error.log
```

## 🐛 Troubleshooting

### Domain tidak bisa diakses

1. Check DNS:
   ```bash
   dig lms.septadenita.my.id
   ```

2. Check Nginx:
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   ```

3. Check Docker:
   ```bash
   docker compose ps
   docker compose logs chamilo_app
   ```

4. Check firewall:
   ```bash
   sudo ufw status
   ```

### SSL Certificate Error

1. Verify certificate:
   ```bash
   sudo certbot certificates
   ```

2. Test renewal:
   ```bash
   sudo certbot renew --dry-run
   ```

3. Check Nginx config:
   ```bash
   sudo nginx -t
   ```

### 502 Bad Gateway

Ini berarti Nginx tidak bisa connect ke Docker container:

1. Check container running:
   ```bash
   docker compose ps
   ```

2. Check port:
   ```bash
   netstat -tlnp | grep 1234
   # atau
   ss -tlnp | grep 1234
   ```

3. Check Docker network:
   ```bash
   docker network inspect chamilo-docker_chamilo_network
   ```

### Permission Errors

Jika ada permission errors:

```bash
# Fix permissions
docker compose exec chamilo_app chown -R www-data:www-data /var/www/html
docker compose exec chamilo_app chmod -R 755 /var/www/html

# Restart container
docker compose restart chamilo_app
```

## 📦 Backup & Restore

### Backup Database

```bash
# Create backup directory
mkdir -p ~/backups/chamilo

# Backup database
docker compose exec chamilo_db mysqldump -u chamilo -pchamilo chamilo | gzip > ~/backups/chamilo/db-$(date +%Y%m%d-%H%M%S).sql.gz
```

### Backup Files

```bash
# Backup Chamilo files
tar -czf ~/backups/chamilo/files-$(date +%Y%m%d-%H%M%S).tar.gz /var/www/chamilo-docker/chamilo
```

### Restore Database

```bash
# Unzip backup
gunzip ~/backups/chamilo/db-YYYYMMDD-HHMMSS.sql.gz

# Restore
docker compose exec -T chamilo_db mysql -u chamilo -pchamilo chamilo < ~/backups/chamilo/db-YYYYMMDD-HHMMSS.sql
```

## 📚 Additional Resources

- [Chamilo Documentation](https://docs.chamilo.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

## 📞 Support

Jika ada masalah, check logs terlebih dahulu:
1. Docker logs: `docker compose logs`
2. Nginx logs: `/var/log/nginx/`
3. Check status services: `systemctl status nginx docker`

