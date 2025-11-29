# 1_Project_UAS_LabSO_B

## 👥 Anggota Kelompok


| Nama | NPM |
| :--- | :--- |
| Fadhlurrahman Alaudin | 2408107010053 |
| Teuku Fikram Al-Syahbana | 2408107010044 |
| Muhammad Anis Fathin | 2408107010045 |



# 💾 Sistem Backup Otomatis dengan Log & Rotasi 


[![Shell Script](https://img.shields.io/badge/Language-Bash-red.svg)](https://www.gnu.org/software/bash/)

---

## 📝 Deskripsi Proyek

Proyek ini adalah implementasi **sistem backup otomatis** berbasis **Bash Shell Script** yang dirancang untuk mengamankan data penting. Skrip ini secara interaktif menerima input dari pengguna (folder sumber dan periode retensi) dan melakukan tugas-tugas inti berikut:

1.  **Backup Data:** Mengompresi folder sumber (*source folder*) menjadi file `.tar.gz` dengan *timestamp* unik.
2.  **Pencatatan Log:** Mencatat status (SUCCESS/FAILED), ukuran file, dan waktu penyelesaian ke dalam file `./backup.log`.
3.  **Rotasi Backup:** Secara otomatis menghapus file backup di folder tujuan (`backup/`) yang usianya melebihi periode retensi yang ditentukan oleh pengguna.

Tujuan utama sistem ini adalah menyediakan solusi backup yang sederhana, efisien, dan dilengkapi manajemen ruang disk otomatis.

---

## 💻 Penjelasan Kode 

Skrip `backup.sh` disusun dalam beberapa fungsi terpisah untuk memastikan modularitas dan kemudahan *troubleshooting*.

### 1. `get_user_input` 💬
* Fungsi ini bertanggung jawab untuk mendapatkan **Path Folder Sumber** dan **Jumlah Hari Retensi** (rotasi) dari pengguna secara interaktif.
* Termasuk validasi dasar untuk memastikan folder tidak kosong dan hari retensi adalah angka.

### 2. `validate_folders` ✅
* Memeriksa apakah folder sumber ada (`-d "$source"`). Jika tidak, skrip akan keluar.
* Membuat folder tujuan backup (`backup/`) jika belum ada menggunakan `mkdir -p`.

### 3. `perform_backup` 📦
* Membuat *timestamp* dengan format `%Y%m%d-%H%M%S` untuk nama file yang unik.
* Melakukan kompresi data menggunakan utilitas **`tar -czf`** (Create, Gzip, File) sambil menggunakan opsi `-C` untuk navigasi direktori, memastikan path dalam arsip relatif dan bersih.
* Menyimpan status keberhasilan/kegagalan (`$BACKUP_STATUS`).

### 4. `write_log` 📜
* Mencatat status proses (**SUCCESS** atau **FAILED**) dan detail seperti ukuran file (`du -h`) ke dalam file `./backup.log`.
* Memberikan *feedback* kepada pengguna di terminal mengenai hasil backup.

### 5. `diff_days` dan `rotate_backups` 🗑️
* **`diff_days`**: Fungsi pembantu yang menghitung selisih hari antara dua tanggal, penting untuk menentukan usia file.
* **`rotate_backups`**: Menerapkan rotasi:
    * Mengiterasi file di folder `backup/`.
    * Menggunakan **`stat -c %y`** untuk mengambil waktu modifikasi file.
    * Jika usia file (dihitung oleh `diff_days`) melebihi `$retention`, file tersebut dihapus menggunakan **`rm`**.

---
