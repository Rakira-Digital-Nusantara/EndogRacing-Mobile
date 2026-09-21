import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/auth/providers/auth_provider.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/features/sales/utils/sales_notification_dialog.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';
import 'package:endog_racing/features/sales/screens/transactions/input_penjualan_screen.dart';
import 'package:endog_racing/features/sales/screens/transactions/retur_tukar_screen.dart';
import 'package:endog_racing/features/sales/screens/cash/setor_kas_besar_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final String? initialCustomerCode;

  const SalesHistoryScreen({
    super.key,
    this.onProfileTap,
    this.initialCustomerCode,
  });

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Lunas', 'Punya Hutang'];
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSalesHistory(
        customerCode: widget.initialCustomerCode,
      );
      context.read<SalesProvider>().fetchSaldoBelumDisetor();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
    });
    context.read<SalesProvider>().fetchSalesHistory(search: val);
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final history = sales.salesHistory;
    final auth = context.watch<AuthProvider>();
    final userFoto = auth.user?.foto;

    List<Map<String, dynamic>> filteredHistory = history;

    if (_selectedFilter == 'Lunas') {
      filteredHistory = filteredHistory.where((h) {
        final status = (h['status_bayar'] ?? h['status'] ?? '')
            .toString()
            .toUpperCase();
        return status == 'PAID' || status == 'LUNAS';
      }).toList();
    } else if (_selectedFilter == 'Punya Hutang') {
      filteredHistory = filteredHistory.where((h) {
        final status = (h['status_bayar'] ?? h['status'] ?? '')
            .toString()
            .toUpperCase();
        return status == 'UNPAID' || status == 'PARSIAL' || status == 'PIUTANG';
      }).toList();
    }
    if (_selectedDateRange != null) {
      filteredHistory = filteredHistory.where((h) {
        final dateStr = h['tanggal']?.toString();
        if (dateStr == null) return true;
        try {
          final date = DateTime.parse(dateStr);
          return date.isAfter(
                _selectedDateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              date.isBefore(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              );
        } catch (_) {
          return true;
        }
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo Endog Racing Hijau.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.egg_alt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Histori Penjualan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PETUGAS SALES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              margin: const EdgeInsets.only(right: 20, left: 4),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.delivery_dining_rounded,
                    color: const Color(0xFF64748B),
                    size: 19.2,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          sales.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await context.read<SalesProvider>().fetchSalesHistory(
                      customerCode: widget.initialCustomerCode,
                    );
                    if (mounted) {
                      await context.read<SalesProvider>().fetchSaldoBelumDisetor();
                    }
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Cash in hand summary card
                            Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Tunai di Tangan (Belum Disetor)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(sales.saldoBelumDisetor),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SetorKasBesarScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  'Setor ke Kas Besar',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Filters (Date & Search)
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            _onSearchChanged(val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari pelanggan...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.grey.shade400,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDateRange: _selectedDateRange,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDateRange = picked;
                              });
                            }
                          },
                        ),
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (val) {
                            _onFilterChanged(filter);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      // List
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 8,
                          bottom: 180, // Ditambahkan lebih besar agar tidak tertutup 2 FAB
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredHistory[index];
                              return _buildTransactionCard(item);
                            },
                            childCount: filteredHistory.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          if (_isFabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isFabExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              heroTag: 'retur_tukar_fab',
              onPressed: () {
                setState(() => _isFabExpanded = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReturTukarScreen()),
                );
              },
              backgroundColor: Colors.orange.shade50,
              icon: const Icon(Icons.sync_problem_rounded, color: Colors.orange),
              label: const Text(
                'Hutang Barang',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              elevation: 4,
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'buat_penjualan_fab',
              onPressed: () {
                setState(() => _isFabExpanded = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InputPenjualanScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text(
                'Buat Penjualan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              elevation: 4,
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'main_fab_toggle',
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            backgroundColor: _isFabExpanded ? Colors.grey.shade400 : AppColors.primary,
            elevation: _isFabExpanded ? 0 : 4,
            child: Icon(
              _isFabExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final statusBayar = (item['status_bayar'] ?? item['status'] ?? '')
        .toString()
        .toUpperCase();
    final isLunas = statusBayar == 'PAID' || statusBayar == 'LUNAS';
    final isParsial = statusBayar == 'PARSIAL';
    final isPiutang =
        statusBayar == 'UNPAID' || isParsial || statusBayar == 'PIUTANG';
    final isRetur = statusBayar == 'RETUR';
    final isTerlambat = item['is_terlambat'] == true;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isLunas) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'LUNAS';
    } else if (isParsial) {
      statusColor = Colors.orange;
      statusIcon = Icons.timelapse_rounded;
      statusText = 'SEBAGIAN';
    } else if (isPiutang) {
      statusColor = Colors.red;
      statusIcon = Icons.schedule_rounded;
      statusText = 'UNPAID';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline_rounded;
      statusText = statusBayar;
    }

    final customerName =
        (item['customer_name'] ??
                item['customer']?['name'] ??
                item['pelanggan_nama'] ??
                'Unknown Customer')
            .toString();
    final initials = customerName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final dibayar =
        double.tryParse(
          item['uang_diterima']?.toString() ??
              item['total_dibayar']?.toString() ??
              item['dibayar']?.toString() ??
              '0',
        ) ??
        0;
    final kurang = item['sisa_piutang'] != null
        ? (double.tryParse(item['sisa_piutang'].toString()) ?? 0)
        : 0.0;

    double grandTotal =
        double.tryParse(
          item['total_akhir']?.toString() ??
              item['grand_total']?.toString() ??
              item['total']?.toString() ??
              '0',
        ) ??
        0;
    if (grandTotal == 0 && (dibayar > 0 || kurang > 0)) {
      grandTotal = dibayar + kurang;
    }

    // In case sisa_piutang was null, we recalculate kurang based on the found grandTotal
    final finalKurang = item['sisa_piutang'] != null
        ? kurang
        : (grandTotal - dibayar);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetail(
            context,
            item,
            customerName,
            initials,
            statusColor,
            statusIcon,
            statusText,
            isLunas,
            isPiutang,
            isRetur,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      radius: 24,
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['jual_code'] ?? item['id'] ?? item['faktur_code'] ?? item['penjualan_code'] ?? '-'} • ${item['tanggal'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isTerlambat || item['tgl_jatuh_tempo'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isTerlambat)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TERLAMBAT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (item['tgl_jatuh_tempo'] != null)
                        Text(
                          'Jatuh Tempo: ${item['tgl_jatuh_tempo']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isRetur
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nilai Retur',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '- ${CurrencyFormatter.format(grandTotal.abs())}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Text(
                                item['catatan'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Penjualan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(grandTotal),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Telah Dibayar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(dibayar),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                if (isPiutang) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sisa: ${CurrencyFormatter.format(finalKurang)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showTerimaCicilanDialog(
                          context,
                          item,
                          context.read<SalesProvider>(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(0, 36),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terima Cicilan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(
    BuildContext context,
    Map<String, dynamic> item,
    String customerName,
    String initials,
    Color statusColor,
    IconData statusIcon,
    String status,
    bool isLunas,
    bool isPiutang,
    bool isRetur,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _TransactionDetailSheet(
          item: item,
          customerName: customerName,
          initials: initials,
          statusColor: statusColor,
          statusIcon: statusIcon,
          status: status,
        );
      },
    );
  }

  void _showTerimaCicilanDialog(
    BuildContext context,
    Map<String, dynamic> item,
    SalesProvider sales,
  ) {
    final nominalCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();
    DateTime? janjiLunasDate;

    double total =
        double.tryParse(
          item['total_akhir']?.toString() ??
              item['grand_total']?.toString() ??
              item['total']?.toString() ??
              '0',
        ) ??
        0;
    double dibayar =
        double.tryParse(
          item['uang_diterima']?.toString() ??
              item['total_dibayar']?.toString() ??
              item['dibayar']?.toString() ??
              '0',
        ) ??
        0;
    double kurang = item['sisa_piutang'] != null
        ? (double.tryParse(item['sisa_piutang'].toString()) ?? 0)
        : (total - dibayar);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Terima Cicilan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sisa tagihan: ${CurrencyFormatter.format(kurang)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nominalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Nominal Bayar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanCtrl,
                    decoration: InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setStateDialog(() => janjiLunasDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            janjiLunasDate == null
                                ? 'Tgl Janji Lunas (Opsional)'
                                : '${janjiLunasDate!.year}-${janjiLunasDate!.month.toString().padLeft(2, '0')}-${janjiLunasDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: janjiLunasDate == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isSubmitting) return;

                    final nominalStr = nominalCtrl.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final nominal = int.tryParse(nominalStr) ?? 0;

                    if (nominal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nominal harus lebih dari 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setStateDialog(() => isSubmitting = true);

                    final jualCode =
                        item['jual_code']?.toString() ??
                        item['id']?.toString() ??
                        item['faktur_code']?.toString() ??
                        item['penjualan_code']?.toString() ??
                        '';
                    final payload = {
                      "nominal_bayar": nominal,
                      "nominal_dibayar": nominal,
                      "nominal": nominal,
                      "jumlah": nominal,
                      "catatan": catatanCtrl.text,
                      if (janjiLunasDate != null)
                        "tgl_janji_lunas":
                            "${janjiLunasDate!.year}-${janjiLunasDate!.month.toString().padLeft(2, '0')}-${janjiLunasDate!.day.toString().padLeft(2, '0')}",
                    };

                    final sm = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    final success = await sales.submitTerimaCicilan(
                      jualCode,
                      payload,
                    );

                    if (!mounted) return;

                    nav.pop(); // Tutup dialog setelah selesai loading

                    if (success) {
                      sm.showSnackBar(
                        const SnackBar(
                          content: Text('Cicilan berhasil diterima'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.read<SalesProvider>().fetchSalesHistory(
                        search: _searchQuery,
                        customerCode: widget.initialCustomerCode,
                      );
                      sales
                          .fetchSalesDashboard(); // Refresh dashboard (piutang)
                      sales.fetchSaldoBelumDisetor(); // Refresh saldo kas
                    } else {
                      showDialog(
                        context: context,
                        builder: (ctxErr) => AlertDialog(
                          title: const Text('Gagal Memproses'),
                          content: Text('Error dari Server:\n\n${sales.error}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctxErr),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    }

                    setStateDialog(() => isSubmitting = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TransactionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String customerName;
  final String initials;
  final Color statusColor;
  final IconData statusIcon;
  final String status;

  const _TransactionDetailSheet({
    required this.item,
    required this.customerName,
    required this.initials,
    required this.statusColor,
    required this.statusIcon,
    required this.status,
  });

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final code =
        widget.item['jual_code'] ??
        widget.item['id'] ??
        widget.item['faktur_code'] ??
        widget.item['penjualan_code'];
    if (code != null) {
      final sales = context.read<SalesProvider>();
      final data = await sales.fetchTransactionDetail(code.toString());
      if (mounted) {
        setState(() {
          _detailData = data;
          _isLoading = false;
        });
        if (data == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal memuat detail dari server. Menampilkan data ringkasan.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final code =
        widget.item['jual_code'] ??
        widget.item['id'] ??
        widget.item['faktur_code'] ??
        widget.item['penjualan_code'];

    // Calculate total from detail data or fallback to item
    double totalQty = 0;
    double totalHarga = 0;
    List<dynamic> detailsList = [];

    if (_detailData != null && _detailData!['details'] != null) {
      detailsList = _detailData!['details'] as List<dynamic>;
      for (var d in detailsList) {
        totalQty += double.tryParse(d['qty']?.toString() ?? '0') ?? 0;
        totalHarga += double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;
      }
    } else {
      totalQty = double.tryParse(widget.item['qty']?.toString() ?? '10') ?? 0;
      totalHarga =
          double.tryParse(widget.item['total']?.toString() ?? '0') ?? 0;
    }

    final cName =
        _detailData?['customer']?['nama_toko']?.toString() ??
        widget.customerName;
    final cInitials = cName.isNotEmpty
        ? cName.substring(0, 1).toUpperCase()
        : widget.initials;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.statusIcon,
                      size: 14,
                      color: widget.statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  cInitials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${code ?? '-'} • ${widget.item['tanggal'] ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            )
          else ...[
            if (detailsList.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RINCIAN PRODUK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: detailsList.map((d) {
                    final productName =
                        d['product']?['product_name'] ??
                        d['product_name'] ??
                        'Produk';
                    final qty = d['qty']?.toString() ?? '0';
                    final price = d['harga_satuan'] ?? 0;
                    final sub = d['subtotal'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$qty x ${CurrencyFormatter.format(price)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(sub),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                const Text(
                  'RINGKASAN PEMBELIAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Qty (Peti/Kg)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        totalQty.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(totalHarga),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isDownloadingPdf ? null : () async {
              if (code != null) {
                setState(() => _isDownloadingPdf = true);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                try {
                  debugPrint('Mulai proses unduh PDF untuk $code...');
                  final path = await sales.downloadFakturPdf(code.toString());
                  debugPrint('Path hasil unduh: $path');
                  if (path != null) {
                    debugPrint('Menampilkan snackbar sukses');
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Download berhasil! Membuka file...'), backgroundColor: Colors.green),
                    );
                    
                    debugPrint('Memanggil OpenFilex.open');
                    final result = await OpenFilex.open(path);
                    debugPrint('Hasil OpenFilex: ${result.type} - ${result.message}');
                    if (result.type != ResultType.done) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Gagal membuka file: ${result.message}'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isDownloadingPdf = false);
                }
              }
            },
            icon: _isDownloadingPdf 
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
            label: Text(
              _isDownloadingPdf ? 'Sedang Mengunduh...' : 'Download Faktur (PDF)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
