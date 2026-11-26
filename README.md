# 🌙 Tiny Haven

**A Cozy Miniature World Builder**: gim santai untuk membangun diorama kecil di malam hari.

Tidak ada musuh, tidak ada misi, tidak ada batas waktu. Kamu cukup menata pohon, tembok batu, tenda, api unggun, dan lentera sesukamu, lalu menikmati cahaya hangat yang menerangi padang malam.

<p align="center">
  <img src="docs/screenshots/menu-utama.png" alt="Menu utama Tiny Haven" width="720">
</p>

<p align="center">
  <img src="docs/screenshots/dunia-malam.png" alt="Dunia malam dengan tembok, tenda, api unggun, dan lentera" width="720">
</p>

---

## Daftar isi
- [Cara memainkan](#cara-memainkan)
- [Kontrol](#kontrol)
- [Alat bangun](#alat-bangun)
- [Menu dan pengaturan](#menu-dan-pengaturan)
- [Untuk pengembang](#untuk-pengembang)
- [Tim dan kredit](#tim-dan-kredit)

---

## Cara memainkan

Saat ini Tiny Haven dijalankan langsung dari Godot (belum ada file `.exe`).

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
| 9 | Hapus | Klik objek di dalam lingkaran merah untuk menghapusnya. |

Sebelum ditaruh, objek tampil transparan di bawah kursor supaya kamu bisa melihat hasilnya dulu. Kamu hanya bisa membangun di dalam lingkaran tipis berwarna lavender. Di luarnya ada hutan pembatas.

## Menu dan pengaturan

- **Mulai**: membuat dunia baru dengan kemah kecil sebagai titik awal.
- **Lanjutkan**: membuka dunia yang terakhir disimpan. Tombol ini redup kalau belum ada simpanan.
- **Pengaturan**: layar penuh, VSync, kualitas bayangan, dan anti-aliasing. Perubahan langsung berlaku dan diingat.
- **Kredit**: tim pembuat dan sumber aset.

Dunia tersimpan otomatis saat kamu kembali ke menu utama lewat menu jeda.

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
│   └── world/            Dunia, kamera, tembok, penaruh objek, hewan, efek cahaya
├── shaders/              Shader langit malam (bintang dan bulan sabit)
├── tests/                Tes otomatis yang dijalankan tanpa layar
├── docs/                 Tangkapan layar dan aturan kerja tim
├── LICENSES.md           Sumber dan lisensi aset
└── project.godot
```

### Materi Komputer Grafis yang dipakai

- **Pencahayaan**: cahaya bulan (directional light) dengan bayangan, serta point light dari api unggun dan lentera. Api unggun berkedip memakai dua gelombang sinus.
- **Shading dan material**: bahan emissive pada kaca lentera dan bara api yang memicu efek glow, serta ghost preview transparan.
- **Shader**: `shaders/night_sky.gdshader` menggambar gradasi langit, bintang dari fungsi hash, dan bulan sabit dari dua lingkaran yang dikurangkan.
- **Geometri prosedural**: tembok disusun dari ribuan batu kotak memakai MultiMesh, dan lentera dibuat dari primitif.
- **Transformasi**: rotasi, skala acak, dan proyeksi kursor ke bidang tanah (ray casting).

### Menjalankan tes

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/save_load_test.gd
godot --headless --path . -s res://tests/ui_flow_test.gd
```

Tes yang sama berjalan otomatis di GitHub Actions setiap ada push (lihat tab **Actions**).

### Mengambil tangkapan layar untuk laporan

```bash
godot --path . -- --shot=user://menu.png
godot --path . -- --world --shot=user://dunia.png --frames=120
```

Tambahkan `--continue` untuk memotret dunia yang tersimpan. File `user://` ada di `%APPDATA%\Godot\app_userdata\Tiny Haven\` (Windows).

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
