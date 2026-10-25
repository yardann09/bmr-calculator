/*
 * KALKULATOR BMR (Basal Metabolic Rate)
 * ------------------------------------------------------------
 * Alur program:
 * 1. Pengguna mengisi umur, jenis kelamin, tinggi, berat, dan memilih rumus.
 * 2. Saat tombol "Hitung" ditekan, program mengambil nilai input.
 * 3. Program memvalidasi input (tidak boleh kosong / di luar batas).
 * 4. Program menghitung BMR sesuai rumus yang dipilih.
 * 5. Program menghitung kebutuhan kalori harian untuk tiap tingkat aktivitas
 *    (BMR x faktor aktivitas).
 * 6. Hasil ditampilkan ke halaman.
 */

// ===== 1. Mengambil elemen-elemen HTML yang akan digunakan =====
const form = document.getElementById("bmrForm");
const rumusSelect = document.getElementById("rumus");
const lemakGroup = document.getElementById("lemakGroup");
const lemakInput = document.getElementById("lemak");
const hasilSection = document.getElementById("hasil");
const bmrAngka = document.getElementById("bmrAngka");
const tabelAktivitas = document.getElementById("tabelAktivitas");

// Daftar tingkat aktivitas beserta faktor pengalinya (Harris-Benedict activity factor)
const daftarAktivitas = [
  { nama: "Sedentari (sedikit/tidak olahraga)", faktor: 1.2 },
  { nama: "Ringan (olahraga 1-3x/minggu)", faktor: 1.375 },
  { nama: "Sedang (olahraga 4-5x/minggu)", faktor: 1.55 },
  { nama: "Aktif (olahraga harian/intens 3-4x/minggu)", faktor: 1.725 },
  { nama: "Sangat aktif (olahraga intens 6-7x/minggu)", faktor: 1.9 },
];

// ===== 2. Menampilkan/menyembunyikan input lemak tubuh =====
// Input % lemak hanya diperlukan untuk rumus Katch-McArdle
rumusSelect.addEventListener("change", function () {
  if (rumusSelect.value === "katch") {
    lemakGroup.classList.remove("hidden");
    lemakInput.required = true;
  } else {
    lemakGroup.classList.add("hidden");
    lemakInput.required = false;
  }
});

// ===== 3. Fungsi-fungsi perhitungan BMR =====

/**
 * Rumus Mifflin-St Jeor
 * Pria   : (10 x berat) + (6.25 x tinggi) - (5 x umur) + 5
 * Wanita : (10 x berat) + (6.25 x tinggi) - (5 x umur) - 161
 */
function hitungMifflin(berat, tinggi, umur, gender) {
  const dasar = 10 * berat + 6.25 * tinggi - 5 * umur;
  return gender === "pria" ? dasar + 5 : dasar - 161;
}

/**
 * Rumus Revised Harris-Benedict
 * Pria   : 13.397W + 4.799H - 5.677A + 88.362
 * Wanita : 9.247W + 3.098H - 4.330A + 447.593
 */
function hitungHarris(berat, tinggi, umur, gender) {
  if (gender === "pria") {
    return 13.397 * berat + 4.799 * tinggi - 5.677 * umur + 88.362;
  }
  return 9.247 * berat + 3.098 * tinggi - 4.33 * umur + 447.593;
}

/**
 * Rumus Katch-McArdle (berdasarkan massa tubuh tanpa lemak)
 * BMR = 370 + 21.6 x (1 - lemak/100) x berat
 */
function hitungKatch(berat, persenLemak) {
  return 370 + 21.6 * (1 - persenLemak / 100) * berat;
}

// ===== 4. Fungsi untuk menampilkan hasil ke halaman =====
function tampilkanHasil(bmr) {
  // Tampilkan nilai BMR (dibulatkan, diberi pemisah ribuan)
  bmrAngka.textContent = Math.round(bmr).toLocaleString("id-ID");

  // Kosongkan tabel sebelum diisi ulang
  tabelAktivitas.innerHTML = "";

  // Isi tabel: kalori harian = BMR x faktor aktivitas
  daftarAktivitas.forEach(function (aktivitas) {
    const kalori = Math.round(bmr * aktivitas.faktor);
    const baris = document.createElement("tr");
    baris.innerHTML =
      "<td>" + aktivitas.nama + "</td>" +
      "<td>" + kalori.toLocaleString("id-ID") + "</td>";
    tabelAktivitas.appendChild(baris);
  });

  // Tampilkan bagian hasil
  hasilSection.classList.remove("hidden");
}

// ===== 5. Proses utama saat tombol "Hitung" ditekan =====
form.addEventListener("submit", function (event) {
  // Mencegah halaman reload saat form di-submit
  event.preventDefault();

  // Ambil nilai dari input dan ubah ke angka
  const umur = parseFloat(document.getElementById("umur").value);
  const tinggi = parseFloat(document.getElementById("tinggi").value);
  const berat = parseFloat(document.getElementById("berat").value);
  const gender = document.querySelector('input[name="gender"]:checked').value;
  const rumus = rumusSelect.value;

  // Validasi: semua input wajib angka positif
  if (isNaN(umur) || isNaN(tinggi) || isNaN(berat) || umur <= 0 || tinggi <= 0 || berat <= 0) {
    alert("Mohon isi umur, tinggi, dan berat badan dengan benar.");
    return;
  }

  // Validasi rentang umur sesuai referensi kalkulator (15-80 tahun)
  if (umur < 15 || umur > 80) {
    alert("Umur harus antara 15 sampai 80 tahun.");
    return;
  }

  // Hitung BMR berdasarkan rumus yang dipilih
  let bmr;
  if (rumus === "mifflin") {
    bmr = hitungMifflin(berat, tinggi, umur, gender);
  } else if (rumus === "harris") {
    bmr = hitungHarris(berat, tinggi, umur, gender);
  } else {
    const persenLemak = parseFloat(lemakInput.value);
    // Validasi khusus Katch-McArdle: % lemak harus diisi
    if (isNaN(persenLemak) || persenLemak <= 0 || persenLemak >= 100) {
      alert("Mohon isi persentase lemak tubuh dengan benar (1-70%).");
      return;
    }
    bmr = hitungKatch(berat, persenLemak);
  }

  // Tampilkan hasil perhitungan
  tampilkanHasil(bmr);
});

// ===== 6. Tombol Reset: sembunyikan hasil & input lemak =====
document.getElementById("btnReset").addEventListener("click", function () {
  hasilSection.classList.add("hidden");
  lemakGroup.classList.add("hidden");
  lemakInput.required = false;
});
