# Chamilo LMS Docker Setup

Docker setup untuk Chamilo LMS dengan konfigurasi lengkap.

## 📋 Requirements

- Docker Engine >= 20.10
- Docker Compose >= 2.0 (atau docker-compose >= 1.29)
- wget atau curl (untuk download Chamilo)
- unzip (untuk extract Chamilo)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url> chamilo-docker
cd chamilo-docker
```

### 2. Jalankan Script Start (Otomatis Download Chamilo)

```bash
chmod +x start.sh setup-chamilo.sh
./start.sh
```

Script `start.sh` akan:
- ✅ Check apakah Chamilo sudah didownload
- ✅ Jika belum, otomatis download Chamilo versi terbaru (1.11.26)
- ✅ Setup direktori `web/build` dengan permissions yang benar
- ✅ Build Docker images
- ✅ Start containers dengan `docker compose up -d`

### 3. Access Application

- Web Interface: http://localhost:1234
- Installation: http://localhost:1234/main/install/index.php

### 4. Install Chamilo via Web Interface

Saat instalasi, gunakan database credentials berikut:

- **Database Host**: `chamilo_db` (bukan localhost!)
- **Database Name**: `chamilo`
- **Database User**: `chamilo`
- **Database Password**: `chamilo`
- **Database Port**: `3306`

## 📝 Manual Setup (Jika Perlu)

### Download Chamilo Manual

```bash
# Download versi tertentu
chmod +x setup-chamilo.sh
./setup-chamilo.sh 1.11.26

# Atau download versi default (terbaru)
./setup-chamilo.sh
```

### Setup Permissions Manual

```bash
# Buat direktori web/build
mkdir -p chamilo/web/build
chmod -R 777 chamilo/web/build  # atau gunakan sudo jika diperlukan
```

### Docker Commands Manual

```bash
# Build images
docker compose build

# Start containers
docker compose up -d

# View logs
docker compose logs -f chamilo_app

# Stop containers
docker compose down
```

## 📁 Project Structure

```
chamilo-docker/
├── docker-compose.yml      # Docker Compose configuration
├── Dockerfile              # Chamilo app image definition
├── docker-entrypoint.sh    # Entrypoint script for permissions
├── start.sh                # Main startup script (auto download Chamilo)
├── setup-chamilo.sh        # Script to download Chamilo
├── create-web-build.sh     # Helper script for web/build
├── .gitignore             # Git ignore rules (excludes chamilo/)
├── README.md              # This file
└── chamilo/               # Chamilo source (NOT in git, downloaded by script)
    └── ...
```

## 🔧 Configuration

### PHP Extensions Included

- intl, pdo, pdo_mysql, mysqli
- zip, gd, curl, mbstring, xml, soap
- apcu, ldap, xapian

### PHP Settings

- `display_errors = Off`
- `short_open_tag = Off`
- `session.cookie_httponly = On`
- `upload_max_filesize = 100M`
- `post_max_size = 100M`
- `memory_limit = 512M`

### Docker Volumes

- `courses_data`: Course files and documents
- `cache_data`: Application cache
- `logs_data`: Application logs
- `config_data`: Configuration files
- `db_data`: MySQL database data

## 🔍 Troubleshooting

### Error: web/build could not be written

```bash
mkdir -p chamilo/web/build
chmod -R 777 chamilo/web/build  # atau gunakan sudo
docker compose restart chamilo_app
```

### Error: Permission denied on courses directory

Named volumes akan diatur permissions otomatis oleh entrypoint script.

### Error: CHECK_PASS_EASY_TO_FIND undefined

File `profile.conf.php` akan dibuat otomatis oleh entrypoint script.

### Check Container Logs

```bash
docker compose logs chamilo_app
docker compose logs chamilo_db
```

### Access Container Shell

```bash
docker compose exec chamilo_app /bin/bash
docker compose exec chamilo_db /bin/bash
```

### Download Failed

Jika download gagal, coba:

```bash
# Check internet connection
ping -c 3 github.com

# Try manual download
wget https://github.com/chamilo/chamilo-lms/releases/download/v1.11.26/chamilo-lms-1.11.26.zip
unzip chamilo-lms-1.11.26.zip
mv chamilo-lms-1.11.26 chamilo
```

## 🔄 Update Chamilo

```bash
# Stop containers
docker compose down

# Remove old Chamilo
rm -rf chamilo

# Download versi baru
./setup-chamilo.sh <NEW_VERSION>

# Start again
./start.sh
```

## 🚀 Deployment di Server Ubuntu

### 1. Clone Repository

```bash
git clone <your-repo-url> chamilo-docker
cd chamilo-docker
```

### 2. Install Dependencies (jika belum ada)

```bash
sudo apt-get update
sudo apt-get install -y wget unzip
```

### 3. Install Docker (jika belum ada)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout dan login lagi setelah ini
```

### 4. Run

```bash
chmod +x start.sh setup-chamilo.sh
./start.sh
```

### 5. (Opsional) Setup Nginx Reverse Proxy

Jika ingin menggunakan port 80 atau HTTPS, setup Nginx sebagai reverse proxy.

## 📚 References

- [Chamilo Official Site](https://chamilo.org/)
- [Chamilo Documentation](https://docs.chamilo.org/)
- [Chamilo Downloads](https://chamilo.org/download/)
- [Chamilo GitHub Releases](https://github.com/chamilo/chamilo-lms/releases)

## 📝 Notes

- Folder `chamilo/` **TIDAK** di-commit ke Git (ukuran besar)
- Download Chamilo secara otomatis menggunakan `setup-chamilo.sh` atau `start.sh`
- Direktori `chamilo/web/build` dibuat otomatis dengan permissions yang benar
- Database credentials dapat diubah di `docker-compose.yml`
- Semua named volumes (courses, cache, logs, config) akan dibuat otomatis

