# AutoBackup Service (UAS Lab SO B)

Sistem backup otomatis berbasis Bash Shell Script yang dirancang untuk kebutuhan manajemen data yang efisien. Sistem ini dilengkapi dengan manajemen konfigurasi berbasis CLI (Command Line Interface), penjadwalan otomatis menggunakan Systemd Timer, mekanisme penguncian (file locking) untuk keamanan konkurensi, dan fitur pemulihan data yang cerdas.

## Anggota Kelompok

| Nama                     | NPM           |
| :----------------------- | :------------ |
| Fadhlurrahman Alaudin    | 2408107010053 |
| Teuku Fikram Al-Syahbana | 2408107010044 |
| Muhammad Anis Fathin     | 2408107010045 |

## Fitur Utama

1.  **Manajemen CLI Penuh**: Membuat, mengedit, dan menghapus konfigurasi backup semudah menggunakan perintah git atau apt.
2.  **Penjadwalan Otomatis**: Terintegrasi dengan Systemd Timer yang mengecek jadwal setiap menit menggunakan format **Cron** (5 kolom).
3.  **Keamanan Konkurensi**: Mencegah tumpang tindih proses backup menggunakan mekanisme `.lock` file.
4.  **Sistem ID Unik**: Setiap konfigurasi memiliki ID unik (`backup@xxxx`) untuk pengelolaan file yang presisi dan aman dari duplikasi nama.
5.  **Smart Recovery**: Fitur restore yang mendukung mode interaktif maupun otomatis (CLI) dengan proteksi penimpaan data (_overwrite protection_).
6.  **Log & Rotasi**: Pencatatan aktivitas detail dengan penanda ID dan penghapusan otomatis file backup yang kadaluarsa.

## Struktur Direktori

```text
.
├── install-service.sh   # Installer untuk Systemd Service & Autocomplete
├── project.conf         # Database konfigurasi (Flat-file DB)
├── completion.sh        # Script untuk Bash Autocomplete (TAB)
└── src/
    ├── main.sh          # Interface Utama (CLI Entry Point)
    ├── autoservice.sh   # Logic Scheduler (Dijalankan oleh Systemd)
    ├── backup.sh        # Logic Eksekusi Backup (Tar Gzip)
    ├── recovery.sh      # Logic Pemulihan Data
    ├── rotation.sh      # Logic Pembersihan Backup Lama
    └── utils.sh         # Library Fungsi Umum (Validasi, ID, dll)
```

## Instalasi
Untuk memasang service ke dalam sistem (level user) dan mengaktifkan fitur autocomplete, jalankan perintah berikut dari folder root proyek:

```Bash
./src/main.sh --install-service
```
Catatan: Setelah instalasi selesai, jalankan perintah: 
```Bash
source ~/.bashrc
``` 
atau restart terminal Anda agar fitur autocomplete (TAB) dapat berfungsi.

## Cara Penggunaan
Semua interaksi dilakukan melalui script utama src/main.sh.

**1. Manajemen Service**
Mengontrol status background service.

Install/Update Service:

```Bash
./src/main.sh --install-service [--update]
Uninstall Service:
```

```Bash
./src/main.sh --uninstall-service [-y]
Start/Stop/Status:
```

```Bash
./src/main.sh --start-service
./src/main.sh --stop-service
./src/main.sh --status-service
```

**2. Manajemen Backup**
Mengelola tugas-tugas backup Anda.

Lihat Daftar Backup Aktif:

```Bash
./src/main.sh list
```

Buat Jadwal Baru:

Mode Interaktif (Wizard):
```Bash
./src/main.sh create
```

Mode CLI Arguments (Format: create <src> <dest> <retensi> <cron> [-y])

```Bash
./src/main.sh create /home/user/Dokumen /tmp/backup 7 "_/30 _ \* \* \*" -y
```

Edit Konfigurasi:

```Bash
./src/main.sh edit <backup_id>
```

Hapus Konfigurasi:

Hapus konfigurasi saja:

```Bash
./src/main.sh delete <backup_id>
```

Hapus konfigurasi BESERTA file backup fisik:

```Bash
./src/main.sh delete <backup_id> --purge
```

Jalankan Backup Manual (Sekarang):

```Bash
./src/main.sh backup <backup_id> 3. Pemulihan Data (Recovery)
```

Mengembalikan data dari file backup yang tersimpan.

Mode Interaktif:

```Bash
./src/main.sh recovery <backup_id>
```

Mode Otomatis (Format: recovery <id> <file|"latest"> <dest_opt> [path] [-y])

dest_opt: 1 (Asli), 2 (Custom)

```Bash
./src/main.sh recovery <backup_id> latest 1 -y
```

## Format Jadwal (Cron)
Sistem ini menggunakan format standar Cron 5 kolom: Menit Jam Tanggal Bulan Hari

Contoh:

_/5 _ \* \* \* : Setiap 5 menit.

0 12 \* \* \* : Setiap hari jam 12:00 siang.

30 17 \* \* 5 : Setiap hari Jumat jam 17:30.

0 0 1 \* \* : Setiap tanggal 1 setiap bulan (tengah malam).

Dibuat untuk memenuhi Tugas Besar Praktikum Sistem Operasi Lab B.
