import 'package:flutter/material.dart';
import '../search/Result.dart';
import '../search/Search.dart';

final RouteObserver<PageRoute> filterRouteObserver = RouteObserver<PageRoute>();

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class FilterPageApp extends StatelessWidget {
  const FilterPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FilterPage(),
      navigatorObservers: [filterRouteObserver],
    );
  }
}

class _FilterPageState extends State<FilterPage> with RouteAware {
  Map<String, bool> jenisHidangan = {
    "Makanan Sehat": false,
    "Makanan Sederhana": false,
    "Makanan Tradisional": false,
    "Diet": false,
    "Sarapan": false,
  };

  Map<String, bool> estimasiWaktu = {
    "<15 Min": false,
    "<30 Min": false,
    "<1 Hour": false,
  };

  Map<String, bool> tingkatKesulitan = {
    "Mudah": false,
    "Sedang": false,
    "Sulit": false,
  };

  TextEditingController bahanController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    filterRouteObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    filterRouteObserver.unsubscribe(this);
    bahanController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reset semua filter dan input bahan saat kembali dari ResultPage
    setState(() {
      jenisHidangan.updateAll((key, value) => false);
      estimasiWaktu.updateAll((key, value) => false);
      tingkatKesulitan.updateAll((key, value) => false);
      bahanController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.teal),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RecipePage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _buildSection("Jenis Hidangan", jenisHidangan),
              const SizedBox(height: 16),
              _buildSection("Estimasi Waktu", estimasiWaktu),
              const SizedBox(height: 16),
              _buildSection("Tingkat Kesulitan", tingkatKesulitan),
              const SizedBox(height: 16),
              const Text(
                "Bahan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD3EDEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: bahanController,
                  decoration: const InputDecoration(
                    hintText: "Search",
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        // Reset semua pilihan ke false
                        jenisHidangan.updateAll((key, value) => false);
                        estimasiWaktu.updateAll((key, value) => false);
                        tingkatKesulitan.updateAll((key, value) => false);

                        // Kosongkan input bahan
                        bahanController.clear();
                      });
                    },
                    child: const Text(
                      "Reset",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // Ambil filter yang dipilih user
                      String? selectedJenisHidangan =
                          jenisHidangan.entries
                              .firstWhere(
                                (e) => e.value,
                                orElse: () => const MapEntry('', false),
                              )
                              .key;
                      String? selectedEstimasiWaktu =
                          estimasiWaktu.entries
                              .firstWhere(
                                (e) => e.value,
                                orElse: () => const MapEntry('', false),
                              )
                              .key;
                      String? selectedTingkatKesulitan =
                          tingkatKesulitan.entries
                              .firstWhere(
                                (e) => e.value,
                                orElse: () => const MapEntry('', false),
                              )
                              .key;
                      String bahan = bahanController.text.trim();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ResultPage(
                                jenisHidangan:
                                    selectedJenisHidangan.isNotEmpty
                                        ? selectedJenisHidangan
                                        : null,
                                estimasiWaktu:
                                    selectedEstimasiWaktu.isNotEmpty
                                        ? selectedEstimasiWaktu
                                        : null,
                                tingkatKesulitan:
                                    selectedTingkatKesulitan.isNotEmpty
                                        ? selectedTingkatKesulitan
                                        : null,
                                bahan: bahan.isNotEmpty ? bahan : null,
                              ),
                        ),
                      );
                    },
                    child: const Text(
                      "Apply",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Map<String, bool> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Column(
          children:
              options.keys.map((String key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: options[key],
                  activeColor: Colors.teal,
                  onChanged: (bool? value) {
                    setState(() {
                      options[key] = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
        ),
      ],
    );
  }
}
