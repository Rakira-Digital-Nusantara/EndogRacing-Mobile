import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../kandang/providers/kandang_telur_provider.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/kandang_header_card.dart';
import '../../../shared/widgets/app_button.dart';

class InputProduksiScreen extends StatefulWidget {
  const InputProduksiScreen({super.key});

  @override
  State<InputProduksiScreen> createState() => _InputProduksiScreenState();
}

class _InputProduksiScreenState extends State<InputProduksiScreen> {
  bool _isLoadingForm = false;
  String _formError = '';
  bool _isSubmitting = false;

  String _skuUtuh = '1500123';
  String _skuRusak = '100001';
  String _gudangCode = 'GDG0001';

  int _populasi = 0;
  DateTime _tanggalPanen = DateTime.now();

  // Sisa kemarin di kandang (dari API /produksi-telur/form)
  double _sisaTelurKemarinKg = 0.0;

  // Tab State: 0 = Utuh, 1 = Rusak
  int _selectedTabIndex = 0;

  // Input Data Utuh
  int _qtyUtuhButir = 0;
  double _qtyUtuhKg = 0.0;

  // Input Data Rusak
  int _qtyRusakButir = 0;
  double _qtyRusakKg = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchForm();
  }

  Future<void> _fetchForm() async {
    setState(() {
      _isLoadingForm = true;
      _formError = '';
    });

    final kandangCode = context.read<AuthProvider>().kandang?.kdgCode ?? "KDG-001";

    try {
      final response = await DioClient().dio.get('/produksi-telur/form?kdg_code=$kandangCode');
      if (response.statusCode == 200) {
        final rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          final innerData = rawData['data'];
          if (innerData is Map) {
            // 1. Gudang Code
            if (innerData.containsKey('gudang_code') && innerData['gudang_code'] != null) {
              _gudangCode = innerData['gudang_code'].toString();
            }

            // 2. Populasi
            if (innerData.containsKey('populasi_ayam_saat_ini')) {
              setState(() {
                _populasi = int.tryParse(innerData['populasi_ayam_saat_ini'].toString()) ?? 0;
              });
            }

            // 3. Saldo Telur Kandang (Sisa Kemarin)
            if (innerData.containsKey('saldo_telur_kandang') && innerData['saldo_telur_kandang'] is List) {
              final List saldos = innerData['saldo_telur_kandang'];
              for (var s in saldos) {
                final kat = s['kategori']?.toString().toLowerCase() ?? '';
                if (kat.contains('utuh')) {
                  final saldoVal = (s['saldo_kg'] is num)
                      ? (s['saldo_kg'] as num).toDouble()
                      : double.tryParse(s['saldo_kg']?.toString() ?? '0') ?? 0.0;
                  setState(() {
                    _sisaTelurKemarinKg = saldoVal;
                  });
                  if (s['sku_product'] != null && s['sku_product'].toString().isNotEmpty) {
                    _skuUtuh = s['sku_product'].toString();
                  }
                  break;
                }
              }
            }

            // 4. SKU dari items
            if (innerData.containsKey('items') && innerData['items'] is List) {
              final List items = innerData['items'];
              for (var item in items) {
                final sku = item['sku_product']?.toString() ?? '';
                final name = item['sku_name']?.toString().toLowerCase() ?? '';
                if (name.contains('utuh') && sku.isNotEmpty) {
                  _skuUtuh = sku;
                } else if ((name.contains('rusak') || name.contains('bentes') || name.contains('retak') || name.contains('afkir')) && sku.isNotEmpty) {
                  _skuRusak = sku;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      String errMsg = 'Gagal memuat form produksi';
      if (e is DioException) {
        errMsg = e.response?.data?['message']?.toString() ?? e.message ?? errMsg;
      }
      setState(() {
        _formError = errMsg;
      });
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _submitProduksi() async {
    List<Map<String, dynamic>> details = [];

    if (_qtyUtuhButir > 0 || _qtyUtuhKg > 0) {
      details.add({
        "sku_product": _skuUtuh,
        "kategori": "Utuh",
        "qty_butir": _qtyUtuhButir,
        "qty_kg": _qtyUtuhKg,
      });
    }

    if (_qtyRusakButir > 0 || _qtyRusakKg > 0) {
      details.add({
        "sku_product": _skuRusak,
        "kategori": "Rusak",
        "qty_butir": _qtyRusakButir,
        "qty_kg": _qtyRusakKg,
      });
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Qty minimal pada salah satu telur!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final kandangCode = context.read<AuthProvider>().kandang?.kdgCode ?? "KDG-001";

    final payload = {
      "kdg_code": kandangCode,
      if (_gudangCode.isNotEmpty) "gudang_code": _gudangCode,
      "tanggal": _tanggalPanen.toIso8601String().split('T')[0],
      "details": details,
    };

    try {
      final response = await DioClient().dio.post('/produksi-telur', data: payload);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh saldo di provider & dashboard
        context.read<KandangTelurProvider>().fetchSaldoKandang(kandangCode);
        context.read<DashboardProvider>().fetchDashboardData(kandangCode);

        // Ambil info stok jika ada
        String infoSubtitle = 'Data produksi panen telur telah dicatat ke stok kandang.';
        int potensiKasBaru = ((_sisaTelurKemarinKg + _qtyUtuhKg) / 15.0).floor();

        if (response.data is Map && response.data['stok_kandang_info'] is List) {
          final List infoList = response.data['stok_kandang_info'];
          if (infoList.isNotEmpty && infoList.first['label'] != null) {
            infoSubtitle = infoList.first['label'].toString();
          }
        }

        showDialog(
          context: context,
          builder: (dialogContext) => SuccessDialog(
            title: 'Panen Berhasil Disimpan',
            subtitle: infoSubtitle,
            time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
            primaryButtonText: potensiKasBaru > 0 ? 'Setor Kas ke Gudang Sekarang' : 'Selesai',
            primaryIcon: potensiKasBaru > 0 ? Icons.local_shipping_outlined : Icons.check_circle_outline,
            secondaryButtonText: potensiKasBaru > 0 ? 'Selesai' : null,
            secondaryIcon: null,
            onPrimaryPressed: () {
              Navigator.pop(dialogContext);
              if (potensiKasBaru > 0) {
                // Navigasi langsung ke form setor kas
                context.push('/setor-telur');
              } else {
                context.pop();
              }
            },
            onSecondaryPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      String errorMessage = 'Terjadi kesalahan koneksi';
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data.containsKey('errors') && data['errors'] != null) {
            final errs = data['errors'];
            if (errs is Map) {
              errorMessage = errs.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
            } else if (errs is List) {
              errorMessage = errs.join('\n');
            } else {
              errorMessage = errs.toString();
            }
          } else if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          }
        } else {
          errorMessage = 'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan tidak terduga: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';

    // Hitung persentase produktivitas
    double produktivitas = 0.0;
    double rusak = 0.0;

    if (_populasi > 0) {
      produktivitas = ((_qtyUtuhButir + _qtyRusakButir) / _populasi) * 100;
      rusak = (_qtyRusakButir / _populasi) * 100;
    }

    // Kalkulasi Realtime Panen & Potensi Kas (Telur Utuh)
    final double totalDiKandangKg = _sisaTelurKemarinKg + _qtyUtuhKg;
    final int potensiKas = (totalDiKandangKg / 15.0).floor();
    final double sisaMengendapKg = totalDiKandangKg % 15.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Input Panen Harian',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoadingForm
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _formError.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_formError, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchForm, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KandangHeaderCard(
                        kandangName: kandangName,
                        subtitleText: 'Pencatatan Panen Telur (Satuan Kg)',
                        icon: Icons.cottage_outlined,
                      ),
                      const SizedBox(height: 16),

                      // BANNER INFORMASI ATAS: SISA KEMARIN
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF), // Soft Blue
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A8A)),
                                  children: [
                                    const TextSpan(text: 'Sisa Telur Kemarin di Kandang: '),
                                    TextSpan(
                                      text: '${_sisaTelurKemarinKg.toStringAsFixed(1)} Kg',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // TANGGAL PANEN PICKER
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggalPanen,
                            firstDate: DateTime(2025),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _tanggalPanen = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              const Text('Tanggal Panen:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              Text(
                                '${_tanggalPanen.day}/${_tanggalPanen.month}/${_tanggalPanen.year}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CARD PERSENTASE PRODUKTIVITAS
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F6F3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.trending_up, color: Color(0xFF166534), size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Produktivitas',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        produktivitas.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.show_chart, color: Colors.red.shade700, size: 16),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Rusak',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        rusak.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // TAB BAR TOGGLE (Utuh / Rusak)
                      Container(
                        height: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 0),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _selectedTabIndex == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    'Telur Utuh',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTabIndex == 0 ? const Color(0xFF166534) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _selectedTabIndex == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    'Telur Rusak/Bentes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTabIndex == 1 ? const Color(0xFF166534) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // INPUT FORM CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Jumlah Butir Input
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Jumlah Butir', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('BUTIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _IntegerInput(
                              value: _selectedTabIndex == 0 ? _qtyUtuhButir : _qtyRusakButir,
                              onChanged: (val) {
                                setState(() {
                                  if (_selectedTabIndex == 0) {
                                    _qtyUtuhButir = val;
                                  } else {
                                    _qtyRusakButir = val;
                                  }
                                });
                              },
                              accentColor: const Color(0xFF166534),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                            ),

                            // Berat Kg Input
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedTabIndex == 0 ? 'Berat Panen Hari Ini (Utuh)' : 'Berat Rusak Hari Ini',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('KG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _DecimalInput(
                              value: _selectedTabIndex == 0 ? _qtyUtuhKg : _qtyRusakKg,
                              onChanged: (val) {
                                setState(() {
                                  if (_selectedTabIndex == 0) {
                                    _qtyUtuhKg = val;
                                  } else {
                                    _qtyRusakKg = val;
                                  }
                                });
                              },
                              accentColor: const Color(0xFF166534),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // LIVE PREVIEW KALKULASI KAS & SISA MENGENDAP
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // Warm amber background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate_outlined, color: Color(0xFFD97706), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Kalkulasi Persediaan Kandang (Utuh)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total di Kandang (Sisa + Hari Ini):', style: TextStyle(fontSize: 13, color: Color(0xFF78350F))),
                                Text(
                                  '${totalDiKandangKg.toStringAsFixed(1)} Kg',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Potensi Siap Setor (@ 15 Kg):', style: TextStyle(fontSize: 13, color: Color(0xFF78350F))),
                                Text(
                                  '$potensiKas Kas (${(potensiKas * 15).toStringAsFixed(1)} Kg)',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Sisa Pecahan Mengendap:', style: TextStyle(fontSize: 13, color: Color(0xFF78350F))),
                                Text(
                                  '${sisaMengendapKg.toStringAsFixed(1)} Kg',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
      bottomNavigationBar: _isLoadingForm || _formError.isNotEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  child: AppButton(
                    onPressed: _submitProduksi,
                    isLoading: _isSubmitting,
                    text: 'Simpan Panen Kandang',
                    trailingIcon: Icons.check_circle,
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// WIDGET INPUT INTEGER (JUMLAH BUTIR)
// ============================================================================
class _IntegerInput extends StatefulWidget {
  final int value;
  final Function(int) onChanged;
  final Color accentColor;

  const _IntegerInput({
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<_IntegerInput> createState() => _IntegerInputState();
}

class _IntegerInputState extends State<_IntegerInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _IntegerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (_controller.text != widget.value.toString()) {
        _controller.text = widget.value.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF1F5F9);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.value > 0 ? () => widget.onChanged(widget.value - 1) : null,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.remove, color: widget.value > 0 ? widget.accentColor : Colors.grey.shade400),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 5),
                isDense: true,
              ),
              onChanged: (val) {
                if (val.isEmpty) {
                  widget.onChanged(0);
                  return;
                }
                final intVal = int.tryParse(val);
                if (intVal != null) {
                  widget.onChanged(intVal);
                }
              },
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onChanged(widget.value + 1),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add, color: widget.accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET INPUT DECIMAL (BERAT KG)
// ============================================================================
class _DecimalInput extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  final Color accentColor;

  const _DecimalInput({
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<_DecimalInput> createState() => _DecimalInputState();
}

class _DecimalInputState extends State<_DecimalInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _DecimalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final currentValue = double.tryParse(_controller.text) ?? 0.0;
      if ((currentValue - widget.value).abs() > 0.01) {
        _controller.text = widget.value.toStringAsFixed(1);
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    widget.onChanged(double.parse((widget.value + 0.1).toStringAsFixed(1)));
  }

  void _decrement() {
    if (widget.value > 0) {
      final newVal = widget.value - 0.1;
      widget.onChanged(double.parse((newVal < 0 ? 0.0 : newVal).toStringAsFixed(1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF1F5F9);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.value > 0 ? _decrement : null,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.remove, color: widget.value > 0 ? widget.accentColor : Colors.grey.shade400),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 5),
                isDense: true,
              ),
              onChanged: (val) {
                if (val.isEmpty) {
                  widget.onChanged(0.0);
                  return;
                }
                final normalizedVal = val.replaceAll(',', '.');
                final doubleVal = double.tryParse(normalizedVal);
                if (doubleVal != null) {
                  widget.onChanged(doubleVal);
                }
              },
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _increment,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add, color: widget.accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
