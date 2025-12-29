# Setup web/build Directory

Chamilo memerlukan direktori `/var/www/html/web/build` untuk menulis file JavaScript yang di-build.

Karena direktori ini menggunakan bind mount dari host, Anda perlu membuat direktori ini di host system dengan permissions yang benar.

## Cara 1: Menggunakan script dengan sudo (Recommended)

Jalankan script berikut dengan sudo:

```bash
sudo ./create-web-build-sudo.sh
```

Kemudian restart container:

```bash
docker-compose restart chamilo_app
```

## Cara 2: Manual

Buat direktori secara manual:

```bash
mkdir -p chamilo/web/build
sudo chmod -R 777 chamilo/web/build
docker-compose restart chamilo_app
```

## Verifikasi

Setelah membuat direktori, verifikasi dengan:

```bash
docker-compose exec -u www-data chamilo_app /bin/bash -c "cd /var/www/html/web/build && touch test.txt && echo 'Build directory is writable' && rm test.txt"
```

Jika berhasil, Anda akan melihat pesan "Build directory is writable".

