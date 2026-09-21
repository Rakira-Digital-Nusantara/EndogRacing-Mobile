import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/shared/widgets/success_screen.dart';

class LaporPecahMobilScreen extends StatefulWidget {
  const LaporPecahMobilScreen({super.key});

  @override
  State<LaporPecahMobilScreen> createState() => _LaporPecahMobilScreenState();
}

class _LaporPecahMobilScreenState extends State<LaporPecahMobilScreen> {
  final _formKey = GlobalKey<FormState>();
  double _qtyRusak = 0;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    FocusScope.of(context).unfocus();

    if (_qtyRusak <= 0) return;

    setState(() => _isLoading = true);
    
    final payload = {
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      'qty_rusak': _qtyRusak,
    };

    final sales = context.read<SalesProvider>();
    final result = await sales.submitLaporPecahMobil(payload);
    
    setState(() => _isLoading = false);

    if (result && mounted) {
      showDialog(
        context: context,
        builder: (context) => SuccessDialog(
          title: 'Lapor Pecah Berhasil',
          subtitle: 'Stok Telur Utuh di mobil telah dikurangi dan Telur Rusak telah ditambahkan.',
          time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
          primaryButtonText: 'Selesai',
          onPrimaryPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sales.error), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lapor Telur Pecah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Header Background Gradient
              Container(
                width: double.infinity,
                height: 140,
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.egg_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lapor Pecah di Mobil',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Catat telur yang pecah/rusak selama di perjalanan.',
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                bottom: 0,
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Pecah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Input Qty
                          const Text('Kuantitas (Kg)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Contoh: 1.5',
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.scale_rounded, color: Colors.orange),
                              suffixText: 'Kg',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Kuantitas harus diisi';
                              final qty = double.tryParse(value);
                              if (qty == null || qty <= 0) return 'Kuantitas tidak valid';
                              return null;
                            },
                            onSaved: (value) {
                              _qtyRusak = double.tryParse(value ?? '0') ?? 0;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Simpan Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
