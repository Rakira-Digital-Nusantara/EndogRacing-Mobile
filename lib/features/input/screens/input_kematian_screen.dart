import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/kandang_header_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';

class InputKematianScreen extends StatefulWidget {
  const InputKematianScreen({super.key});

  @override
  State<InputKematianScreen> createState() => _InputKematianScreenState();
}

class _InputKematianScreenState extends State<InputKematianScreen> {
  int _jumlahAyam = 0;
  int _populasiAwal = 0;
  String _kategori = 'Mati'; // 'Mati' or 'Afkir'
  final TextEditingController _penyebabController = TextEditingController();
  String? _selectedPenyakitCode;
  List<Map<String, dynamic>> _penyakitList = [];
  bool _isLoadingPenyakit = false;

  bool _isLoading = false;
  bool _isLoadingForm = false;
  String _formError = '';

  bool get _isLainnyaSelected {
    if (_selectedPenyakitCode == null) return false;
    final selectedItem = _penyakitList.firstWhere(
      (p) => p['penyakit_code']?.toString() == _selectedPenyakitCode,
      orElse: () => <String, dynamic>{},
    );
    final nama = selectedItem['penyakit_nama']?.toString().toLowerCase() ?? '';
    return nama == 'lainnya' || _selectedPenyakitCode?.toLowerCase() == 'lainnya';
  }

  @override
  void initState() {
    super.initState();
    _fetchPopulasi();
  }

  Future<void> _fetchPopulasi() async {
    setState(() {
      _isLoadingForm = true;
      _formError = '';
    });

    final kandangCode =
        context.read<AuthProvider>().kandang?.kdgCode ?? "KDG-001";
    try {
      final response = await DioClient().dio.get(
        '/populasi/form?kdg_code=$kandangCode',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          if (data.containsKey('populasi_sebelumnya')) {
            _populasiAwal =
                int.tryParse(data['populasi_sebelumnya'].toString()) ?? 0;
          }
          if (data.containsKey('list_penyakit') && data['list_penyakit'] is List) {
            final list = data['list_penyakit'] as List;
            _penyakitList = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil populasi: $e');
      _formError = 'Gagal memuat form data populasi';
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _saveData() async {
    final kandang = context.read<AuthProvider>().kandang;
    if (kandang == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kandang tidak ditemukan')));
      return;
    }

    if (_jumlahAyam <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah ayam tidak boleh 0')),
      );
      return;
    }

    if (_kategori == 'Mati' && _selectedPenyakitCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih penyebab penyakit!')));
      return;
    }

    if (_kategori == 'Mati' && _isLainnyaSelected && _penyebabController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi penyebab kematian lainnya!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        "kdg_code": kandang.kdgCode,
        "gudang_code": "GDG0001",
        "tanggal": DateTime.now().toIso8601String().split('T')[0],
        "details": [
          {
            "sku_product": _kategori == 'Afkir' ? "990001" : "990002",
            "kategori": _kategori,
            "qty_ekor": _jumlahAyam,
            "penyakit_code": _kategori == 'Mati' 
                ? (_isLainnyaSelected ? "" : _selectedPenyakitCode) 
                : null,
            "penyebab": _kategori == 'Mati' 
                ? (_isLainnyaSelected ? null : _selectedPenyakitCode) 
                : null,
            if (_kategori == 'Mati' && _isLainnyaSelected)
              "penyebab_lainnya": _penyebabController.text,
            "catatan": "",
          },
        ],
      };

      final response = await DioClient().dio.post('/populasi', data: payload);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: _kategori == 'Afkir'
                ? 'Data Afkir Tersimpan'
                : 'Data Kematian Tersimpan',
            subtitle: _kategori == 'Afkir'
                ? 'Pengurangan populasi afkir telah dicatat.'
                : 'Pengurangan populasi kematian telah dicatat.',
            time:
                '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
            primaryButtonText: 'Kembali ke Input',
            onPrimaryPressed: () {
              Navigator.pop(context); // Tutup dialog
              context.pop(); // Kembali
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
      setState(() => _isLoading = false);
      String errorMessage = 'Terjadi kesalahan koneksi';
      if (e.response != null && e.response?.data != null) {
        errorMessage = 'Response Backend:\n${e.response?.data.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _penyebabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kandangName =
        context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';
    final populasiAktual = _populasiAwal - _jumlahAyam;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Update Populasi', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoadingForm
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _formError.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_formError, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPopulasi,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KandangHeaderCard(
                    kandangName: kandangName,
                    subtitleText: 'Update populasi harian ayam',
                    icon: Icons.cottage_outlined,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF166534), width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KALKULASI POPULASI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sebelumnya',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_populasiAwal',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'JetBrainsMono',
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Berkurang',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_jumlahAyam',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                    fontFamily: 'JetBrainsMono',
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              '=',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Aktual',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$populasiAktual',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF166534),
                                      fontFamily: 'JetBrainsMono',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 54,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Slate 100
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _kategori = 'Mati'),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _kategori == 'Mati' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _kategori == 'Mati' ? [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                      ] : [],
                                    ),
                                    child: Text(
                                      'Mati',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _kategori == 'Mati' ? const Color(0xFF166534) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _kategori = 'Afkir'),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _kategori == 'Afkir' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _kategori == 'Afkir' ? [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                      ] : [],
                                    ),
                                    child: Text(
                                      'Afkir',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _kategori == 'Afkir' ? const Color(0xFF166534) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Jumlah Ayam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _IntegerInput(
                          value: _jumlahAyam,
                          accentColor: _kategori == 'Afkir'
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626),
                          bgColor: const Color(0xFFF1F5F9),
                          onChanged: (val) {
                            setState(() {
                              if (val <= _populasiAwal) {
                                _jumlahAyam = val;
                              } else {
                                _jumlahAyam = _populasiAwal;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        if (_kategori == 'Mati') ...[
                          const Text('Penyebab', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          _isLoadingPenyakit
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: _selectedPenyakitCode,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  hint: const Text('Pilih Penyakit...'),
                                  items: _penyakitList.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p['penyakit_code']?.toString() ?? '',
                                      child: Text(p['penyakit_nama']?.toString() ?? p['penyakit_code']?.toString() ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedPenyakitCode = val;
                                      if (!_isLainnyaSelected) {
                                        _penyebabController.clear();
                                      }
                                    });
                                  },
                                ),
                          if (_isLainnyaSelected) ...[
                            const SizedBox(height: 16),
                            const Text('Sebutkan Penyebab Lainnya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _penyebabController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                hintText: 'Contoh: Terjepit, dll',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    onPressed: _saveData,
                    isLoading: _isLoading,
                    text: 'Simpan Data',
                    trailingIcon: Icons.check_circle,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF166534),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// WIDGET INPUT INTEGER (JUMLAH KEMATIAN / AFKIR)
// ============================================================================
class _IntegerInput extends StatefulWidget {
  final int value;
  final Function(int) onChanged;
  final Color accentColor;
  final Color? bgColor;

  const _IntegerInput({
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.bgColor,
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
    final bg = widget.bgColor ?? const Color(0xFFF1F5F9); // Light slate/grey

    return Container(
      height: 56, // Slightly taller to match screenshot look
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
              onTap: widget.value > 0
                  ? () => widget.onChanged(widget.value - 1)
                  : null,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.remove,
                  color: widget.value > 0
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'monospace',
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
                width: 56,
                height: 56,
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
