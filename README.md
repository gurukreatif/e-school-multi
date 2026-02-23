# 🏫 Emes CBT System — Multi-tenant (NPSN-based)

Aplikasi Ujian Berbasis Komputer (CBT) multi-tenant dalam **satu file HTML**.  
Setiap sekolah diidentifikasi menggunakan **NPSN** sebagai ID unik.

---

## 📁 Struktur File

```
├── index.html                      ← Seluruh aplikasi (HTML + CSS + JS)
├── vercel.json                     ← Konfigurasi routing Vercel (wajib ada)
├── migration_multitenant_npsn.sql  ← SQL schema database Supabase
└── README.md                       ← Dokumentasi ini
```

> **Cukup 2 file** (`index.html` + `vercel.json`) untuk deploy. File `.sql` dijalankan sekali di Supabase.

---

## 🗺️ URL Routing

| URL | Halaman |
|-----|---------|
| `domain.com/` | Landing page — daftar semua sekolah |
| `domain.com/login` | Login admin / guru / proktor / siswa |
| `domain.com/super` | Super Admin panel |
| `domain.com/login?npsn=10200001` | Login langsung ke sekolah tertentu (untuk QR Code) |

---

## 🚀 Cara Deploy ke Vercel + GitHub

### Langkah 1: Siapkan Repository GitHub
1. Buat repo baru di [github.com](https://github.com) (bisa private)
2. Upload **2 file**: `index.html` dan `vercel.json`
3. Commit & push

### Langkah 2: Deploy ke Vercel
1. Buka [vercel.com](https://vercel.com) → Login dengan GitHub
2. Klik **"Add New → Project"**
3. Pilih repo yang baru dibuat → Klik **"Import"**
4. **Framework Preset**: pilih **"Other"** (bukan Next.js, dll)
5. Klik **"Deploy"** — selesai dalam ~30 detik
6. Dapat URL: `https://nama-project.vercel.app`

> ✅ Setiap push ke GitHub otomatis update di Vercel.

---

## 🗄️ Setup Database Supabase

### Langkah 1: Buat Project Supabase
1. Buka [supabase.com](https://supabase.com) → Buat akun gratis
2. **"New Project"** → isi nama project dan database password
3. Pilih region: **Southeast Asia (Singapore)**
4. Tunggu ~2 menit hingga project siap

### Langkah 2: Jalankan SQL Schema
1. Di Supabase: **SQL Editor → New Query**
2. Buka file `migration_multitenant_npsn.sql`
3. Salin seluruh isi → Paste di SQL Editor → Klik **"Run"**
4. Semua tabel otomatis terbuat

### Langkah 3: Ambil Kredensial Supabase
1. **Project Settings → API**
2. Catat:
   - **Project URL**: `https://xxxxxxxx.supabase.co`
   - **anon/public key**: `eyJhbGci...`

### Langkah 4: Masukkan Kredensial ke Aplikasi
Buka file `index.html`, cari baris ini (sekitar baris 590):

```javascript
const SUPABASE_URL  = 'https://oshnmliknppofbfsbkwq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGci...';
```

Ganti dengan URL dan Key milik Anda, lalu push ulang ke GitHub.

---

## 🔑 Login & Akses

### Super Admin
| URL | `domain.com/super` |
|-----|--------------------|
| Username | `superadmin` |
| Password | `EmesSuper@2026!` |

> ⚠️ **Wajib ganti** password di `index.html` sebelum deploy produksi!  
> Cari konstanta `SA_PASS` dan ubah nilainya.

### Admin Sekolah (default saat sekolah baru dibuat)
| Field | Nilai |
|-------|-------|
| NPSN | NPSN sekolah (8 digit) |
| Username | `admin` |
| Password | `admin` |

> ⚠️ Ganti password admin setelah login pertama via **Manajemen User**.

---

## 🏫 Alur Penggunaan Multi-tenant

### Untuk Operator Platform (Super Admin)
1. Buka `domain.com/super` → Login
2. Klik **"Tambah Sekolah"** → Isi NPSN, nama, alamat
3. Simpan → Otomatis dibuat: akun admin default + pengaturan awal
4. Sekolah langsung muncul di landing page

### Untuk Admin Sekolah
1. Buka `domain.com/login`
2. Isi **NPSN** sekolah → klik Cari → muncul nama sekolah
3. Isi username & password → Masuk
4. Kelola soal, siswa, ujian, dll

### Untuk Siswa
1. Buka `domain.com/login` → Tab **Siswa**
2. Isi NPSN sekolah → Isi nomor peserta & password → Masuk
3. Atau scan **QR Code** sekolah yang mengarah ke `domain.com/login?npsn=XXXXXXXX`

---

## ✅ Fitur Lengkap

### Super Admin Panel
- Dashboard global (total sekolah, siswa, paket soal)
- Tambah / Edit / Hapus sekolah (tenant)
- Toggle aktif/nonaktif sekolah
- Masuk ke panel admin sekolah tertentu langsung

### Admin / Guru / Proktor Panel
- Dashboard statistik sekolah
- Manajemen paket soal (5 tipe soal)
- Import/Export siswa via Excel
- Monitor ujian real-time
- Leaderboard & daftar hadir
- Koreksi uraian manual
- Analisa per-butir soal
- Chat dengan siswa
- Pengaturan sekolah

### Portal Siswa
- Daftar & ikuti ujian aktif
- Timer countdown + auto-save
- Riwayat nilai
- Chat dengan guru
- Mini game saat menunggu

---

## 📋 Format Import Siswa (Excel)

Header kolom harus persis:

| nama_siswa | username | password | kelas | rombel |
|------------|----------|----------|-------|--------|
| Budi Santoso | 123456 | 123456 | 9 | A |

---

## 🔧 Troubleshooting

**Q: Routing `/login` atau `/super` tidak bekerja**  
A: Pastikan `vercel.json` ada di repo dan berisi wildcard rewrite ke `index.html`.

**Q: Landing page kosong / tidak ada sekolah**  
A: Jalankan SQL schema dulu di Supabase. Pastikan ada data di tabel `tenants`.

**Q: NPSN tidak ditemukan saat login**  
A: Sekolah belum didaftarkan. Super Admin perlu tambah sekolah dulu.

**Q: Error koneksi Supabase**  
A: Periksa `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `index.html`. Pastikan RLS policy sudah dibuat.

**Q: Data sekolah A terlihat di sekolah B**  
A: Tidak mungkin terjadi — semua query otomatis difilter oleh NPSN via `patchSupabaseForTenant()`.
