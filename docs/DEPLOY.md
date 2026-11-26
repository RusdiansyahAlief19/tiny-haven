# Cara membagikan Tiny Haven (gratis)

Setiap kali ada tag versi baru (misalnya `v0.6`), GitHub Actions otomatis membuat dua file di halaman [Releases](https://github.com/RusdiansyahAlief19/tiny-haven/releases):

| File | Untuk apa |
|---|---|
| `TinyHaven-vX-windows.zip` | Versi Windows. Ekstrak, lalu jalankan `TinyHaven.exe`. |
| `TinyHaven-vX-web.zip` | Versi browser. Di-upload ke itch.io. |

## Upload ke itch.io (main di browser)

1. Buat akun gratis di [itch.io](https://itch.io/register), lalu buka **Dashboard → Create new project**.
2. Isi data dasar:
   - **Title**: Tiny Haven
   - **Kind of project**: pilih **HTML**
   - **Classification**: Games
3. Di bagian **Uploads**, upload `TinyHaven-vX-web.zip`, lalu centang **This file will be played in the browser**.
4. Di bagian **Embed options**:
   - **Viewport dimensions**: 1152 × 648
   - Centang **Mobile friendly** (boleh dilewati) dan **Fullscreen button**.
   - **SharedArrayBuffer support** tidak perlu dicentang, karena build ini dibuat tanpa thread.
5. Di bagian **Visibility & access**, pilih:
   - **Draft** untuk mencoba sendiri dulu,
   - **Restricted** supaya hanya orang yang punya link yang bisa membuka, atau
   - **Public** supaya semua orang bisa menemukannya.
6. Klik **Save & view page**. Link halaman game bisa langsung dibagikan.

Untuk memperbarui game, upload zip web versi baru dan hapus file lama di bagian **Uploads**.

## Catatan versi web

- Versi web memakai renderer **Compatibility** (WebGL 2), karena browser belum mendukung renderer Forward+ yang dipakai di versi Windows. Bayangan dan efek cahaya sedikit lebih sederhana.
- Simpanan dunia di versi web tersimpan di browser (IndexedDB). Simpanan bisa hilang kalau data situs dihapus.
- Tombol **Keluar** disembunyikan di versi web, karena game di browser tidak bisa menutup dirinya sendiri.

## Membuat versi baru

```bash
git tag -a v0.6 -m "Iterasi 6"
git push origin v0.6
```

Tunggu sekitar 1 menit, lalu file `.zip` baru muncul di halaman Releases.
