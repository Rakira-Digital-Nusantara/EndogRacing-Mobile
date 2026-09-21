import 'package:flutter/material.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';

class DepositAgenScreen extends StatefulWidget {
  const DepositAgenScreen({super.key});

  @override
  State<DepositAgenScreen> createState() => _DepositAgenScreenState();
}

class _DepositAgenScreenState extends State<DepositAgenScreen> {
  // Dummy Data
  final List<Map<String, dynamic>> _customers = [
    {'code': 'CST-001', 'name': 'Toko Barokah', 'saldo': 1500000},
    {'code': 'CST-002', 'name': 'Agen Makmur', 'saldo': 500000},
    {'code': 'CST-003', 'name': 'Warung Budi', 'saldo': 0},
  ];

  final List<Map<String, dynamic>> _history = [
    {'tanggal': '2026-08-28', 'jenis': 'IN', 'nominal': 1000000, 'ket': 'Top Up Tunai ke Sales'},
    {'tanggal': '2026-08-29', 'jenis': 'OUT', 'nominal': 250000, 'ket': 'Pembelian Telur JUAL-001'},
  ];

  String? _selectedCustomer;
  double _saldo = 0;

  void _onCustomerChanged(String? val) {
    setState(() {
      _selectedCustomer = val;
      if (val != null) {
        final cust = _customers.firstWhere((c) => c['code'] == val);
        _saldo = (cust['saldo'] as num).toDouble();
      }
    });
  }

  void _showTopUpDialog() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih customer terlebih dahulu!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Terima Setoran Deposit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nominal Setoran (Rp)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Metode Pembayaran', border: OutlineInputBorder()),
                initialValue: 'Transfer Bank',
                enabled: false, // Wajib Transfer Bank sesuai SOP
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Keterangan (Opsional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Top up deposit berhasil dicatat! (Simulasi)'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Setoran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Top Up & Saldo Agen'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Selection
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Pilih Customer / Agen',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedCustomer,
                items: _customers.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['code'],
                    child: Text('${c['code']} - ${c['name']}'),
                  );
                }).toList(),
                onChanged: _onCustomerChanged,
              ),
              const SizedBox(height: 24),

              if (_selectedCustomer != null) ...[
                // Saldo Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text('Total Sisa Deposit', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_saldo.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showTopUpDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Terima Setoran Deposit', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // History List
                const Text('Riwayat Deposit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, idx) {
                      final h = _history[idx];
                      final isMasuk = h['jenis'] == 'IN';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMasuk ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isMasuk ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(h['ket']),
                        subtitle: Text(h['tanggal']),
                        trailing: Text(
                          '${isMasuk ? '+' : '-'} Rp ${h['nominal']}',
                          style: TextStyle(
                            color: isMasuk ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
