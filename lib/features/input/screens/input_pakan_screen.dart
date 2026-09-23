import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/kandang_header_card.dart';
import '../../../shared/widgets/app_button.dart';

class FeedInputItem {
  double qty = 0.0;
  String? sku;
}

class InputPakanScreen extends StatefulWidget {
  const InputPakanScreen({super.key});

  @override
  State<InputPakanScreen> createState() => _InputPakanScreenState();
}

class _InputPakanScreenState extends State<InputPakanScreen> {
  bool _isLoadingForm = false;
  String _formError = '';
  bool _isSubmitting = false;

  // Data Dropdown
  List<dynamic> _pakanItems = [];

  // State Input Konsumsi Pakan
  final List<FeedInputItem> _pakanInputs = [FeedInputItem()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForm();
    });
  }

  Future<void> _fetchForm() async {
    setState(() {
      _isLoadingForm = true;
      _formError = '';
    });

    try {
      final response = await DioClient().dio.get('/pemakaian-pakan/form?gudang_code=GDG0001');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map && data.containsKey('items')) {
          setState(() {
            _pakanItems = data['items'] is List ? data['items'] : [];
          });
        }
      }
    } on DioException catch (e) {
      _formError = 'Gagal memuat form produk pakan: ${e.response?.data?['message'] ?? e.message}';
    } catch (e) {
      _formError = 'Gagal memuat form produk pakan: $e';
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _saveData() async {
    final kandang = context.read<AuthProvider>().kandang;
    if (kandang == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kandang tidak ditemukan'), backgroundColor: Colors.red));
      return;
    }

    if (_pakanInputs.every((item) => item.qty <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi minimal 1 Pakan Habis terlebih dahulu!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> details = [];
      
      for (var item in _pakanInputs) {
        if (item.qty > 0) {
          final fallbackSku = _pakanItems.isNotEmpty ? _pakanItems.first['sku_product']?.toString() : null;
          details.add({
            "sku_product": item.sku ?? fallbackSku ?? "PKN-001",
            "qty_pakai": item.qty
          });
        }
      }

      final payload = {
        "gudang_code": "GDG0001",
        "kdg_code": kandang.kdgCode,
        "tanggal": DateTime.now().toIso8601String().split('T')[0],
        "details": details,
      };

      final response = await DioClient().dio.post('/pemakaian-pakan', data: payload);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Pakan Tersimpan',
            subtitle: 'Data pakan harian telah berhasil dicatat.',
            time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
            primaryButtonText: 'Selesai',
            onPrimaryPressed: () {
              Navigator.pop(context);
              context.pop();
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Gagal menyimpan data'), backgroundColor: Colors.red)
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      String errorMessage = 'Terjadi kesalahan koneksi';
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else {
            errorMessage = 'Gagal menyimpan data';
          }
          if (data.containsKey('errors')) {
            if (data['errors'] is Map) {
              final errorValues = (data['errors'] as Map).values;
              errorMessage += '\n${errorValues.map((v) => v is List ? v.join('\n') : v.toString()).join('\n')}';
            } else {
              errorMessage += '\n${data['errors']}';
            }
          }
        } else {
          errorMessage = 'Backend Response:\n${data.toString()}';
        }
      } else {
        errorMessage = 'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
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
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 10)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FDF9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Input Pakan',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w600),
        ),
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
                  // HEADER CARD
                  KandangHeaderCard(
                    kandangName: kandangName,
                    subtitleText: 'Update harian pakan ayam petelur',
                    icon: Icons.cottage_outlined,
                  ),
                  const SizedBox(height: 24),

                  // DAFTAR KONSUMSI PAKAN
                  ..._pakanInputs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.hourglass_bottom, color: Color(0xFF166534), size: 20),
                                  const SizedBox(width: 8),
                                  Text('Konsumsi Pakan ${index + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ],
                              ),
                              if (_pakanInputs.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _pakanInputs.removeAt(index);
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Pakan Habis (Kg)', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                          const SizedBox(height: 8),
                          _DecimalInput(
                            value: item.qty,
                            onChanged: (val) => setState(() => item.qty = val),
                            accentColor: const Color(0xFF166534),
                          ),
                          const SizedBox(height: 16),
                          const Text('Jenis Pakan (Opsional)', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2EF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: item.sku,
                                hint: const Text('Pilih Jenis Pakan', style: TextStyle(color: Color(0xFF475569), fontSize: 14)),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569)),
                                items: _pakanItems.map((pakanOption) {
                                  final sku = pakanOption['sku_product']?.toString() ?? '';
                                  final name = pakanOption['sku_name']?.toString() ?? sku;
                                  return DropdownMenuItem(
                                    value: sku,
                                    child: Text(name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => item.sku = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // BUTTON TAMBAH PAKAN
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _pakanInputs.add(FeedInputItem());
                        });
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF166534)),
                      label: const Text(
                        'Tambah Input Pakan',
                        style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _isLoadingForm || _formError.isNotEmpty ? null : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                onPressed: _saveData,
                isLoading: _isSubmitting,
                text: 'Simpan Data',
                trailingIcon: Icons.check_circle,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET INPUT DECIMAL (BERAT)
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
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  String _formatValue(double val) {
    if (val == val.toInt()) return val.toInt().toString();
    return val.toString();
  }

  @override
  void didUpdateWidget(covariant _DecimalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final formatted = _formatValue(widget.value);
      if (_controller.text != formatted) {
        _controller.text = formatted;
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    widget.onChanged(widget.value + 1);
  }

  void _decrement() {
    if (widget.value > 0) {
      widget.onChanged(widget.value - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEEF2EF);
    
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bg, width: 2),
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
                final doubleVal = double.tryParse(val.replaceAll(',', '.'));
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bg, width: 2),
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
