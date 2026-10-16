import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/dashboard_provider.dart';
import '../data/models/setor_telur_model.dart';
import '../data/repositories/kandang_telur_repository.dart';
import '../providers/kandang_telur_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/kandang_header_card.dart';

class SetorKasScreen extends StatefulWidget {
  const SetorKasScreen({super.key});

  @override
  State<SetorKasScreen> createState() => _SetorKasScreenState();
}

class _SetorKasScreenState extends State<SetorKasScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSubmitting = false;

  SetorTelurFormResponse? _formData;
  String? _selectedGudangCode;
  DateTime _tanggalSetor = DateTime.now();
  final TextEditingController _catatanController = TextEditingController();

  // Map SKU -> Jumlah Kas yang akan disetor
  final Map<String, int> _qtyKasMap = {};

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final kdgCode = context.read<AuthProvider>().kandang?.kdgCode ?? 'KDG-001';

    try {
      final repo = context.read<KandangTelurRepository>();
      final result = await repo.getSetorTelurForm(kdgCode);

      setState(() {
        _formData = result;

        // Auto pilih gudang default (Gudang Pusat / GDG0001)
        _selectedGudangCode = result.defaultGudangCode.isNotEmpty
            ? result.defaultGudangCode
            : (result.daftarGudang.isNotEmpty ? result.daftarGudang.first.gudangCode : 'GDG0001');

        // Set default nilai setor kas = 0 agar pengguna menentukan sendiri jumlah kas yang ingin disetor
        for (var item in result.saldoKandang) {
          _qtyKasMap[item.skuProduct] = 0;
        }
      });
    } catch (e) {
      String msg = 'Gagal memuat form setor telur';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalKasDipilih {
    int sum = 0;
    for (var val in _qtyKasMap.values) {
      sum += val;
    }
    return sum;
  }

  double get _totalKgDipilih => _totalKasDipilih * 15.0;

  Future<void> _submitSetor() async {
    if (_totalKasDipilih <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah kas yang disetor harus lebih dari 0!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGudangCode == null || _selectedGudangCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gudang tujuan terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final kdgCode = context.read<AuthProvider>().kandang?.kdgCode ?? 'KDG-001';

    // Buat items payload
    final List<Map<String, dynamic>> items = [];
    if (_formData != null) {
      for (var saldo in _formData!.saldoKandang) {
        final kas = _qtyKasMap[saldo.skuProduct] ?? 0;
        if (kas > 0) {
          items.add({
            'sku_product': saldo.skuProduct,
            'kategori': saldo.kategori,
            'qty_kas': kas,
            'catatan': '$kas Kas utuh @ 15 Kg',
          });
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = context.read<KandangTelurRepository>();
      final result = await repo.submitSetorTelur(
        kdgCode: kdgCode,
        gudangCode: _selectedGudangCode!,
        tanggal: _tanggalSetor.toIso8601String().split('T')[0],
        catatan: _catatanController.text.trim(),
        items: items,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Refresh saldo kandang, setor dashboard & dashboard metrik
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      context.read<KandangTelurProvider>().fetchSaldoKandang(kdgCode);
      context.read<KandangTelurProvider>().fetchDashboardSetor(kdgCode, startDate: todayStr, endDate: todayStr);
      context.read<DashboardProvider>().fetchDashboardData(kdgCode);

      // Navigasi langsung ke Layar 4: Bukti Surat Jalan Digital
      context.pushReplacement('/setor-telur-detail', extra: result);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      String errMsg = 'Gagal memproses setoran kas';

      if (responseData is Map) {
        if (responseData.containsKey('errors') && responseData['errors'] != null) {
          final errs = responseData['errors'];
          if (errs is Map) {
            errMsg = errs.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
          } else if (errs is List) {
            errMsg = errs.join('\n');
          } else {
            errMsg = errs.toString();
          }
        } else if (responseData.containsKey('message')) {
          errMsg = responseData['message'].toString();
        }
      }

      // Penanganan khusus sesuai spesifikasi Bab 4
      if (statusCode == 403) {
        // Belum Absen Masuk
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Belum Absen'),
              ],
            ),
            content: Text(
              errMsg.contains('Absen')
                  ? errMsg
                  : 'Anda belum melakukan Absen Masuk hari ini. Harap absen terlebih dahulu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.push('/absensi');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Ke Layar Absensi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final kandangName = _formData?.kdgNama ??
        context.watch<AuthProvider>().kandang?.kdgNama ??
        'Kandang';

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
          'Setor Kas ke Gudang',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF475569)),
            tooltip: 'Riwayat Setoran',
            onPressed: () => context.push('/riwayat-setor-telur'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadForm, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. KANDANG HEADER CARD (Standar konsisten seluruh halaman input)
                      KandangHeaderCard(
                        kandangName: kandangName,
                        subtitleText: 'Pengiriman Kas Telur ke Gudang',
                        icon: Icons.cottage_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 2. TANGGAL SETOR PICKER (Standar format input tanggal)
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggalSetor,
                            firstDate: DateTime(2025),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            setState(() => _tanggalSetor = picked);
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
                              const Text('Tanggal Setor:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              Text(
                                '${_tanggalSetor.day}/${_tanggalSetor.month}/${_tanggalSetor.year}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. DAFTAR TELUR & INPUT KAS
                      if (_formData?.saldoKandang.isEmpty ?? true)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text(
                                  'Tidak ada stok telur di kandang saat ini.',
                                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...(_formData!.saldoKandang.map((saldo) {
                          final int currentKas = _qtyKasMap[saldo.skuProduct] ?? 0;
                          final double kgEkuivalen = currentKas * 15.0;
                          final double sisaTinggal = (saldo.saldoKg - kgEkuivalen) < 0 ? 0.0 : (saldo.saldoKg - kgEkuivalen);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                // Header Kartu: Nama Produk & Stok di Kandang
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF7ED),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.egg_rounded, color: Color(0xFFEA580C), size: 22),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  saldo.skuName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Stok di Kandang: ${saldo.saldoKg.toStringAsFixed(1)} Kg',
                                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: saldo.kasTersedia > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        saldo.kasTersedia > 0 ? '${saldo.kasTersedia} Kas Tersedia' : 'Belum Cukup 1 Kas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: saldo.kasTersedia > 0 ? const Color(0xFF166534) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                                ),

                                if (saldo.kasTersedia == 0)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Stok telur ${saldo.saldoKg.toStringAsFixed(1)} Kg belum mencapai 15.0 Kg untuk 1 Kas. Telur tetap disimpan di kandang.',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  // Stepper Kas Input (Format Konsisten _IntegerInput)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Jumlah Kas yang Disetor',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2F6),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'MAKS ${saldo.kasTersedia} KAS',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _KasIntegerInput(
                                    value: currentKas,
                                    max: saldo.kasTersedia,
                                    onChanged: (val) {
                                      setState(() {
                                        _qtyKasMap[saldo.skuProduct] = val;
                                      });
                                    },
                                    accentColor: const Color(0xFF166534),
                                  ),

                                  const SizedBox(height: 16),

                                  // LIVE PREVIEW KALKULASI PENGIRIMAN (Amber/Warm Card seperti input_produksi)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.calculate_outlined, color: Color(0xFFD97706), size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Kalkulasi Pengiriman',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Expanded(
                                              child: Text('Akan Dikirim ke Gudang:', style: TextStyle(fontSize: 12.5, color: Color(0xFF78350F))),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$currentKas Kas (${kgEkuivalen.toStringAsFixed(1)} Kg)',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Expanded(
                                              child: Text('Sisa Mengendap di Kandang:', style: TextStyle(fontSize: 12.5, color: Color(0xFF78350F))),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${sisaTinggal.toStringAsFixed(1)} Kg',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        })),

                      // 5. CATATAN PENGIRIMAN (Format Kartu Input Standar)
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
                            const Text(
                              'Catatan Pengiriman (Opsional)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _catatanController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Misal: Setoran panen pagi atau catatan untuk gudang',
                                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      bottomNavigationBar: _isLoading || _errorMessage.isNotEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Pengiriman:',
                            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalKasDipilih Kas (${_totalKgDipilih.toStringAsFixed(1)} Kg)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: _totalKasDipilih > 0
                          ? 'Konfirmasi & Setor Kas'
                          : 'Pilih Kas yang Akan Disetor',
                      isLoading: _isSubmitting,
                      onPressed: (_isSubmitting || _totalKasDipilih <= 0) ? null : _submitSetor,
                      trailingIcon: Icons.local_shipping_rounded,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// WIDGET INPUT INTEGER KAS (Sesuai Konsep Desain Standar Halaman Input)
// ============================================================================
class _KasIntegerInput extends StatefulWidget {
  final int value;
  final int max;
  final Function(int) onChanged;
  final Color accentColor;

  const _KasIntegerInput({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<_KasIntegerInput> createState() => _KasIntegerInputState();
}

class _KasIntegerInputState extends State<_KasIntegerInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _KasIntegerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF1F5F9);

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
                  if (intVal > widget.max) {
                    widget.onChanged(widget.max);
                    _controller.text = widget.max.toString();
                  } else if (intVal < 0) {
                    widget.onChanged(0);
                    _controller.text = '0';
                  } else {
                    widget.onChanged(intVal);
                  }
                }
              },
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.value < widget.max ? () => widget.onChanged(widget.value + 1) : null,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add, color: widget.value < widget.max ? widget.accentColor : Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
