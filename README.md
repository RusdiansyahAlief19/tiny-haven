# Tiny Haven
A Cozy Miniature World Builders

<p align="center">
  <img src="assets/icon/icon-game.png" alt="Ikon Tiny Haven" width="360">
</p>

## Teknologi
- Godot versi: 4.7.2 
- Bahasa: GDScript
- Renderer: Forward+
- Git LFS untuk aset berukuran besar

## Mulai project
Pastikan Godot dan Git LFS sudah terpasang, lalu jalankan:

```bash
git lfs install
git clone https://github.com/AhmadSyafiNurroyyan/tiny-haven-komgraf-project.git
cd tiny-haven-komgraf-project
```

Buka `project.godot` lewat Godot Project Manager dan tunggu impor aset selesai.

## Workflow
- Kerjakan perubahan di branch `feature/<nama-singkat>`, bukan langsung di `main` agar tidak konflik.
- Awali pesan commit dengan `feat:`, `fix:`, atau `chore:` sesuai perubahan.

## Iterasi 4: masuk ke dunia permainan
- Menu utama sekarang menjadi scene pertama. Mulai membuka dunia baru, Lanjutkan memuat dunia tersimpan, Pengaturan mengatur layar penuh, VSync, kualitas bayangan, dan anti-aliasing, Kredit menampilkan tim dan aset.
- Dunia bertema malam dengan langit dari shader (`shaders/night_sky.gdshader`: gradasi, bintang, bulan sabit), kabut ungu, dan hutan pembatas.
- Sembilan alat bangun: Tembok, Pohon, Batu, Tanaman, Pagar, Tenda, Api unggun (cahaya berkedip + bara), Lentera (cahaya hangat), dan Hapus.
- Dunia tersimpan di `user://tiny_haven_world.json` (F5, menu jeda, atau otomatis saat kembali ke menu).

| Kontrol | Fungsi |
|---|---|
| 1-9 / klik toolbar | pilih alat |
| Klik kiri | taruh objek / titik tembok |
| Klik kanan | selesai tembok / putar objek |
| R | putar objek |
| Z | undo |
| Shift | kunci ke grid 0,5 m |
| Klik tengah + geser, scroll | putar dan zoom kamera |
| WASD / panah | geser kamera |
| F5 | simpan |
| H | sembunyikan bantuan |
| Esc | menu jeda |

Tangkapan layar untuk laporan bisa diambil otomatis:
`godot --path . -- --world --shot=user://dunia.png --frames=120`
