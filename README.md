# 🌙 Tiny Haven

**A Cozy Miniature World Builder**: gim santai untuk membangun diorama kecil di malam hari.

Tidak ada musuh, tidak ada misi, tidak ada batas waktu. Kamu cukup menata pohon, tembok batu, tenda, api unggun, dan lentera sesukamu, lalu menikmati cahaya hangat yang menerangi padang malam.

> **Versi terbaru: v0.5 (Iterasi 5)** menambahkan siklus siang-malam, cuaca hujan dan angin, tantangan santai, dan domba yang berkumpul di api unggun. Versi sebelumnya tetap tersedia, lihat [Versi](#versi).

<p align="center">
  <img src="docs/screenshots/menu-utama.png" alt="Menu utama Tiny Haven" width="720">
</p>

<p align="center">
  <img src="docs/screenshots/dunia-malam.png" alt="Dunia malam dengan tembok, tenda, api unggun, dan lentera" width="720">
</p>

<p align="center">
  <img src="docs/screenshots/siang-berangin.png" alt="Siang hari yang berangin" width="355">
  <img src="docs/screenshots/malam-hujan.png" alt="Malam hujan dengan lentera menyala" width="355">
</p>

---

## Daftar isi
- [Cara memainkan](#cara-memainkan)
- [Kontrol](#kontrol)
- [Alat bangun](#alat-bangun)
- [Siang, malam, dan cuaca](#siang-malam-dan-cuaca)
- [Tantangan santai](#tantangan-santai)
- [Menu dan pengaturan](#menu-dan-pengaturan)
- [Versi](#versi)
- [Untuk pengembang](#untuk-pengembang)
- [Tim dan kredit](#tim-dan-kredit)

---

## Cara memainkan

### Cara termudah (Windows, tanpa Godot)

1. Buka halaman [Releases](https://github.com/RusdiansyahAlief19/tiny-haven/releases/latest).
2. Unduh file **TinyHaven-...-windows.zip**, lalu ekstrak.
3. Jalankan **TinyHaven.exe**.

Mau membagikan versi browser lewat itch.io? Lihat [docs/DEPLOY.md](docs/DEPLOY.md).

### Lewat Godot (untuk mengubah atau mengembangkan game)

1. **Unduh Godot 4.7.2** (versi standar, bukan .NET) dari [godotengine.org](https://godotengine.org/download/archive/4.7.2-stable/).
2. **Unduh proyek ini.** Paling mudah pakai Git (perlu [Git LFS](https://git-lfs.com) karena ada model 3D):
   ```bash
   git lfs install
   git clone https://github.com/RusdiansyahAlief19/tiny-haven.git
   ```
   > Kalau mengunduh lewat tombol **Code → Download ZIP**, model 3D bisa tidak ikut terunduh. Gunakan Git kalau bisa.
3. **Buka Godot**, klik **Import**, lalu pilih file `project.godot` di folder `tiny-haven`.
4. Tunggu impor aset selesai, lalu tekan **F5** (atau tombol ▶ di kanan atas). Game dimulai dari menu utama.

## Kontrol

| Tombol | Fungsi |
|---|---|
| **1 – 9** atau klik toolbar | Pilih alat bangun |
| **Klik kiri** | Taruh objek / tambah titik tembok |
| **Klik kanan** | Selesaikan tembok / putar objek |
| **R** | Putar objek |
| **Z** | Batalkan (undo) |
| **Tahan Shift** | Kunci posisi ke grid 0,5 m |
| **W A S D** atau **panah** | Geser kamera |
| **Klik tengah + geser** | Putar kamera |
| **Scroll** | Zoom kamera |
| **T** | Ubah kecepatan waktu (1x, 6x, berhenti) |
| **C** | Ganti cuaca (cerah, berangin, hujan) |
| **J** | Tampilkan / sembunyikan daftar tantangan |
| **F5** | Simpan dunia |
| **H** | Sembunyikan / tampilkan bantuan |
| **Esc** | Menu jeda |

## Alat bangun

| No. | Alat | Keterangan |
|---|---|---|
| 1 | Tembok | Klik beberapa titik, klik kanan untuk selesai. Tembok yang panjang otomatis punya pintu. |
| 2 | Pohon | Jenis dan ukurannya diacak setiap kali ditaruh. |
| 3 | Batu | Batu, tunggul kayu, dan tumpukan kayu. |
| 4 | Tanaman | Bunga dan jamur kecil. |
| 5 | Pagar | Pagar kayu, putar dengan **R**. |
| 6 | Tenda | Tenda kemah. |
| 7 | Api | Api unggun dengan cahaya berkedip dan percikan bara. |
| 8 | Lentera | Lampu kecil bercahaya hangat. |
| 9 | Hapus | Klik objek atau tembok di dalam lingkaran merah untuk menghapusnya. Satu klik pada tembok menghapus tembok itu seluruhnya. |

Sebelum ditaruh, objek tampil transparan di bawah kursor supaya kamu bisa melihat hasilnya dulu. Kamu hanya bisa membangun di dalam lingkaran tipis berwarna lavender. Di luarnya ada hutan pembatas.

## Siang, malam, dan cuaca

- **Waktu berjalan sendiri.** Satu hari penuh sekitar 5 menit. Dunia baru dimulai menjelang malam (19:30). Jam tampil di kiri atas.
- **Lampu otomatis.** Saat gelap, lentera dan api unggun menyala sendiri. Saat siang mereka padam.
- **Cuaca berganti sendiri** setiap 1 sampai 2 menit, atau tekan **C** untuk menggantinya:
  - *Cerah*: langit bersih, bintang dan bulan terlihat di malam hari.
  - *Berangin*: pohon dan bunga bergoyang.
  - *Hujan*: hujan turun, angin bertiup, dan langit lebih gelap.
- **Domba** berkumpul mengelilingi api unggun terdekat saat malam, lalu berkeliaran lagi saat pagi.

## Tantangan santai

Tantangan ini tidak wajib, tidak punya batas waktu, dan tidak ada kalah. Gunanya sekadar memberi ide kalau kamu bingung mau membangun apa. Tekan **J** untuk melihat daftarnya.

1. Terangi kemah dengan 4 lentera
2. Tanam hutan kecil: 10 pohon
3. Nyalakan 2 api unggun
4. Bangun tembok yang punya pintu (buat satu sisi tembok lebih dari 4 meter)
5. Kelilingi tenda dengan tembok (titik terakhir tembok harus kembali ke dekat titik awal)
6. Lewati satu malam sampai pagi
7. Nikmati hujan di Tiny Haven
8. Kumpulkan 3 domba di api unggun

Tantangan yang sudah selesai ikut tersimpan bersama dunia.

## Menu dan pengaturan

- **Mulai**: membuat dunia baru dengan kemah kecil sebagai titik awal.
- **Lanjutkan**: membuka dunia yang terakhir disimpan. Tombol ini redup kalau belum ada simpanan.
- **Pengaturan**: layar penuh, VSync, kualitas bayangan, dan anti-aliasing. Perubahan langsung berlaku dan diingat.
- **Kredit**: tim pembuat dan sumber aset.

Dunia tersimpan otomatis saat kamu kembali ke menu utama lewat menu jeda.

## Versi

| Versi | Isi | Cara memakai |
|---|---|---|
| **v0.5.2** (terbaru, branch `main`) | Siap dimainkan: ada file .exe dan versi web di Releases | Unduh dari Releases, atau clone biasa |
| **v0.5.1** | Perbaikan: alat Hapus bisa menghapus tembok | `git checkout v0.5.1` |
| **v0.5** | Siang-malam, cuaca, tantangan, domba bereaksi | `git checkout v0.5` |
| **v0.4** | Menu berfungsi, dunia malam, 9 alat bangun, simpan/muat | `git checkout v0.4` setelah clone, atau unduh dari halaman [Releases](https://github.com/RusdiansyahAlief19/tiny-haven/releases) |

Kembali ke versi terbaru dengan `git checkout main`.

---

## Untuk pengembang

### Struktur folder

```
tiny-haven/
├── assets/
│   ├── fonts/            Font judul (Magic Light) dan antarmuka (Minecraft)
│   ├── icon/             Ikon game
│   └── model/nature/     Model 3D Kenney Nature Kit (.glb, Git LFS)
├── scenes/
│   ├── ui/main_menu.tscn     Scene pertama: menu utama
│   └── world/main.tscn       Dunia permainan
├── scripts/
│   ├── core/             Status global (autoload GameState: pengaturan & simpanan)
│   ├── ui/               Menu, HUD, panel pengaturan, gaya antarmuka bersama
│   └── world/            Dunia, kamera, tembok, objek, siang-malam, cuaca, tantangan, hewan
├── shaders/              Shader langit (siang/malam, bintang, bulan) dan goyangan angin
├── tests/                Tes otomatis yang dijalankan tanpa layar
├── docs/                 Tangkapan layar, panduan deploy, aturan kerja tim
├── LICENSES.md           Sumber dan lisensi aset
└── project.godot
```

### Materi Komputer Grafis yang dipakai

- **Pencahayaan**: cahaya bulan (directional light) dengan bayangan, serta point light dari api unggun dan lentera. Api unggun berkedip memakai dua gelombang sinus.
- **Shading dan material**: bahan emissive pada kaca lentera dan bara api yang memicu efek glow, serta ghost preview transparan.
- **Shader**: `shaders/night_sky.gdshader` menggambar gradasi langit, bintang dari fungsi hash, bulan sabit dari dua lingkaran yang dikurangkan, dan matahari saat siang.
- **Vertex shader**: `shaders/wind_sway.gdshader` menggoyangkan pohon. Geseran tiap titik naik kuadratik terhadap tingginya, mengikuti gelombang sinus.
- **Interpolasi warna**: siklus siang-malam mencampur (lerp) warna langit, kabut, cahaya, dan rumput antara palet siang, senja, dan malam berdasarkan tinggi matahari.
- **Sistem partikel**: hujan (ribuan tetes yang mengikuti kamera dan miring tertiup angin), bara api, dan kunang-kunang.
- **Geometri prosedural**: tembok disusun dari ribuan batu kotak memakai MultiMesh, dan lentera dibuat dari primitif.
- **Transformasi**: rotasi, skala acak, dan proyeksi kursor ke bidang tanah (ray casting).

### Menjalankan tes

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/save_load_test.gd
godot --headless --path . -s res://tests/ui_flow_test.gd
godot --headless --path . -s res://tests/iteration5_test.gd
```

Tes yang sama berjalan otomatis di GitHub Actions setiap ada push (lihat tab **Actions**).

### Mengambil tangkapan layar untuk laporan

```bash
godot --path . -- --shot=user://menu.png
godot --path . -- --world --shot=user://dunia.png --frames=120
```

Tambahkan `--continue` untuk memotret dunia yang tersimpan, `--time=13` untuk mengatur jam, dan `--weather=2` untuk cuaca (0 cerah, 1 berangin, 2 hujan). File `user://` ada di `%APPDATA%\Godot\app_userdata\Tiny Haven\` (Windows).

---

## Tim dan kredit

Dibuat oleh **Regu Tulip** untuk mata kuliah Komputer Grafis, Tahun Ajaran 2026/2027.

- Rusdiansyah Alief Prasetya
- Fevoura Agnesia Tatontos
- Ahmad Syafi Nurroyyan
- Shafiyyah Daniswara Nurwijayanti

Aset pihak ketiga:
- Model 3D: [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) (CC0)
- Font judul: [Magic Light](https://www.fontspace.com/magic-light-font-f107354) oleh Edric Studio (versi demo, khusus penggunaan pribadi)
- Font antarmuka: Minecraft

Detail lisensi tiap aset ada di [LICENSES.md](LICENSES.md). Repo induk tim: [AhmadSyafiNurroyyan/tiny-haven-komgraf-project](https://github.com/AhmadSyafiNurroyyan/tiny-haven-komgraf-project).
