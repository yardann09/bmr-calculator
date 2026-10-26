import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kalkulator BMR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF00796B),
          useMaterial3: true,
        ),
        home: const BmrPage(),
      );
}

// ===== Rumus (sama dengan script.js) =====
double hitungMifflin(double w, double h, double a, bool pria) {
  final dasar = 10 * w + 6.25 * h - 5 * a;
  return pria ? dasar + 5 : dasar - 161;
}

double hitungHarris(double w, double h, double a, bool pria) {
  return pria
      ? 13.397 * w + 4.799 * h - 5.677 * a + 88.362
      : 9.247 * w + 3.098 * h - 4.330 * a + 447.593;
}

double hitungKatch(double w, double persenLemak) =>
    370 + 21.6 * (1 - persenLemak / 100) * w;

const daftarAktivitas = [
  ('Sedentari (sedikit/tidak olahraga)', 1.2),
  ('Ringan (olahraga 1-3x/minggu)', 1.375),
  ('Sedang (olahraga 4-5x/minggu)', 1.55),
  ('Aktif (olahraga harian/intens 3-4x/minggu)', 1.725),
  ('Sangat aktif (olahraga intens 6-7x/minggu)', 1.9),
];

// Format angka dengan pemisah ribuan titik (1.618)
String fmt(double n) => n
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

class BmrPage extends StatefulWidget {
  const BmrPage({super.key});
  @override
  State<BmrPage> createState() => _BmrPageState();
}

class _BmrPageState extends State<BmrPage> {
  final umurC = TextEditingController();
  final tinggiC = TextEditingController();
  final beratC = TextEditingController();
  final lemakC = TextEditingController();
  bool pria = true;
  String rumus = 'mifflin';
  double? bmr;

  void _pesan(String teks) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(teks)));

  void _hitung() {
    final umur = double.tryParse(umurC.text);
    final tinggi = double.tryParse(tinggiC.text);
    final berat = double.tryParse(beratC.text);

    if (umur == null || tinggi == null || berat == null ||
        umur <= 0 || tinggi <= 0 || berat <= 0) {
      _pesan('Mohon isi umur, tinggi, dan berat badan dengan benar.');
      return;
    }
    if (umur < 15 || umur > 80) {
      _pesan('Umur harus antara 15 sampai 80 tahun.');
      return;
    }

    double hasil;
    if (rumus == 'mifflin') {
      hasil = hitungMifflin(berat, tinggi, umur, pria);
    } else if (rumus == 'harris') {
      hasil = hitungHarris(berat, tinggi, umur, pria);
    } else {
      final lemak = double.tryParse(lemakC.text);
      if (lemak == null || lemak <= 0 || lemak >= 100) {
        _pesan('Mohon isi persentase lemak tubuh dengan benar (1-70%).');
        return;
      }
      hasil = hitungKatch(berat, lemak);
    }
    setState(() => bmr = hasil);
  }

  void _reset() {
    umurC.clear();
    tinggiC.clear();
    beratC.clear();
    lemakC.clear();
    setState(() {
      pria = true;
      rumus = 'mifflin';
      bmr = null;
    });
  }

  Widget _field(String label, TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator BMR')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Basal Metabolic Rate (BMR) adalah jumlah kalori yang dibutuhkan '
            'tubuh saat istirahat total untuk menjalankan fungsi dasar.',
          ),
          _field('Umur (tahun)', umurC, 'contoh: 20'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Pria')),
              ButtonSegment(value: false, label: Text('Wanita')),
            ],
            selected: {pria},
            onSelectionChanged: (s) => setState(() => pria = s.first),
          ),
          _field('Tinggi Badan (cm)', tinggiC, 'contoh: 170'),
          _field('Berat Badan (kg)', beratC, 'contoh: 65'),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: rumus,
            decoration: const InputDecoration(
              labelText: 'Rumus Perhitungan',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'mifflin', child: Text('Mifflin-St Jeor')),
              DropdownMenuItem(value: 'harris', child: Text('Revised Harris-Benedict')),
              DropdownMenuItem(value: 'katch', child: Text('Katch-McArdle (butuh % lemak)')),
            ],
            onChanged: (v) => setState(() => rumus = v!),
          ),
          if (rumus == 'katch')
            _field('Persentase Lemak Tubuh (%)', lemakC, 'contoh: 20'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: FilledButton(onPressed: _hitung, child: const Text('Hitung'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(onPressed: _reset, child: const Text('Reset'))),
          ]),
          if (bmr != null) ...[
            const Divider(height: 40),
            Text('Hasil', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('BMR = ${fmt(bmr!)} kalori/hari',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final (nama, faktor) in daftarAktivitas)
              ListTile(
                dense: true,
                title: Text(nama),
                trailing: Text(fmt(bmr! * faktor)),
              ),
          ],
        ],
      ),
    );
  }
}
/*
 * KALKULATOR BMR (Flutter/Dart)
 * Alur program:
 * 1. Pengguna mengisi umur, jenis kelamin, tinggi, berat, dan memilih rumus.
 * 2. Saat tombol "Hitung" ditekan, fungsi _hitung() mengambil dan memvalidasi input.
 * 3. BMR dihitung sesuai rumus yang dipilih.
 * 4. Hasil dan kebutuhan kalori per tingkat aktivitas ditampilkan.
 */