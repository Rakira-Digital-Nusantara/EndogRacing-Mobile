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

class InputOvkScreen extends StatefulWidget {
  const InputOvkScreen({super.key});

  @override
  State<InputOvkScreen> createState() => _InputOvkScreenState();
}

class _InputOvkScreenState extends State<InputOvkScreen> {
  bool _isLoadingForm = false;
  String _formError = '';
  bool _isSubmitting = false;

  // Data Dropdown
  List<dynamic> _ovkItems = [];

  // State
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _inputRows = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi 1 baris input default
    _inputRows.add({
      'sku_product': null,
      'qty_pakai': 0.0,
      'controller': TextEditingController(text: '0'),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFormData();
    });
  }

  @override
  void dispose() {
    for (var row in _inputRows) {
      if (row['controller'] is TextEditingController) {
        (row['controller'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  Future<void> _fetchFormData() async {
    setState(() {
      _isLoadingForm = true;
      _formError = '';
    });

    try {
      final response = await DioClient().dio.get('/pemakaian-ovk/form?gudang_code=GDG-001');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map && data.containsKey('items')) {
          setState(() {
            _ovkItems = data['items'] as List<dynamic>;
          });
        } else if (data is List) {
           setState(() {
            _ovkItems = data;
          });
        }
      }
    } catch (e) {
      setState(() {
        _formError = 'Gagal memuat daftar Obat/Vaksin.\nPastikan koneksi internet stabil.';
      });
      // Fallback data for testing if backend fails
      setState(() {
         _ovkItems = [
            {"sku_product": "OBT-001", "sku_name": "Vitamin Ayam 1L"},
            {"sku_product": "VKS-001", "sku_name": "Vaksin ND Clone"},
         ];
      });
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addRow() {
    setState(() {
      _inputRows.add({
        'sku_product': null,
        'qty_pakai': 0.0,
        'controller': TextEditingController(text: '0'),
      });
    });
  }

  void _removeRow(int index) {
    setState(() {
      final controller = _inputRows[index]['controller'] as TextEditingController;
      controller.dispose();
      _inputRows.removeAt(index);
    });
  }

  Future<void> _submitData() async {
    // Validasi
    final validRows = _inputRows.where((row) => row['sku_product'] != null && (row['qty_pakai'] as double) > 0).toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi setidaknya 1 pemakaian Obat/Vaksin dengan Qty > 0'), backgroundColor: Colors.red),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final kdgCode = auth.kandang?.kdgCode ?? 'KDG-001';

    final payload = {
      "gudang_code": "GDG-001",
      "kdg_code": kdgCode,
      "tanggal": "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
      "details": validRows.map((row) => {
        "sku_product": row['sku_product'],
        "qty_pakai": row['qty_pakai']
      }).toList()
    };

    setState(() => _isSubmitting = true);

    try {
      final response = await DioClient().dio.post('/pemakaian-ovk', data: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              title: 'Data Berhasil Disimpan',
              subtitle: 'Pemakaian OVK untuk kandang ini berhasil diperbarui.',
              time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
              onPrimaryPressed: () {
                context.pop();
                context.pop();
              },
            ),
          );
        }
      } else {
        throw Exception('Gagal menyimpan data');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pemakaian OVK Harian', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoadingForm
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header Merah Kandang
                        KandangHeaderCard(kandangName: kandangName),
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_formError.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(_formError, style: TextStyle(color: Colors.red.shade700)),
                                ),

                              // 1. Pilih Tanggal
                              const Text('Tanggal Pemakaian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectDate(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 2. Daftar Item
                              const Text('Daftar Obat / Vaksin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 8),

                              ..._inputRows.asMap().entries.map((entry) {
                                final index = entry.key;
                                final row = entry.value;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Item #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          if (_inputRows.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                              onPressed: () => _removeRow(index),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Dropdown Produk
                                      DropdownButtonFormField<String>(
                                        value: row['sku_product'],
                                        isExpanded: true,
                                        hint: const Text('Pilih Obat / Vaksin'),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        items: _ovkItems.map<DropdownMenuItem<String>>((prod) {
                                          final sku = prod['sku_product']?.toString() ?? '';
                                          final name = prod['sku_name']?.toString() ?? '';
                                          return DropdownMenuItem<String>(
                                            value: sku,
                                            child: Text('$name ($sku)', style: const TextStyle(fontSize: 14)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            row['sku_product'] = val;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Input Qty
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _DecimalInput(
                                              value: row['qty_pakai'] as double,
                                              accentColor: AppColors.primary,
                                              onChanged: (val) {
                                                setState(() {
                                                  row['qty_pakai'] = val;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text('Satuan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),

                              // Tombol Tambah Baris
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _addRow,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Obat / Vaksin Lain', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40), // Spacing for bottom button
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Simpan
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AppButton(
                      onPressed: _submitData,
                      isLoading: _isSubmitting,
                      text: 'Simpan Data',
                      trailingIcon: Icons.check_circle,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// WIDGET INPUT DECIMAL (BERAT / QTY)
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
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
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
    const bg = Color(0xFFF1F5F9);
    
    return Container(
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
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
