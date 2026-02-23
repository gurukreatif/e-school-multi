-- ════════════════════════════════════════════════════════════════════
-- EMES CBT SYSTEM — MULTI-TENANT MIGRATION (NPSN-based)
-- Versi: 2.0  |  Jalankan di: Supabase → SQL Editor → New Query
-- ════════════════════════════════════════════════════════════════════
-- NPSN (Nomor Pokok Sekolah Nasional) digunakan sebagai:
--   • Primary Key tabel tenants
--   • Foreign Key (npsn) di semua tabel data
--   • Identifier unik setiap sekolah di URL: /login?npsn=XXXXXXXX
-- ════════════════════════════════════════════════════════════════════

-- ── STEP 1: BUAT TABEL TENANTS ──────────────────────────────────────
create table if not exists tenants (
  npsn        text primary key check (npsn ~ '^[0-9]{8}$'),
  nama        text not null,
  alamat      text default '',
  logo        text default '',
  status      text default 'Aktif' check (status in ('Aktif','Nonaktif')),
  paket       text default 'Free'  check (paket  in ('Free','Basic','Pro','Enterprise')),
  kepsek      text default '',
  nip_kepsek  text default '',
  created_at  timestamptz default now()
);

alter table tenants enable row level security;
create policy "allow all tenants"
  on tenants for all using (true) with check (true);

-- ── STEP 2: BUAT SEMUA TABEL DATA (with npsn FK) ────────────────────

create table if not exists admins (
  id          bigint primary key generated always as identity,
  npsn        text not null references tenants(npsn) on delete cascade,
  username    text not null,
  password    text not null,
  nama_admin  text not null,
  role        text default 'editor'
                   check (role in ('admin','guru','editor','proktor','pengawas')),
  created_at  timestamptz default now(),
  unique(npsn, username)
);
alter table admins enable row level security;
create policy "allow all admins" on admins for all using (true) with check (true);

create table if not exists siswa (
  id_siswa      bigint primary key generated always as identity,
  npsn          text not null references tenants(npsn) on delete cascade,
  nama_siswa    text not null,
  username      text not null,
  password      text not null,
  kelas         text default '',
  rombel        text default '',
  status        text default 'Aktif',
  session_token text default '',
  force_logout  boolean default false,
  page_url      text default '',
  created_at    timestamptz default now(),
  unique(npsn, username)
);
alter table siswa enable row level security;
create policy "allow all siswa" on siswa for all using (true) with check (true);

create table if not exists soal (
  id_soal               bigint primary key generated always as identity,
  npsn                  text not null references tenants(npsn) on delete cascade,
  id_pembuat            text default '',
  kode_soal             text not null,
  nama_soal             text not null,
  mapel                 text default '',
  kelas                 text default '',
  waktu_ujian           integer default 60,
  tanggal               date,
  status                text default 'Aktif',
  tampilan_soal         text default 'Urut',
  kunci                 text default '',
  token                 text default '',
  jumlah_opsi           integer default 4,
  tampil_tombol_selesai integer default 1,
  created_at            timestamptz default now(),
  unique(npsn, kode_soal)
);
alter table soal enable row level security;
create policy "allow all soal" on soal for all using (true) with check (true);

create table if not exists butir_soal (
  id_soal       bigint primary key generated always as identity,
  npsn          text not null references tenants(npsn) on delete cascade,
  nomer_soal    integer,
  kode_soal     text,
  pertanyaan    text,
  tipe_soal     text default 'Pilihan Ganda',
  pilihan_1     text default '',
  pilihan_2     text default '',
  pilihan_3     text default '',
  pilihan_4     text default '',
  pilihan_5     text default '',
  jawaban_benar text,
  gambar        text default '',
  status_soal   text default 'Aktif',
  created_at    timestamptz default now()
);
alter table butir_soal enable row level security;
create policy "allow all butir_soal" on butir_soal for all using (true) with check (true);

create table if not exists jawaban_siswa (
  id_jawaban    bigint primary key generated always as identity,
  npsn          text not null references tenants(npsn) on delete cascade,
  id_siswa      bigint,
  nama_siswa    text,
  kode_soal     text,
  jawaban       text default '{}',
  status_ujian  text default 'Aktif',
  waktu_sisa    integer default 0,
  waktu_dijawab timestamptz,
  created_at    timestamptz default now()
);
alter table jawaban_siswa enable row level security;
create policy "allow all jawaban_siswa" on jawaban_siswa for all using (true) with check (true);

create table if not exists nilai (
  id_nilai          bigint primary key generated always as identity,
  npsn              text not null references tenants(npsn) on delete cascade,
  id_siswa          bigint,
  nama_siswa        text,
  kode_soal         text,
  nilai             numeric(6,2) default 0,
  jawaban_benar     integer default 0,
  jawaban_salah     integer default 0,
  total_soal        integer default 0,
  jawaban_siswa     text,
  nilai_uraian      numeric(6,2) default 0,
  detail_uraian     text default '',
  status_penilaian  text default 'otomatis',
  tanggal_ujian     timestamptz default now()
);
alter table nilai enable row level security;
create policy "allow all nilai" on nilai for all using (true) with check (true);

create table if not exists chat (
  id            bigint primary key generated always as identity,
  npsn          text not null references tenants(npsn) on delete cascade,
  id_siswa      bigint,
  nama_pengirim text,
  role          text default 'siswa',
  pesan         text,
  waktu         timestamptz default now()
);
alter table chat enable row level security;
create policy "allow all chat" on chat for all using (true) with check (true);

create table if not exists skor_game (
  id        bigint primary key generated always as identity,
  npsn      text not null references tenants(npsn) on delete cascade,
  id_siswa  bigint,
  nama_game text,
  skor      integer default 0,
  waktu     timestamptz default now()
);
alter table skor_game enable row level security;
create policy "allow all skor_game" on skor_game for all using (true) with check (true);

create table if not exists faq (
  id         bigint primary key generated always as identity,
  npsn       text not null references tenants(npsn) on delete cascade,
  question   text,
  answer     text,
  urutan     integer default 0,
  created_at timestamptz default now()
);
alter table faq enable row level security;
create policy "allow all faq" on faq for all using (true) with check (true);

create table if not exists pengaturan (
  id                bigint primary key generated always as identity,
  npsn              text unique not null references tenants(npsn) on delete cascade,
  nama_sekolah      text default 'Sekolah',
  nama_app          text default 'CBT E-School',
  alamat_sekolah    text default '',
  nama_kepsek       text default '',
  nip_kepsek        text default '',
  logo_sekolah      text default '',
  kop_custom        text default '',
  chat              text default 'izin',
  login_ganda       text default 'izin',
  sembunyikan_nilai text default 'tidak',
  berita_acara      text default 'tidak'
);
alter table pengaturan enable row level security;
create policy "allow all pengaturan" on pengaturan for all using (true) with check (true);

-- ── STEP 3: INDEKS PERFORMA ──────────────────────────────────────────
create index if not exists idx_admins_npsn       on admins(npsn);
create index if not exists idx_siswa_npsn        on siswa(npsn);
create index if not exists idx_soal_npsn         on soal(npsn);
create index if not exists idx_butir_npsn        on butir_soal(npsn);
create index if not exists idx_jawaban_npsn      on jawaban_siswa(npsn);
create index if not exists idx_nilai_npsn        on nilai(npsn);
create index if not exists idx_chat_npsn         on chat(npsn);
create index if not exists idx_game_npsn         on skor_game(npsn);
create index if not exists idx_faq_npsn          on faq(npsn);
create index if not exists idx_pengaturan_npsn   on pengaturan(npsn);

-- ── STEP 4: DATA CONTOH ──────────────────────────────────────────────
-- Sekolah pertama (ganti sesuai data asli)
insert into tenants (npsn, nama, alamat, status, paket)
values ('10200001', 'MIN Singkawang', 'Jl. Pendidikan No.1, Singkawang', 'Aktif', 'Pro')
on conflict (npsn) do nothing;

-- Admin default sekolah pertama (SEGERA GANTI PASSWORD SETELAH DEPLOY!)
insert into admins (npsn, username, password, nama_admin, role)
values ('10200001', 'admin', 'admin', 'Administrator', 'admin')
on conflict (npsn, username) do nothing;

-- Pengaturan default sekolah pertama
insert into pengaturan (npsn, nama_sekolah, nama_app, alamat_sekolah)
values ('10200001', 'MIN Singkawang', 'CBT E-School', 'Jl. Pendidikan No.1, Singkawang')
on conflict (npsn) do nothing;

-- ── STEP 5: MIGRASI DARI VERSI LAMA (jika ada) ──────────────────────
-- Jika tabel sebelumnya tidak punya kolom npsn:
-- 1. Pastikan tabel tenants sudah dibuat dan diisi
-- 2. Jalankan ALTER di bawah ini:
/*
alter table admins      add column if not exists npsn text references tenants(npsn);
alter table siswa       add column if not exists npsn text references tenants(npsn);
alter table soal        add column if not exists npsn text references tenants(npsn);
alter table butir_soal  add column if not exists npsn text references tenants(npsn);
alter table jawaban_siswa add column if not exists npsn text references tenants(npsn);
alter table nilai       add column if not exists npsn text references tenants(npsn);
alter table chat        add column if not exists npsn text references tenants(npsn);
alter table skor_game   add column if not exists npsn text references tenants(npsn);
alter table faq         add column if not exists npsn text references tenants(npsn);
alter table pengaturan  add column if not exists npsn text unique references tenants(npsn);

-- Isi npsn untuk data lama (ganti '10200001' dengan NPSN sekolah Anda):
update admins        set npsn = '10200001' where npsn is null;
update siswa         set npsn = '10200001' where npsn is null;
update soal          set npsn = '10200001' where npsn is null;
update butir_soal    set npsn = '10200001' where npsn is null;
update jawaban_siswa set npsn = '10200001' where npsn is null;
update nilai         set npsn = '10200001' where npsn is null;
update chat          set npsn = '10200001' where npsn is null;
update skor_game     set npsn = '10200001' where npsn is null;
update faq           set npsn = '10200001' where npsn is null;
update pengaturan    set npsn = '10200001' where npsn is null;
*/

-- ════════════════════════════════════════════════════════════════════
-- SELESAI! Selanjutnya:
-- 1. Deploy index.html ke Vercel (pastikan vercel.json sudah ada)
-- 2. Buka domain.com → Landing page daftar sekolah
-- 3. domain.com/super → Login Super Admin (user: superadmin, pass: EmesSuper@2026!)
-- 4. Tambah sekolah dari Super Admin → otomatis buat admin default (admin/admin)
-- 5. domain.com/login → Login page dengan input NPSN
-- 6. QR code per sekolah: domain.com/login?npsn=XXXXXXXX
--
-- KEAMANAN: Segera ubah password di:
--   • Super Admin: konstanta SA_PASS di index.html
--   • Admin sekolah: update via panel Admin → Manajemen User
-- ════════════════════════════════════════════════════════════════════
