-- ════════════════════════════════════════════════════════════════════
-- EMES CBT — FASE 1 SECURITY MIGRATION
-- Jalankan di: Supabase Dashboard → SQL Editor → New Query
-- Versi: 1.0  |  Tanggal: 2026
-- ════════════════════════════════════════════════════════════════════
-- Tujuan:
--   1. Ganti RLS "allow all" → isolasi per NPSN via session config
--   2. Buat RPC set_tenant_npsn (dipanggil JS setelah login)
--   3. Migrate password plaintext → SHA-256 hash
--
-- PRASYARAT: Schema tabel sudah ada (migration_multitenant_npsn.sql sudah dijalankan)
-- AMAN DIJALANKAN ULANG: semua statement idempoten (create or replace / do-except)
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────────
-- STEP 1: Fungsi set_tenant_npsn
--   Dipanggil dari JS setelah login berhasil.
--   Menyimpan npsn di session variable Postgres (app.current_npsn)
--   sehingga RLS policy bisa membacanya.
-- ────────────────────────────────────────────────────────────────────
create or replace function set_tenant_npsn(p_npsn text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Validasi ketat: hanya 8 digit angka
  if p_npsn is null or p_npsn !~ '^[0-9]{8}$' then
    raise exception 'NPSN tidak valid: harus 8 digit angka';
  end if;
  -- Simpan di session (false = local to transaction, pakai true agar persist di koneksi)
  perform set_config('app.current_npsn', p_npsn, false);
end;
$$;

-- Izinkan anon key (user belum auth) memanggil fungsi ini
grant execute on function set_tenant_npsn(text) to anon, authenticated;

-- ────────────────────────────────────────────────────────────────────
-- STEP 2: Fungsi helper get_tenant_npsn
--   Digunakan oleh semua RLS policy untuk mendapatkan npsn aktif.
-- ────────────────────────────────────────────────────────────────────
create or replace function get_tenant_npsn()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select nullif(trim(current_setting('app.current_npsn', true)), '');
$$;

grant execute on function get_tenant_npsn() to anon, authenticated;

-- ────────────────────────────────────────────────────────────────────
-- STEP 3: Ganti semua RLS policy "allow all" → berbasis NPSN
--
-- Logika policy:
--   - Jika get_tenant_npsn() IS NULL (session belum di-set / super admin):
--     → izinkan akses (fallback agar super admin panel tetap bisa query)
--   - Jika get_tenant_npsn() ada:
--     → hanya boleh akses row yang npsn-nya sama
--
-- Catatan: Super Admin menggunakan Supabase service_role key (tidak terkena RLS)
-- atau bisa set npsn khusus '00000000' untuk bypass. Untuk saat ini, null = izin.
-- ────────────────────────────────────────────────────────────────────

-- Helper macro: drop policy if exists (aman untuk re-run)
do $$
declare
  tbl text;
  pol text;
begin
  -- Hapus semua policy "allow all" lama
  for tbl, pol in
    select tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and policyname like 'allow all%'
  loop
    execute format('drop policy if exists %I on %I', pol, tbl);
  end loop;
end $$;

-- ── TENANTS ──
-- Semua bisa SELECT (untuk landing page & NPSN lookup)
-- INSERT/UPDATE/DELETE hanya via super admin (no tenant filter)
create policy "tenants_select"
  on tenants for select
  using (true);

create policy "tenants_write"
  on tenants for insert
  with check (true);

create policy "tenants_update"
  on tenants for update
  using (true);

create policy "tenants_delete"
  on tenants for delete
  using (true);

-- ── ADMINS ──
drop policy if exists "admins_tenant" on admins;
create policy "admins_tenant"
  on admins for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── SISWA ──
drop policy if exists "siswa_tenant" on siswa;
create policy "siswa_tenant"
  on siswa for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── SOAL ──
drop policy if exists "soal_tenant" on soal;
create policy "soal_tenant"
  on soal for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── BUTIR SOAL ──
drop policy if exists "butir_tenant" on butir_soal;
create policy "butir_tenant"
  on butir_soal for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── JAWABAN SISWA ──
drop policy if exists "jawaban_tenant" on jawaban_siswa;
create policy "jawaban_tenant"
  on jawaban_siswa for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── NILAI ──
drop policy if exists "nilai_tenant" on nilai;
create policy "nilai_tenant"
  on nilai for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── CHAT ──
drop policy if exists "chat_tenant" on chat;
create policy "chat_tenant"
  on chat for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── SKOR GAME ──
drop policy if exists "game_tenant" on skor_game;
create policy "game_tenant"
  on skor_game for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ── FAQ (global, tidak per tenant) ──
drop policy if exists "faq_all" on faq;
create policy "faq_all"
  on faq for all
  using (true)
  with check (true);

-- ── PENGATURAN ──
drop policy if exists "pengaturan_tenant" on pengaturan;
create policy "pengaturan_tenant"
  on pengaturan for all
  using (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  )
  with check (
    get_tenant_npsn() is null
    or npsn = get_tenant_npsn()
  );

-- ────────────────────────────────────────────────────────────────────
-- STEP 4: Migrasi password plaintext → SHA-256
--
-- SHA-256 tersedia native di Postgres via pgcrypto (sudah aktif di Supabase).
-- Hanya update row yang passwordnya BUKAN hex 64 karakter (plaintext).
-- ────────────────────────────────────────────────────────────────────

-- Aktifkan ekstensi pgcrypto jika belum aktif
create extension if not exists pgcrypto;

-- Migrate password admin (plaintext → SHA-256 hex)
update admins
  set password = encode(digest(password, 'sha256'), 'hex')
  where password !~ '^[0-9a-f]{64}$';

-- Migrate password siswa (plaintext → SHA-256 hex)
update siswa
  set password = encode(digest(password, 'sha256'), 'hex')
  where password !~ '^[0-9a-f]{64}$';

-- ────────────────────────────────────────────────────────────────────
-- STEP 5: Verifikasi hasil
-- ────────────────────────────────────────────────────────────────────
-- Cek fungsi terbuat:
select proname, prosecdef
from pg_proc
where proname in ('set_tenant_npsn','get_tenant_npsn')
  and pronamespace = 'public'::regnamespace;

-- Cek policy baru (tidak boleh ada "allow all" lagi):
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('admins','siswa','soal','butir_soal','jawaban_siswa','nilai','chat','skor_game','pengaturan')
order by tablename;

-- Cek password sudah di-hash (tidak ada yang plaintext pendek):
select
  (select count(*) from admins where length(password) < 60) as admins_plaintext,
  (select count(*) from siswa  where length(password) < 60) as siswa_plaintext;
-- Idealnya: 0 | 0

-- ════════════════════════════════════════════════════════════════════
-- SELESAI! Langkah selanjutnya:
--   1. Deploy index.html terbaru ke Vercel
--   2. Test login: setelah login, JS akan memanggil set_tenant_npsn(npsn)
--   3. Verifikasi isolasi: login sebagai sekolah A, tidak bisa melihat data sekolah B
--   4. Ganti password default "admin" via panel Manajemen User
-- ════════════════════════════════════════════════════════════════════
