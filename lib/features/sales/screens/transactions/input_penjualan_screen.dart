import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';


class InputPenjualanScreen extends StatefulWidget {
  const InputPenjualanScreen({super.key});

  @override
  State<InputPenjualanScreen> createState() => _InputPenjualanScreenState();
}

class _InputPenjualanScreenState extends State<InputPenjualanScreen> {
  String? _selectedCustomerCode;
  String? _selectedProductSku;
  Map<String, dynamic>? _selectedProductMap;

  double _qty = 0;

  String _paymentMethod = 'Lunas';
  final List<String> _paymentMethods = ['Lunas', 'Sebagian', 'Belum Bayar'];
  final _uangDiterimaCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  DateTime? _jatuhTempoDate;

  @override
  void dispose() {
    _uangDiterimaCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchPenjualanForm();
    });
  }

  Map<String, dynamic>? get _selectedCustomerMap {
    if (_selectedCustomerCode == null) return null;
    final provider = context.read<SalesProvider>();
    try {
      return provider.customers.firstWhere(
        (c) => (c['code'] ?? c['customer_code']) == _selectedCustomerCode,
      );
    } catch (_) {
      return null;
    }
  }

  bool get _isNettingPartner {
    final c = _selectedCustomerMap;
    if (c == null) return false;
    return c['is_netting_partner'] == true ||
        c['is_netting_partner'] == 1 ||
        c['is_netting_partner']?.toString() == 'true';
  }

  void _onCustomerChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedCustomerCode = val;
      // If selected customer is a netting partner, auto-lock payment method to Belum Bayar
      if (_isNettingPartner) {
        _paymentMethod = 'Belum Bayar';
        _uangDiterimaCtrl.text = '0';
        _jatuhTempoDate ??= DateTime.now().add(const Duration(days: 7));
      }
    });
  }

  void _onProductChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedProductSku = val;
      final provider = context.read<SalesProvider>();
      try {
        _selectedProductMap = provider.products.firstWhere(
          (p) => p['sku'] == val,
        );
      } catch (_) {
        _selectedProductMap = null;
      }
    });
  }

  void _updateUangDiterima() {
    if (_isNettingPartner || _paymentMethod == 'Belum Bayar') {
      _uangDiterimaCtrl.text = '0';
    } else if (_paymentMethod == 'Lunas') {
      _uangDiterimaCtrl.text = _calculatedTotal.toStringAsFixed(0);
    } else if (_paymentMethod == 'Sebagian') {
      if (_uangDiterimaCtrl.text.isEmpty ||
          _uangDiterimaCtrl.text == '0' ||
          _uangDiterimaCtrl.text == _calculatedTotal.toStringAsFixed(0)) {
        _uangDiterimaCtrl.text = ''; // Kosongkan agar diisi manual
      }
    }
  }

  double get _calculatedTotal {
    if (_selectedProductMap == null) return 0;
    final price = double.tryParse(_selectedProductMap!['hpp']?.toString() ?? '0') ?? 0;
    return price * _qty;
  }

  bool get _canSubmit {
    if (_selectedCustomerCode == null ||
        _selectedProductSku == null ||
        _selectedProductMap == null) {
      return false;
    }
    if (_qty <= 0) return false;
    return true;
  }

  void _showMitraNettingDialog(String errorMsg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.handshake_rounded, color: Colors.amber.shade900, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mitra Netting Kantor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                errorMsg.isNotEmpty
                    ? errorMsg.replaceAll(RegExp(r'[\{\}\[\]]'), '')
                    : 'Pelanggan ini adalah Mitra Netting Kantor. Pembayaran invoice tidak diserahkan tunai ke sales, melainkan diselesaikan melalui pemotongan tagihan pakan oleh admin kantor.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber.shade900,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Opsi pembayaran wajib diatur ke "Belum Bayar" (Tempo) dengan nominal dibayar Rp 0.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _paymentMethod = 'Belum Bayar';
                  _uangDiterimaCtrl.text = '0';
                  _jatuhTempoDate ??= DateTime.now().add(const Duration(days: 7));
                });
              },
              child: const Text('Atur ke Belum Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_canSubmit) return;

    // Mitra netting enforcement
    if (_isNettingPartner) {
      _paymentMethod = 'Belum Bayar';
      _uangDiterimaCtrl.text = '0';
      _jatuhTempoDate ??= DateTime.now().add(const Duration(days: 7));
    }

    if ((_paymentMethod == 'Sebagian' || _paymentMethod == 'Belum Bayar') && _jatuhTempoDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Tanggal Jatuh Tempo terlebih dahulu'), backgroundColor: Colors.red),
      );
      return;
    }

    final double uangDiterima = _isNettingPartner 
        ? 0.0 
        : (double.tryParse(_uangDiterimaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0);

    if (!_isNettingPartner && _paymentMethod == 'Sebagian' && uangDiterima <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal Dibayar harus lebih dari 0'), backgroundColor: Colors.red),
      );
      return;
    }

    final payload = {
      'customer_code': _selectedCustomerCode,
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      'opsi_bayar': _isNettingPartner ? 'Belum Bayar' : _paymentMethod,
      'nominal_dibayar': uangDiterima,
      if ((_paymentMethod == 'Sebagian' || _paymentMethod == 'Belum Bayar' || _isNettingPartner) && _jatuhTempoDate != null)
        'tgl_jatuh_tempo': _jatuhTempoDate!.toIso8601String().split('T')[0],
      'catatan': _keteranganCtrl.text,
      'details_jual': [
        {
          'sku_product': _selectedProductSku,
          'qty': _qty,
          'harga_satuan': double.tryParse(_selectedProductMap?['hpp']?.toString() ?? '0') ?? 0,
        },
      ],
    };

    final provider = context.read<SalesProvider>();
    final success = await provider.submitPenjualan(payload);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Penjualan berhasil dicatat!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      if (provider.errorCode == 'MITRA_NETTING' ||
          provider.error.toLowerCase().contains('mitra netting') ||
          provider.error.contains('MITRA_NETTING')) {
        _showMitraNettingDialog(provider.error);
        return;
      }

      final err = provider.error;
      final cleanErr = err.replaceAll(RegExp(r'[\{\}\[\]]'), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(cleanErr)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();

    final seenCustomerCodes = <String>{};
    final customerItems = <DropdownMenuItem<String>>[];
    for (final c in sales.customers) {
      final code = (c['code'] ?? c['customer_code'])?.toString() ?? '';
      if (code.isNotEmpty && !seenCustomerCodes.contains(code)) {
        seenCustomerCodes.add(code);
        final name = c['name']?.toString() ?? c['customer_name']?.toString() ?? code;
        final isNetting = c['is_netting_partner'] == true ||
            c['is_netting_partner'] == 1 ||
            c['is_netting_partner']?.toString() == 'true';
        customerItems.add(
          DropdownMenuItem<String>(
            value: code,
            child: Text.rich(
              TextSpan(
                text: name,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                children: [
                  if (isNetting)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade600, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label_outline_rounded, size: 11, color: Colors.amber.shade900),
                            const SizedBox(width: 3),
                            Text(
                              'Mitra Netting',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    final effectiveCustomerCode = seenCustomerCodes.contains(_selectedCustomerCode)
        ? _selectedCustomerCode
        : null;

    final seenProductSkus = <String>{};
    final productItems = <DropdownMenuItem<String>>[];
    for (final p in sales.products) {
      final sku = (p['sku'] ?? p['sku_product'])?.toString() ?? '';
      if (sku.isNotEmpty && !seenProductSkus.contains(sku)) {
        seenProductSkus.add(sku);
        final name = p['name']?.toString() ?? p['sku_name']?.toString() ?? sku;
        productItems.add(
          DropdownMenuItem<String>(
            value: sku,
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    final effectiveProductSku = seenProductSkus.contains(_selectedProductSku)
        ? _selectedProductSku
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        actions: const [],
        title: const Text(
          'Tambah Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: sales.isLoading && sales.customers.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : sales.customers.isEmpty && sales.error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          sales.error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<SalesProvider>().fetchPenjualanForm(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox.expand(
                  child: Stack(
                    children: [
                  // Header Background Gradient
                  Container(
                    width: double.infinity,
                    height: 140, // Added fixed height
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.point_of_sale_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catat Penjualan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Catat transaksi penjualan harian Anda',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Positioned.fill(
                    top: 90, // Start scrolling over the header
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // 1. Kustomer
                            _buildInputLabel('Kustomer Tujuan', true),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                'Pilih Kustomer',
                                Icons.person_outline_rounded,
                              ),
                              initialValue: effectiveCustomerCode,
                              items: customerItems,
                              onChanged: _onCustomerChanged,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_isNettingPartner) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.amber.shade800,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '⚠️ PERHATIAN: Toko ini adalah Mitra Netting Kantor',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pembayaran invoice ini tidak diserahkan ke sales, melainkan diselesaikan melalui pemotongan/kompensasi tagihan pakan oleh admin kantor.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.35,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // 2. Produk
                            _buildInputLabel('Produk', true),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                'Pilih Produk',
                                Icons.egg_alt_rounded,
                              ),
                              initialValue: effectiveProductSku,
                              items: productItems,
                              onChanged: _onProductChanged,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 3. Jumlah (Qty)
                            _buildInputLabel(
                              'Jumlah Terjual (${_selectedProductMap?['uom'] ?? 'Kg'})',
                              true,
                            ),
                            TextFormField(
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                              decoration: _buildInputDecoration(
                                '0.00',
                                Icons.monitor_weight_rounded,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _qty = double.tryParse(val) ?? 0;
                                  _updateUangDiterima();
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            // 4. Total Tagihan
                            if (_selectedProductMap != null && _qty > 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Tagihan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text(
                                      CurrencyFormatter.format(_calculatedTotal),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),

                            // 5. Status Pembayaran
                            _buildInputLabel('Status Pembayaran', true),
                            if (_isNettingPartner) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Belum Bayar (Tempo)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Terkunci: Kompensasi netting admin kantor',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade400, width: 0.8),
                                      ),
                                      child: Text(
                                        'LOCKED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ] else ...[
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: _buildInputDecoration(
                                  'Pilih Status Pembayaran',
                                  Icons.payment_rounded,
                                ),
                                initialValue: _paymentMethod,
                                items: _paymentMethods.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(
                                      m,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _paymentMethod = val;
                                      _updateUangDiterima();
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            if (_paymentMethod == 'Sebagian' || _paymentMethod == 'Belum Bayar') ...[
                              _buildInputLabel('Jatuh Tempo', true),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => _jatuhTempoDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _jatuhTempoDate == null 
                                            ? 'Pilih Tanggal Jatuh Tempo' 
                                            : '${_jatuhTempoDate!.day.toString().padLeft(2, '0')}/${_jatuhTempoDate!.month.toString().padLeft(2, '0')}/${_jatuhTempoDate!.year}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _jatuhTempoDate == null ? AppColors.textHint : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 6. Uang Diterima (Hanya untuk Sebagian)
                            if (_paymentMethod == 'Sebagian') ...[
                              _buildInputLabel('Nominal Dibayar (Rp)', true),
                              TextField(
                                controller: _uangDiterimaCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                                decoration: _buildInputDecoration(
                                  '0',
                                  Icons.attach_money_rounded,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 7. Keterangan
                            _buildInputLabel('Keterangan (Opsional)', false),
                            TextField(
                              controller: _keteranganCtrl,
                              decoration: _buildInputDecoration(
                                'Tambahkan catatan...',
                                Icons.notes_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isNettingPartner
                                    ? Colors.amber.withValues(alpha: 0.12)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isNettingPartner ? Icons.handshake_rounded : Icons.info_outline_rounded,
                                    color: _isNettingPartner ? Colors.amber.shade900 : Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isNettingPartner
                                          ? 'Kustomer ini adalah Mitra Netting. Opsi pembayaran otomatis Belum Bayar dan tidak menerima uang tunai.'
                                          : 'Pilih metode pembayaran (Tunai, Transfer, Tempo). Jika Tempo, uang diterima dapat 0 dan wajib isi Jatuh Tempo.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _isNettingPartner ? Colors.amber.shade900 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
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
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canSubmit && !sales.isLoading ? _submitForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: sales.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Simpan Penjualan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: Icon(icon, color: AppColors.primary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
