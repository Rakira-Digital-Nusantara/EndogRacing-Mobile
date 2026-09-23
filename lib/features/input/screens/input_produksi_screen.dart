import 'package:flutter/foundation.dart';
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

  int _populasi = 0;
  String _gudangCode = 'GDG0001';

  // Tab State
  int _selectedTabIndex = 0; // 0 = Utuh, 1 = Rusak

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
            if (innerData.containsKey('populasi_ayam_saat_ini')) {
              setState(() {
                _populasi = int.tryParse(innerData['populasi_ayam_saat_ini'].toString()) ?? 0;
              });
            }
            if (innerData.containsKey('gudang_code')) {
              _gudangCode = innerData['gudang_code']?.toString() ?? 'GDG0001';
            }
            if (innerData.containsKey('items')) {
              // Extract SKU automatically based on name
              final List items = innerData['items'];
              for (var item in items) {
                final sku = item['sku_product']?.toString() ?? '';
                final name = item['sku_name']?.toString().toLowerCase() ?? '';
                if (name.contains('utuh')) {
                  _skuUtuh = sku;
                } else if (name.contains('rusak') || name.contains('bentes') || name.contains('retak') || name.contains('afkir')) {
                  _skuRusak = sku;
                }
              }
              // If we couldn't find them, default to the first two, or log them
              if (_skuUtuh.isEmpty && items.isNotEmpty) {
                _skuUtuh = items[0]['sku_product']?.toString() ?? '1500123';
              } else if (_skuUtuh.isEmpty) {
                _skuUtuh = '1500123';
              }
              if (_skuRusak.isEmpty && items.length > 1) {
                _skuRusak = items[1]['sku_product']?.toString() ?? '100001';
              } else if (_skuRusak.isEmpty) {
                _skuRusak = '100001';
              }
            } else {
               _skuUtuh = '1500123';
               _skuRusak = '100001';
               debugPrint("API TIDAK MENGEMBALIKAN ITEMS: $innerData");
            }
          }
        }
      }
    } catch (e) {
      String errMsg = 'Gagal memuat form produksi';
      if (e is DioException) {
        errMsg = e.response?.data?.toString() ?? e.message ?? errMsg;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi Qty minimal pada salah satu telur!')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    final kandangCode = context.read<AuthProvider>().kandang?.kdgCode ?? "KDG-001";

    final payload = {
      "kdg_code": kandangCode,
      "gudang_code": _gudangCode,
      "tanggal": DateTime.now().toIso8601String().split('T')[0],
      "details": details,
    };

    try {
      final response = await DioClient().dio.post('/produksi-telur', data: payload);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Produksi Tersimpan',
            subtitle: 'Data produksi telur telah berhasil dicatat.',
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
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
          if (data.containsKey('errors')) {
            errorMessage += '\n${data['errors']}';
          }
        } else {
          errorMessage = 'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 10))
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan tidak terduga: $e'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';

    // Hitung persentase
    double produktivitas = 0.0;
    double rusak = 0.0;

    if (_populasi > 0) {
      produktivitas = ((_qtyUtuhButir + _qtyRusakButir) / _populasi) * 100;
      rusak = (_qtyRusakButir / _populasi) * 100;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FDF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Input Produksi Harian', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
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
                    subtitleText: 'Update harian produksi telur',
                    icon: Icons.cottage_outlined,
                  ),
                  const SizedBox(height: 24),

                  // CARD PERSENTASE
                  Row(
                    children: [
                      // Produktivitas Card
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
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, color: Color(0xFF166534), size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Produktivitas',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    produktivitas.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '%',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Rusak Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5), // Light red bg
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
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    rusak.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '%',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TAB BAR TOGGLE (Utuh / Rusak)
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
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTabIndex == 0 ? [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ] : [],
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
                                boxShadow: _selectedTabIndex == 1 ? [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ] : [],
                              ),
                              child: Text(
                                'Telur Rusak',
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
                  const SizedBox(height: 24),

                  // INPUT FORM CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                              child: const Text('PCS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
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

                        // Berat Utuh Input
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTabIndex == 0 ? 'Berat Utuh' : 'Berat Rusak', 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _isLoadingForm || _formError.isNotEmpty ? null : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            child: AppButton(
              onPressed: _submitProduksi,
              isLoading: _isSubmitting,
              text: 'Simpan Data',
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
            TextPosition(offset: _controller.text.length));
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
            TextPosition(offset: _controller.text.length));
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
